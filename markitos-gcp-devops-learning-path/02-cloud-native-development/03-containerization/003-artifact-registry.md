# 📦 Artifact Registry

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-artifact-registry)

---

## 🧭 Descripción

Artifact Registry es el servicio universal de gestión de artefactos de Google Cloud. Es la evolución de Container Registry y permite almacenar, gestionar y proteger no solo imágenes de contenedor (Docker), sino también paquetes de lenguajes de programación como Maven (Java), npm (Node.js), Python (PyPI) y más. Centraliza todos los artefactos de tu ciclo de vida de desarrollo de software (SDLC) en un único lugar, con control de acceso granular a través de IAM y análisis de vulnerabilidades integrado.

---

## 📘 Detalles

### De Container Registry a Artifact Registry

Artifact Registry reemplaza y mejora al antiguo Container Registry (GCR). Mientras que GCR solo soportaba imágenes de contenedor y tenía una estructura de almacenamiento por proyecto, Artifact Registry ofrece:

*   **Soporte Multi-formato:** Almacena imágenes Docker, paquetes de lenguajes (Maven, npm, Python, etc.) y otros tipos de artefactos como los de Helm.
*   **Repositorios Regionales y Multi-regionales:** Puedes crear repositorios en una región específica para minimizar la latencia y los costos de transferencia, o en una multi-región para alta disponibilidad.
*   **Control de Acceso Basado en Repositorios:** A diferencia de GCR donde los permisos se aplicaban a nivel de bucket de almacenamiento, en Artifact Registry puedes aplicar permisos de IAM directamente a cada repositorio, ofreciendo un control mucho más granular.

### Conceptos Clave

1.  **Repositorio (Repository):** Es la unidad fundamental de almacenamiento. Cada repositorio tiene un formato específico (ej. `docker`, `npm`) y está ubicado en una región o multi-región.

2.  **Formato (Format):** El tipo de artefacto que el repositorio almacenará (Docker, Maven, Python, etc.).

3.  **Nombre de la Imagen/Paquete:** Los artefactos se identifican con una ruta única que incluye la ubicación, el proyecto, el repositorio y el nombre del artefacto. Por ejemplo:
    `europe-west1-docker.pkg.dev/mi-proyecto/mi-repo-docker/mi-imagen:tag`

4.  **Integración con CI/CD y Análisis:** Se integra de forma nativa con Cloud Build para los pipelines de CI/CD y con Artifact Analysis para escanear tus imágenes de contenedor en busca de vulnerabilidades conocidas.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear un Repositorio Docker, Subir una Imagen y Escanearla
**Contexto:** Crearemos un repositorio de tipo Docker en Artifact Registry, subiremos la imagen que creamos en el capítulo anterior y luego la listaremos para confirmar que está almacenada de forma segura.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export REPO_NAME="mi-repo-docker"
export IMAGE_NAME="hello-artifact-registry"
export LOCAL_IMAGE_TAG="$IMAGE_NAME:v1"
export AR_IMAGE_TAG="${REGION}-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:v1"

# Crear un Dockerfile simple (si no lo tienes del lab anterior)
cat <<EOT > Dockerfile
FROM alpine
CMD ["echo", "Hola desde Artifact Registry!"]
EOT

# Construir la imagen Docker localmente
docker build -t $LOCAL_IMAGE_TAG .
```

#### ACT (Implementación del escenario)
*Creamos el repositorio, configuramos la autenticación de Docker, etiquetamos la imagen para el registro y la subimos.*
```bash
# 1. Crear el repositorio de Artifact Registry
echo "\n=== Creando repositorio Docker... ==="
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Repositorio para imágenes Docker de prueba"

# 2. Configurar el helper de credenciales de Docker para gcloud
# Esto permite a Docker autenticarse con Artifact Registry usando tus credenciales de gcloud
echo "\n=== Configurando autenticación de Docker... ==="
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# 3. Etiquetar (tag) la imagen local con el nombre del repositorio de Artifact Registry
echo "\n=== Etiquetando la imagen... ==="
docker tag $LOCAL_IMAGE_TAG $AR_IMAGE_TAG

# 4. Subir (push) la imagen a Artifact Registry
echo "\n=== Subiendo la imagen a Artifact Registry... ==="
docker push $AR_IMAGE_TAG
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la imagen ahora existe en nuestro repositorio de Artifact Registry.*
```bash
# Listar las imágenes en el repositorio
echo "\n=== Verificando la imagen en Artifact Registry... ==="
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/$PROJECT_ID/$REPO_NAME
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la imagen del registro y el repositorio
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud artifacts docker images delete $AR_IMAGE_TAG --delete-tags --quiet
gcloud artifacts repositories delete $REPO_NAME --location=$REGION --quiet

# Eliminar la imagen local y el Dockerfile
docker rmi $LOCAL_IMAGE_TAG $AR_IMAGE_TAG
rm Dockerfile
```

---

## 💡 Lecciones Aprendidas

*   **Un Registro para Gobernarlos a Todos:** Centralizar todos tus artefactos (contenedores, paquetes de lenguajes) en un solo lugar simplifica la gestión, la seguridad y la auditoría.
*   **La Autenticación es Clave:** El comando `gcloud auth configure-docker` es esencial. Sin él, Docker no sabrá cómo autenticarse para subir o bajar imágenes de Artifact Registry.
*   **El Nombre Completo Importa:** La ruta completa de un artefacto (`<region>-<formato>.pkg.dev/...`) es la forma canónica de identificarlo y es necesaria para etiquetar y subir imágenes.

---

## ⚠️ Errores y Confusiones Comunes

*   **Olvidar `configure-docker`:** Es el error más frecuente. Si recibes un error de `permission denied` o `authentication required` al hacer `docker push`, es casi seguro que te falta este paso.
*   **Usar la URL de GCR (Container Registry):** Si vienes del antiguo Container Registry, puedes intentar usar por costumbre la URL `gcr.io/...`. La nueva URL para Artifact Registry es `*.pkg.dev`.
*   **Permisos de IAM Insuficientes:** Para subir una imagen, tu principal (usuario o SA) necesita el rol `roles/artifactregistry.writer`. Para bajarla, necesita `roles/artifactregistry.reader`.

---

## 🎯 Tips de Examen

*   **Sucesor de Container Registry:** Si una pregunta menciona la necesidad de almacenar imágenes de contenedor Y paquetes de Maven/npm, la respuesta es Artifact Registry.
*   **`gcloud auth configure-docker`:** Recuerda este comando como el paso necesario para integrar Docker con Artifact Registry.
*   **Formato de URL `pkg.dev`:** Asocia Artifact Registry con el dominio `pkg.dev`.

---

## 🧾 Resumen

Artifact Registry es el pilar del almacenamiento de artefactos en un ecosistema moderno de GCP. Al proporcionar un único servicio seguro, privado y gestionado para todos los paquetes y contenedores de tu software, se convierte en una pieza crítica del puzzle de la cadena de suministro de software (CI/CD), garantizando que los bloques de construcción de tus aplicaciones estén siempre disponibles, versionados y protegidos.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-artifact-registry)
