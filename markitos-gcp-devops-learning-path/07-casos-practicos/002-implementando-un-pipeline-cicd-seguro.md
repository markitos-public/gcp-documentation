# ☁️ Caso Práctico: Implementando un Pipeline CI/CD Seguro en GCP

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

Este caso práctico demuestra cómo construir un pipeline de Integración Continua y Despliegue Continuo (CI/CD) seguro en Google Cloud. El objetivo es crear un flujo automatizado que compile una aplicación, la empaquete en un contenedor, la escanee en busca de vulnerabilidades, la firme criptográficamente para verificar su integridad y finalmente la despliegue en un clúster de Google Kubernetes Engine (GKE). Este pipeline integra varios servicios de GCP para establecer una cadena de suministro de software segura y confiable, desde el código fuente hasta la producción.

---

## 📘 Detalles

El pipeline seguro se basa en la orquestación de los siguientes servicios de GCP:

1.  **Cloud Source Repositories:** Actúa como nuestro repositorio de Git privado para alojar el código fuente de la aplicación.
2.  **Cloud Build:** Es el corazón del pipeline. Se dispara automáticamente ante un cambio en el repositorio y ejecuta una serie de pasos definidos en un archivo `cloudbuild.yaml`.
3.  **Artifact Registry:** Almacena de forma segura la imagen de contenedor creada por Cloud Build.
4.  **Artifact Analysis:** Escanea automáticamente la imagen almacenada en Artifact Registry en busca de vulnerabilidades conocidas (CVEs).
5.  **Cloud Key Management Service (KMS):** Proporciona las claves criptográficas para firmar la imagen, demostrando que ha pasado los controles de calidad.
6.  **Binary Authorization:** Actúa como el guardián del clúster de GKE. Su política impide que se desplieguen imágenes que no estén firmadas por una autoridad de confianza.
7.  **Google Kubernetes Engine (GKE):** Es el entorno de ejecución final donde se desplegará nuestra aplicación en contenedores.

El flujo es el siguiente:
*   Un desarrollador empuja código a una rama específica en Cloud Source Repositories.
*   Un **trigger de Cloud Build** detecta el cambio y comienza una nueva construcción.
*   **Cloud Build** ejecuta los siguientes pasos:
    1.  **Build:** Construye la imagen de contenedor usando el Dockerfile.
    2.  **Push:** Sube la imagen a Artifact Registry.
    3.  **Scan Check (Espera):** Artifact Analysis comienza a escanear la imagen automáticamente. El pipeline puede esperar y verificar que no se encuentren vulnerabilidades críticas.
    4.  **Attest (Firma):** Si el escaneo es exitoso, Cloud Build usa una clave de KMS para crear una atestación (firma) para la imagen. Esta atestación se almacena en Artifact Analysis.
    5.  **Deploy:** Cloud Build actualiza el manifiesto de despliegue de Kubernetes con el nuevo `digest` de la imagen y aplica el cambio en el clúster de GKE.
*   **Binary Authorization** intercepta la solicitud de despliegue en GKE, verifica que la imagen tiene la atestación requerida consultando a Artifact Analysis y, si es así, permite que el Pod se cree.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio implementa el pipeline descrito. Es complejo y requiere que los servicios de capítulos anteriores (GKE, Binary Authorization) estén configurados.

### ARRANGE (Preparación)

```bash
# --- Variables y Configuración Inicial ---
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export REGION="europe-west1"
export CLUSTER_NAME="secure-pipeline-cluster" # Asume que este clúster ya existe con Binary Authorization habilitado
export REPO_NAME="secure-app-repo"
export CSR_REPO_NAME="csr-secure-app"
export IMAGE_NAME="secure-app"
export ATTESTOR_NAME="build-attestor"

gcloud config set compute/region $REGION

# --- Habilitar APIs ---
gcloud services enable \
    sourcerepo.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    containeranalysis.googleapis.com \
    binaryauthorization.googleapis.com \
    cloudkms.googleapis.com

# --- Crear Repositorios ---
gcloud source repos create $CSR_REPO_NAME
gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REGION

# --- Configurar Permisos para Cloud Build ---
# Cloud Build necesita permisos para invocar a KMS, crear atestaciones y desplegar en GKE
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/cloudkms.signerVerifier"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/containeranalysis.notes.attacher"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/container.developer" # Permiso para desplegar en GKE

# --- Clonar el repo y crear archivos iniciales ---
gcloud source repos clone $CSR_REPO_NAME
cd $CSR_REPO_NAME

# --- Aplicación simple en Go ---
cat > main.go << EOM
package main
import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, Secure World!")
    })
    log.Fatal(http.ListenAndServe(":8080", nil))
}
EOM

# --- Dockerfile ---
cat > Dockerfile << EOM
FROM golang:1.18-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o /main .

FROM alpine:latest
WORKDIR /app
COPY --from=builder /main .
CMD ["/app/main"]
EOM

# --- Manifiesto de Kubernetes ---
cat > k8s.yaml << EOM
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: server
        image: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest # Placeholder
        ports:
        - containerPort: 8080
EOM
```

### ACT (Implementación)

```bash
# --- Crear el cloudbuild.yaml con los pasos del pipeline ---
cat > cloudbuild.yaml << EOM
steps:
# 1. Construir la imagen
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA', '.']

# 2. Subir la imagen a Artifact Registry
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA']

# 3. Generar y firmar la atestación (asumiendo que el atestador y la clave ya existen)
- name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: /bin/bash
  args:
  - -c
  - |
    gcloud beta container binauthz create-signature-payload \
      --artifact-url="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}@
$(gcloud container images describe ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA --format='get(image_summary.digest)')" > /tmp/payload.json && \
    gcloud kms asymmetric-sign \
      --location=${REGION} \
      --keyring=binauthz-keys \
      --key=build-key \
      --version=1 \
      --digest-algorithm=sha256 \
      --input-file=/tmp/payload.json \
      --output-file=/tmp/signature.bin && \
    gcloud beta container binauthz attestations create \
      --artifact-url="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}@
$(gcloud container images describe ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA --format='get(image_summary.digest)')" \
      --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR_NAME}" \
      --signature-file=/tmp/signature.bin \
      --public-key-id=$(gcloud kms keys versions list build-key --keyring=binauthz-keys --location=${REGION} --format='get(name)')

# 4. Desplegar en GKE
- name: 'gcr.io/cloud-builders/gke-deploy'
  args:
  - run
  - --filename=k8s.yaml
  - --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}@
$(gcloud container images describe ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA --format='get(image_summary.digest)')
  - --location=${REGION}-b # Zona del clúster
  - --cluster=${CLUSTER_NAME}

images:
- '${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA'
EOM

# --- Subir el código y disparar la build ---
git add .
git commit -m "Initial commit"
git push origin master

# --- Crear el Trigger de Cloud Build ---
gcloud beta builds triggers create cloud-source-repositories \
    --repo=$CSR_REPO_NAME \
    --branch-pattern="^master$" \
    --build-config=cloudbuild.yaml
```

### ASSERT (Verificación)

```bash
# --- Verificar el historial de builds en Cloud Build ---
gcloud builds list --limit=5

# --- Verificar que la imagen y la atestación existen ---
IMAGE_DIGEST=$(gcloud container images describe ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:$SHORT_SHA --format='get(image_summary.digest)')
gcloud beta container binauthz attestations list \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR_NAME}" \
    --artifact-url="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}@${IMAGE_DIGEST}"

# --- Verificar que el despliegue en GKE está corriendo ---
kubectl get deployments | grep secure-app
kubectl get pods | grep secure-app
```

### CLEANUP (Limpieza)

```bash
# --- Eliminar recursos ---
kubectl delete deployment secure-app
gcloud beta builds triggers delete <TRIGGER_NAME> --quiet # Reemplazar con el nombre del trigger
gcloud source repos delete $CSR_REPO_NAME --quiet
gcloud artifacts repositories delete $REPO_NAME --location $REGION --quiet
cd .. && rm -rf $CSR_REPO_NAME
# La limpieza de GKE, KMS y Binary Authorization se haría por separado según sus respectivos capítulos.
```

---

## 💡 Lecciones Aprendidas

*   **La Seguridad es un Contrato:** El pipeline define un "contrato de seguridad". La atestación es la prueba de que el contrato (build, test, scan) se ha cumplido. Binary Authorization simplemente hace cumplir ese contrato en el momento del despliegue.
*   **Inmutabilidad y `digest` lo son todo:** Todo el proceso se basa en el `digest` inmutable de la imagen. Las etiquetas son para los humanos, los `digest` son para las máquinas y la seguridad.
*   **El Poder de la Automatización:** Un pipeline bien configurado elimina el error humano del proceso de despliegue. La seguridad no es una opción que alguien pueda saltarse; es un requisito automatizado y verificado en cada commit.

---

## ⚠️ Errores y Confusiones Comunes

*   **Gestión de Permisos Compleja:** El error más común es una pesadilla de permisos de IAM. La cuenta de servicio de Cloud Build necesita una docena de roles para hablar con todos los demás servicios. Es crucial añadirlos uno por uno y verificar.
*   **Dependencias Cíclicas en la Configuración:** Para crear un atestador necesitas una nota, para la nota necesitas un proyecto. Para el pipeline necesitas el atestador. Es fácil perderse en qué crear primero. Sigue un orden lógico: Proyecto -> APIs -> KMS -> Atesstador/Política -> Repos -> Pipeline.
*   **Olvidar el `digest` en el Despliegue:** Si despliegas usando una etiqueta (`:latest`), Binary Authorization podría evaluar una imagen diferente a la que firmaste si la etiqueta se mueve. Siempre se debe desplegar usando el `digest` exacto (`image@sha256:...`).

---

## 🎯 Tips de Examen

*   **Flujo Completo:** Si una pregunta de examen de nivel Profesional (PCA, Devops Engineer) pide diseñar una solución completa para una cadena de suministro de software segura en GCP, la respuesta es esta arquitectura: **Source Repo -> Cloud Build -> Artifact Registry -> (Artifact Analysis) -> (KMS) -> Binary Authorization -> GKE/Cloud Run**.
*   **Rol de Cloud Build:** Cloud Build no es solo un compilador, es el **orquestador** del pipeline. Es el que invoca a KMS, crea atestaciones y ejecuta el despliegue.
*   **`gke-deploy`:** Recuerda que `gke-deploy` es el builder especializado de Cloud Build para facilitar los despliegues en GKE, ya que puede sustituir el `digest` de la imagen en el manifiesto de Kubernetes automáticamente.

---

## 🧾 Resumen

Implementar un pipeline CI/CD seguro en GCP es un ejercicio de integración que conecta herramientas de desarrollo, construcción, registro, análisis, seguridad y ejecución. Orquestado por Cloud Build, este flujo automatizado garantiza que solo el código verificado, escaneado y firmado criptográficamente pueda llegar a producción, estableciendo un pilar fundamental de la cultura DevSecOps en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-implementando-un-pipeline-cicd-seguro-en-gcp)
