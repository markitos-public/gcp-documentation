# ☁️ Binary Authorization: Seguridad en el Despliegue de Contenedores

## 📑 Índice

* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [🔬 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Descripción

**Binary Authorization** es un servicio de seguridad de Google Cloud que aplica políticas de "solo desplegar lo verificado" en entornos de contenedores como Google Kubernetes Engine (GKE) y Cloud Run. Su objetivo principal es garantizar que solo se desplieguen imágenes de contenedor que han sido explícitamente autorizadas por uno o más "attestors" (atestadores), que son entidades verificables que firman digitalmente las imágenes. Esto crea un control de seguridad crítico en el pipeline de CI/CD, previniendo el despliegue de código malicioso, no probado o no autorizado.

---

## 📘 Detalles

Binary Authorization se integra en la fase de despliegue para interceptar las solicitudes a la API de Kubernetes o Cloud Run. Cuando se intenta crear una carga de trabajo (como un Pod o un servicio de Cloud Run), el servicio verifica si existe una política de Binary Authorization aplicable.

### 🔹 Componentes Clave

1.  **Política (Policy):** Un conjunto de reglas que definen los requisitos para el despliegue. Se configura a nivel de proyecto. La política puede tener reglas por defecto y reglas específicas para clústeres de GKE o identidades de servicio. Una regla clave es la `enforcementMode`, que puede ser `ENFORCED` (bloquea despliegues no conformes) o `DRY_RUN` (solo audita y registra violaciones).

2.  **Atestador (Attestor):** Una entidad de IAM que tiene la autoridad para firmar una imagen. Un atestador está respaldado por un par de claves criptográficas (PKA) gestionadas a través de Cloud KMS. La clave pública se registra en el atestador, mientras que la clave privada se usa para firmar.

3.  **Atestación (Attestation):** Una firma digital creada por un atestador sobre un digest de imagen de contenedor específico (`image@digest`). Esta firma es la prueba de que la imagen ha sido verificada. Las atestaciones se almacenan como metadatos asociados a la imagen.

### 🔹 Flujo de Verificación

1.  Un desarrollador o un sistema de CI/CD construye una imagen y la sube a un registro como Artifact Registry.
2.  Un proceso de validación (pruebas unitarias, análisis de vulnerabilidades, revisión manual) se completa con éxito.
3.  El sistema de CI (o una persona autorizada) utiliza la clave privada de un atestador para crear una atestación para el digest de la imagen.
4.  Cuando un orquestador como GKE intenta desplegar esa imagen, el "enforcer" de Binary Authorization intercepta la solicitud.
5.  El enforcer consulta la política del proyecto, encuentra los atestadores requeridos para ese despliegue y verifica si existen atestaciones válidas para el digest de la imagen.
6.  Si se cumplen todos los requisitos de la política, el despliegue se permite. De lo contrario, se bloquea.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio demuestra cómo configurar una política básica de Binary Authorization que requiere una atestación para desplegar una imagen en GKE.

### ARRANGE (Preparación)

```bash
# 1. Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export CLUSTER_NAME="binary-auth-cluster"
export REGION="europe-west1"

# 2. Habilitar las APIs necesarias
gcloud services enable \
    container.googleapis.com \
    binaryauthorization.googleapis.com \
    containeranalysis.googleapis.com \
    cloudkms.googleapis.com

# 3. Crear un clúster de GKE con Binary Authorization habilitado
gcloud container clusters create $CLUSTER_NAME \
    --region=$REGION \
    --enable-binauthz \
    --machine-type=e2-small \
    --num-nodes=1

# 4. Configurar kubectl para que apunte al nuevo clúster
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# 5. Crear un atestador
export ATTESTOR_ID="qa-attestor"
export ATTESTOR_EMAIL="qa-attestor@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud binary-authorization attestors create $ATTESTOR_ID \
    --display-name="QA Signer" \
    --description="Attestor for images that passed QA"

# 6. Crear un par de claves en Cloud KMS para el atestador
export KMS_KEYRING="binauthz-keys"
export KMS_KEY="qa-key"
export KMS_KEY_VERSION=1

gcloud kms keyrings create $KMS_KEYRING --location=$REGION
gcloud kms keys create $KMS_KEY \
    --keyring=$KMS_KEYRING \
    --location=$REGION \
    --purpose="asymmetric-signing" \
    --default-algorithm="ec-sign-p256-sha256"

# 7. Asociar la clave pública con el atestador
gcloud beta binary-authorization attestors add-iam-policy-binding $ATTESTOR_ID \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[gke-system/binauthz-system]" \
    --role="roles/binaryauthorization.attestorVerifier"

# 8. Extraer y registrar la clave pública en el atestador
gcloud container binauthz attestors public-keys add \
    --attestor=$ATTESTOR_ID \
    --keyversion-project=$PROJECT_ID \
    --keyversion-location=$REGION \
    --keyversion-keyring=$KMS_KEYRING \
    --keyversion-key=$KMS_KEY \
    --keyversion=$KMS_KEY_VERSION
```

### ACT (Implementación)

```bash
# 1. Configurar una política de Binary Authorization que requiera nuestro atestador
# Primero, exportamos la política actual a un archivo.
gcloud binary-authorization policy export > ./policy.yaml

# Modificamos el archivo policy.yaml para añadir la regla.
# (Este paso se haría manualmente o con una herramienta como `yq`)
# El cambio clave es añadir `projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}`
# a la sección `requireAttestationsBy`.

# Ejemplo de cómo se vería la política (simplificado):
# defaultAdmissionRule:
#   enforcementMode: ENFORCED
#   evaluationMode: REQUIRE_ATTESTATION
#   requireAttestationsBy:
#     - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}

# Por simplicidad, usamos gcloud para establecer una regla simple.
gcloud binary-authorization policy update \
    --default-rule='ENFORCED' \
    --require-attestation-by=$ATTESTOR_ID

# 2. Intentar desplegar una imagen NO firmada (debería fallar)
kubectl run hello-server-unsigned --image=gcr.io/google-samples/hello-app:1.0 --port=8080

# 3. Crear una atestación para la imagen
export IMAGE_PATH="gcr.io/google-samples/hello-app"
export IMAGE_DIGEST=$(gcloud container images describe ${IMAGE_PATH}:1.0 --format='get(image_summary.digest)')
export IMAGE_TO_ATTEST="${IMAGE_PATH}@${IMAGE_DIGEST}"

gcloud beta container binauthz attestations sign-and-create \
    --project=$PROJECT_ID \
    --artifact-url=$IMAGE_TO_ATTEST \
    --attestor=$ATTESTOR_ID \
    --keyversion-project=$PROJECT_ID \
    --keyversion-location=$REGION \
    --keyversion-keyring=$KMS_KEYRING \
    --keyversion-key=$KMS_KEY \
    --keyversion=$KMS_KEY_VERSION

# 4. Intentar desplegar la imagen AHORA firmada (debería funcionar)
kubectl run hello-server-signed --image=$IMAGE_TO_ATTEST --port=8080
```

### ASSERT (Verificación)

```bash
# 1. Verificar que el despliegue no firmado falló
# El siguiente comando no debería mostrar el pod "hello-server-unsigned" o mostrarlo en un estado de error.
kubectl get pods -l run=hello-server-unsigned
# También se puede ver el evento de denegación en los logs de GKE.
kubectl get event --template \
'{{range.items}}{{"\n"}}{{ if and (eq .involvedObject.kind "Pod") (eq .reason "FailedCreate") (eq .source.component "replicaset-controller") }}{{ .message }}{{end}}{{end}}' | grep "denied by Binary Authorization"

# 2. Verificar que la atestación fue creada
gcloud beta container binauthz attestations list \
    --attestor=$ATTESTOR_ID \
    --artifact-url=$IMAGE_TO_ATTEST

# 3. Verificar que el despliegue firmado tuvo éxito
kubectl get pods -l run=hello-server-signed
# El pod "hello-server-signed" debería estar en estado "Running".
```

### CLEANUP (Limpieza)

```bash
# Eliminar los recursos del clúster
kubectl delete deployment hello-server-signed
kubectl delete deployment hello-server-unsigned --ignore-not-found=true

# Eliminar el clúster de GKE
gcloud container clusters delete $CLUSTER_NAME --region $REGION --quiet

# Resetear la política de Binary Authorization a la por defecto
gcloud binary-authorization policy update --default-rule=\'ALLOW\'

# Eliminar el atestador
gcloud binary-authorization attestors delete $ATTESTOR_ID --quiet

# Deshabilitar y destruir las claves KMS (¡CUIDADO!)
gcloud kms keys versions disable $KMS_KEY_VERSION --key=$KMS_KEY --keyring=$KMS_KEYRING --location=$REGION
gcloud kms keys versions destroy $KMS_KEY_VERSION --key=$KMS_KEY --keyring=$KMS_KEYRING --location=$REGION
gcloud kms keys delete $KMS_KEY --keyring=$KMS_KEYRING --location=$REGION --quiet || true
gcloud kms keyrings delete $KMS_KEYRING --location=$REGION --quiet || true
```

---

## 💡 Lecciones Aprendidas

*   **Shift-Left de la Seguridad:** Binary Authorization no es solo una herramienta de operaciones; fuerza a los equipos de desarrollo a integrar la seguridad (firmado de imágenes) en sus pipelines de CI/CD desde el principio.
*   **La Confianza se Basa en Criptografía, no en Nombres:** El sistema no confía en tags de imagen como `:latest` o `:prod` (que son mutables). La confianza se ancla en el `digest` inmutable de la imagen, verificado con una firma criptográfica.
*   **El Modo `DRY_RUN` es tu Mejor Amigo:** Antes de forzar políticas (`ENFORCED`), usa el modo `DRY_RUN` para auditar qué cargas de trabajo serían bloqueadas. Esto permite una implementación gradual sin interrumpir servicios críticos.

---

## ⚠️ Errores y Confusiones Comunes

*   **Error: Firmar el Tag en lugar del Digest:** Intentar crear una atestación para `gcr.io/my-project/my-app:v1.0` en lugar de `gcr.io/my-project/my-app@sha256:...`. La atestación debe estar ligada al contenido exacto de la imagen (el digest), no a una etiqueta mutable.
*   **Confusión: Pensar que Binary Authorization Analiza Vulnerabilidades:** Binary Authorization no escanea imágenes. Su función es verificar que *otro* proceso (como Artifact Analysis) ha ocurrido y ha sido validado por un atestador. El atestador es la prueba de que el análisis (u otro control) se realizó.
*   **Problema: Permisos de IAM Incorrectos:** Un error común es que la cuenta de servicio que intenta crear la atestación no tiene el rol `roles/cloudkms.signer` en la clave KMS, o que el enforcer de GKE no tiene `roles/binaryauthorization.attestorVerifier` sobre el atestador.

---

## 🎯 Tips de Examen

*   **Recuerda los dos modos de ejecución:** `ENFORCED` (bloquea) y `DRY_RUN` (audita). Es una pregunta clásica de examen.
*   **Componentes Clave:** Conoce la relación entre Política (Policy), Atestador (Attestor) y Atestación (Attestation).
*   **Imágenes Exentas:** Google mantiene una lista de imágenes base (ej. `gcr.io/google-containers/*`) que están exentas por defecto para no romper la funcionalidad del clúster. Esto es configurable.
*   **Integración:** Binary Authorization se integra con GKE, Cloud Run y Anthos.

---

## 🧾 Resumen

Binary Authorization es un pilar de la seguridad de la cadena de suministro de software en GCP. Actúa como un portero en tiempo de despliegue, asegurando que solo las imágenes de contenedor que han pasado por procesos de verificación y han sido firmadas digitalmente puedan ejecutarse. Esto previene despliegues no autorizados y fortalece la postura de seguridad del entorno.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-binary-authorization-seguridad-en-el-despliegue-de-contenedores)