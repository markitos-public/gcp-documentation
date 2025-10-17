# ☁️ Caso Práctico: Troubleshooting de Binary Authorization

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🕵️‍♂️ Proceso de Diagnóstico (Troubleshooting)](#️-proceso-de-diagnóstico-troubleshooting)
* [🔬 Laboratorio Práctico (Simulación y Solución)](#-laboratorio-práctico-simulación-y-solución)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Un equipo de desarrollo intenta desplegar una nueva versión de su aplicación en un clúster de GKE. El pipeline de CI/CD completa la compilación y el push de la imagen a Artifact Registry con éxito, pero el despliegue en GKE falla misteriosamente. Al inspeccionar los Pods, ven un estado de `FailedCreate` o `ErrImagePull`. El equipo está seguro de que la imagen existe y que el clúster tiene los permisos correctos para acceder al registro.

**Mensaje de Error Típico (visto en los eventos del ReplicaSet):**
`Error creating: pods "my-app-deployment-xxxx-yyyy" is forbidden: failed to create pod container "my-app": Denied by Binary Authorization policy: No attestations found for the image...`

El objetivo es diagnosticar por qué Binary Authorization está bloqueando un despliegue que se considera legítimo y aplicar la solución correcta.

---

## 🕵️‍♂️ Proceso de Diagnóstico (Troubleshooting)

Ante un bloqueo de Binary Authorization, se debe seguir un proceso sistemático para identificar la causa raíz.

1.  **Confirmar que es Binary Authorization:** El primer paso es verificar los eventos del `ReplicaSet` o `Deployment` en Kubernetes. El mensaje de error será explícito, como se muestra en el escenario. Esto confirma que el problema no es de red, permisos de pull de imagen o un error en el manifiesto de Kubernetes.
    ```bash
    kubectl get events --sort-by='.lastTimestamp' | grep "Binary Authorization"
    ```

2.  **Inspeccionar la Política Aplicable:** ¿Qué regla está bloqueando el despliegue? Hay que revisar la política de Binary Authorization del proyecto.
    *   ¿Está el `enforcementMode` en `ENFORCED`?
    *   ¿Qué `attestors` se requieren en la `defaultAdmissionRule` o en alguna regla específica del clúster?
    ```bash
    gcloud binary-authorization policy describe
    ```

3.  **Verificar la Imagen Exacta que se Intenta Desplegar:** Binary Authorization opera sobre el **digest** de la imagen (`image@sha256:...`), no sobre el tag (`image:latest`). Hay que obtener el digest exacto que el `Deployment` de Kubernetes está intentando usar.
    ```bash
    kubectl get deployment my-app-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
    ```

4.  **Buscar Atestaciones para esa Imagen y Digest:** Una vez que se tiene el digest, hay que comprobar si existen las atestaciones requeridas por la política. Para cada `attestor` requerido, se debe ejecutar:
    ```bash
    gcloud beta container binauthz attestations list \
        --attestor="projects/MY_PROJECT/attestors/MY_ATTESTOR" \
        --artifact-url="gcr.io/my-project/my-app@sha256:..."
    ```
    Si este comando no devuelve ninguna atestación, hemos encontrado la causa raíz: **la imagen no fue firmada por el atestador requerido.**

5.  **Analizar el Proceso de Firma (CI/CD):** Si no hay atestación, el siguiente paso es investigar el pipeline de CI/CD.
    *   ¿Se ejecutó el paso de firma después de las pruebas y el análisis de vulnerabilidades?
    *   ¿El pipeline firmó el **digest correcto**? Un error común es firmar el tag `latest` y luego intentar desplegar un digest específico.
    *   ¿La cuenta de servicio del pipeline de CI/CD tiene los permisos de IAM necesarios (`roles/cloudkms.signer` y `roles/containeranalysis.notes.attacher`)?

---

## 🔬 Laboratorio Práctico (Simulación y Solución)

Este laboratorio simula el escenario y aplica la solución.

### ARRANGE (Preparación del Problema)

*Asumimos que ya existe un clúster con Binary Authorization habilitado, un atestador (`qa-attestor`) y una política que lo requiere, como en el laboratorio del capítulo de Binary Authorization.*

```bash
# 1. Variables (asumiendo configuración previa)
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export CLUSTER_NAME="binary-auth-cluster"
export ATTESTOR_ID="qa-attestor"
export IMAGE_URI="gcr.io/google-samples/hello-app:1.0"

# 2. Asegurarse de que la política está en modo ENFORCED
gcloud binary-authorization policy update \
    --default-rule='ENFORCED' \
    --require-attestation-by=$ATTESTOR_ID

# 3. Obtener el digest de la imagen
export IMAGE_DIGEST=$(gcloud container images describe $IMAGE_URI --format='get(image_summary.digest)')
export IMAGE_WITH_DIGEST="gcr.io/google-samples/hello-app@${IMAGE_DIGEST}"

# 4. Asegurarse de que no hay atestaciones para esta imagen
# (Limpieza de atestaciones previas si es necesario)
gcloud beta container binauthz attestations list \
    --attestor=$ATTESTOR_ID --artifact-url=$IMAGE_WITH_DIGEST --format="value(name)" | xargs -I {} gcloud beta container binauthz attestations delete {}
```

### ACT (Simulación del Fallo)

```bash
# 1. Intentar desplegar la imagen sin firmar (esto simula el fallo del pipeline)
# Usamos el digest para ser explícitos.
kubectl run hello-blocked --image=$IMAGE_WITH_DIGEST --port=8080

# 2. Verificar el fallo (Assert del problema)
# El pod no se creará. Verificamos el evento de ReplicaSet.
kubectl get events --template \
'{{range.items}}{{"\n"}}{{ if and (eq .involvedObject.kind "Pod") (eq .reason "FailedCreate") (eq .source.component "replicaset-controller") }}{{ .message }}{{end}}{{end}}' | grep "Denied by Binary Authorization"
# SALIDA ESPERADA: Contendrá un mensaje como "...No attestations found for the image..."
```

### ASSERT (Aplicación de la Solución)

*El diagnóstico nos lleva a la conclusión de que falta la atestación. La solución es firmar la imagen correctamente.*

```bash
# 1. Firmar la imagen (simulando el paso que faltó en el CI/CD)
# Asumimos que las variables de KMS (KEYRING, KEY, etc.) están configuradas como en el lab anterior.
export KMS_KEYRING="binauthz-keys"
export KMS_KEY="qa-key"
export KMS_KEY_VERSION=1

gcloud beta container binauthz attestations sign-and-create \
    --project=$PROJECT_ID \
    --artifact-url=$IMAGE_WITH_DIGEST \
    --attestor=$ATTESTOR_ID \
    --keyversion-project=$PROJECT_ID \
    --keyversion-location=$REGION \
    --keyversion-keyring=$KMS_KEYRING \
    --keyversion-key=$KMS_KEY \
    --keyversion=$KMS_KEY_VERSION

# 2. Verificar que la atestación ahora existe
gcloud beta container binauthz attestations list \
    --attestor=$ATTESTOR_ID \
    --artifact-url=$IMAGE_WITH_DIGEST
# SALIDA ESPERADA: Debería mostrar la atestación que acabamos de crear.

# 3. Reintentar el despliegue
# Kubernetes reintentará crear el Pod automáticamente. Verificamos que ahora sí se crea.
# Esperamos unos segundos para que el controlador de ReplicaSet lo intente de nuevo.
sleep 10
kubectl get pod -l run=hello-blocked
# SALIDA ESPERADA: El pod "hello-blocked" ahora debería estar en estado "ContainerCreating" o "Running".
```

### CLEANUP (Limpieza)

```bash
kubectl delete deployment hello-blocked
# ... (resto de la limpieza del laboratorio de Binary Authorization)
```

---

## 💡 Lecciones Aprendidas

*   **Los Mensajes de Error son tus Amigos:** El evento de Kubernetes es extremadamente claro. El primer reflejo debe ser siempre `kubectl get events`.
*   **Confía en el Digest, no en el Tag:** El problema casi siempre se reduce a una discrepancia entre la imagen que *crees* que estás desplegando (basada en un tag) y la imagen que *realmente* se está desplegando (el digest subyacente), y cuál de ellas fue firmada.
*   **Modo `DRY_RUN` para Prevenir:** Antes de mover un clúster a `ENFORCED`, déjalo en modo `DRY_RUN`. Esto te permite ver qué despliegues *habrían sido* bloqueados en los logs de auditoría (`cloudaudit.googleapis.com%2Factivity`), permitiéndote arreglar los pipelines de CI/CD sin causar una interrupción.

---

## 🧾 Resumen

El troubleshooting de Binary Authorization es un proceso lógico de verificación. Comienza confirmando el error en los eventos de Kubernetes, luego inspecciona la política para entender los requisitos, y finalmente verifica si el artefacto específico (el digest de la imagen) cumple esos requisitos (tiene las atestaciones necesarias). La causa raíz casi siempre es una atestación faltante, lo que apunta a un problema en el proceso de firma dentro del pipeline de CI/CD.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-troubleshooting-de-binary-authorization)
