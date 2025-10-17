# ⚙️ Cloud Build

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#️-cloud-build)

---

## 🧭 Descripción

Cloud Build es el servicio de Integración Continua (CI) y construcción totalmente gestionado y serverless de Google Cloud. Te permite construir, probar y desplegar artefactos (como imágenes de contenedor o paquetes de software) de forma rápida y consistente. Cloud Build ejecuta tus compilaciones en la infraestructura de Google, lo que significa que no tienes que gestionar tus propios servidores de compilación, y pagas solo por el tiempo de compilación que consumes.

---

## 📘 Detalles

### Conceptos Clave de Cloud Build

1.  **Pasos de Compilación (Build Steps):** Una compilación es una secuencia de pasos. Cada paso se ejecuta en un contenedor Docker, lo que garantiza un entorno limpio y reproducible. Un paso puede hacer cualquier cosa que puedas hacer en un contenedor: compilar código, ejecutar tests, construir una imagen de Docker, hacer push a un registro, etc.

2.  **Constructores (Builders):** Son imágenes de contenedor con herramientas comunes preinstaladas (como `gcloud`, `docker`, `git`, `go`, `npm`). Google proporciona una serie de constructores soportados, pero también puedes usar cualquier imagen de Docker pública o privada como un paso de compilación.

3.  **Fichero de Configuración (`cloudbuild.yaml`):** Es el fichero YAML donde defines los pasos de tu compilación. Este fichero vive junto a tu código fuente, tratando al pipeline de CI como parte de tu aplicación (Pipelines as Code).

4.  **Disparadores (Triggers):** Un disparador conecta un evento de tu repositorio de código fuente (como un `push` a una rama o la creación de una etiqueta) con una configuración de compilación. Cuando el evento ocurre, Cloud Build inicia automáticamente una nueva compilación.

5.  **Cuenta de Servicio de Cloud Build:** Cada compilación se ejecuta con la identidad de una cuenta de servicio de Cloud Build. Por defecto, esta cuenta tiene permisos bastante amplios en el proyecto, pero es una mejor práctica de seguridad reducir sus permisos al mínimo necesario para que la compilación funcione.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Construir una Imagen de Contenedor y Subirla a Artifact Registry
**Contexto:** Crearemos un pipeline de CI simple que se activa al hacer un `push` a un repositorio. El pipeline construirá una imagen de Docker a partir de un `Dockerfile` y la subirá a Artifact Registry, el servicio de GCP para almacenar artefactos.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable cloudbuild.googleapis.com sourcerepo.googleapis.com artifactregistry.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export REPO_NAME="app-for-build"
export AR_REPO_NAME="my-docker-repo"

# Crear repositorio de Artifact Registry para Docker
# gcloud artifacts repositories create: Crea un nuevo repositorio en Artifact Registry.
# $AR_REPO_NAME: (Requerido) El nombre del repositorio.
# --repository-format: (Requerido) El formato de los artefactos (docker, maven, etc.).
# --location: (Requerido) La región donde se creará el repositorio.
gcloud artifacts repositories create $AR_REPO_NAME --repository-format=docker --location=$REGION

# Crear repositorio de Cloud Source y clonarlo
# gcloud source repos create: Crea un repositorio de código Git gestionado por Google.
# gcloud source repos clone: Clona el repositorio a tu entorno local.
gcloud source repos create $REPO_NAME
gcloud source repos clone $REPO_NAME && cd $REPO_NAME

# Crear ficheros de la aplicación
cat <<EOT > Dockerfile
FROM alpine
CMD ["echo", "Hello from Cloud Build!"]
EOT

cat <<EOT > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${_LOCATION}-docker.pkg.dev/$PROJECT_ID/${_AR_REPO_NAME}/hello-image:latest', '.']
images:
- '${_LOCATION}-docker.pkg.dev/$PROJECT_ID/${_AR_REPO_NAME}/hello-image:latest'
EOT

# Hacer commit y push inicial
git add . && git commit -m "Initial commit" && git push --set-upstream origin master
```

#### ACT (Implementación del escenario)
*Creamos un disparador que escucha los `push` a la rama `master` y luego realizamos un nuevo `push` para activarlo.*
```bash
# 1. Crear el disparador de Cloud Build.
# gcloud builds triggers create github: Crea un disparador (en este caso, para un repo de Cloud Source, aunque el comando diga 'github').
# --name: (Requerido) Nombre para el disparador.
# --repo: (Requerido) La URL del repositorio de código fuente.
# --branch-pattern: (Requerido) Un patrón de expresión regular para la rama que activará el build.
# --build-config: (Requerido) La ruta al fichero de configuración de la compilación (cloudbuild.yaml).
# --substitutions: (Opcional) Variables que se pasarán al build.
gcloud builds triggers create github --name="trigger-main" \
    --repo="https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME" \
    --branch-pattern="^master$" \
    --build-config="cloudbuild.yaml" \
    --substitutions="_LOCATION=$REGION,_AR_REPO_NAME=$AR_REPO_NAME"

# 2. Realizar un cambio y hacer push para activar el disparador
echo "# Un cambio para activar el build" >> README.md
git add . && git commit -m "Trigger build" && git push
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos el historial de compilaciones para ver si nuestro build se ha ejecutado y luego comprobamos que la imagen existe en Artifact Registry.*
```bash
# 1. Esperar y luego listar el historial de compilaciones
echo "\n=== Esperando al build... (puede tardar ~1 min) ==="
sleep 60
# gcloud builds list: Muestra el historial de compilaciones de Cloud Build.
# --limit=1: (Opcional) Limita la salida al build más reciente.
gcloud builds list --limit=1

# 2. Verificar que la imagen ha sido subida a Artifact Registry
echo "\n=== Verificando la imagen en Artifact Registry... ==="
# gcloud artifacts docker images list: Lista las imágenes de Docker en un repositorio de Artifact Registry.
# La URL completa del repositorio es necesaria.
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/$PROJECT_ID/$AR_REPO_NAME
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar todo
cd .. && rm -rf $REPO_NAME
gcloud builds triggers delete trigger-main --quiet
gcloud source repos delete $REPO_NAME --quiet
gcloud artifacts repositories delete $AR_REPO_NAME --location=$REGION --quiet
```

---

## 💡 Lecciones Aprendidas

*   **Todo es un Contenedor:** La potencia de Cloud Build reside en que cada paso es un contenedor efímero y limpio, lo que garantiza compilaciones consistentes y sin efectos secundarios.
*   **Pipelines como Código:** Definir tu pipeline en `cloudbuild.yaml` te permite versionarlo junto con tu aplicación, facilitando la auditoría y la gestión de cambios.
*   **Aprovecha las Sustituciones:** Usa variables de sustitución (`_VARIABLE_NAME`) en tu `cloudbuild.yaml` para parametrizar tus compilaciones y hacerlas más reutilizables.

---

## ⚠️ Errores y Confusiones Comunes

*   **Permisos de la Cuenta de Servicio:** El error más común es que una compilación falle porque la cuenta de servicio de Cloud Build no tiene los permisos necesarios para interactuar con otros servicios (ej. desplegar en Cloud Run o GKE).
*   **No cachear las dependencias:** Las compilaciones pueden ser lentas si en cada ejecución se descargan todas las dependencias desde cero. Cloud Build ofrece mecanismos de cacheo para acelerar este proceso.
*   **Escribir ficheros `cloudbuild.yaml` monolíticos:** Para pipelines complejos, puedes dividirlos en múltiples ficheros YAML e importarlos, o usar plantillas para mejorar la reutilización.

---

## 🎯 Tips de Examen

*   **CI/CD Serverless en GCP = Cloud Build:** Si un escenario requiere un sistema de CI/CD totalmente gestionado y serverless, la respuesta es Cloud Build.
*   **`cloudbuild.yaml`:** Es el fichero de configuración clave. Conoce su estructura básica (la sección `steps`).
*   **Triggers:** Entiende que los disparadores son el pegamento entre tu repositorio de código y el pipeline de compilación.

---

## 🧾 Resumen

Cloud Build es el motor de CI/CD en el corazón del ecosistema de desarrollo de Google Cloud. Al proporcionar un entorno de compilación serverless, efímero y basado en contenedores, permite a los equipos automatizar la construcción, prueba y despliegue de su software de una manera rápida, segura y escalable. Su profunda integración con el resto de servicios de GCP lo convierte en la opción natural para cualquier flujo de trabajo de DevOps en la plataforma.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#️-cloud-build)
