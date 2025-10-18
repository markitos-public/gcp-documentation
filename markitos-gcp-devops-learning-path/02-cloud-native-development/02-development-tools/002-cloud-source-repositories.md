# 🛠️ Cloud Source Repositories

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#️-cloud-source-repositories)

---

## 🧭 Descripción

Cloud Source Repositories es el servicio de repositorios de Git privados, totalmente gestionado, de Google Cloud. Proporciona un lugar centralizado para que los equipos alojen y colaboren en su código fuente. Aunque ofrece funcionalidades similares a otros servicios como GitHub, GitLab o Bitbucket, su principal ventaja es la integración nativa con el ecosistema de GCP, especialmente con servicios como Cloud Build, Cloud Deploy y las herramientas de observabilidad.

---

## 📘 Detalles

### Funcionalidades Clave

1.  **Repositorios Git Privados:** Ofrece repositorios Git estándar y privados sin límite de tamaño, alojados en la infraestructura segura de Google.

2.  **Integración con IAM:** El acceso a los repositorios se controla mediante los permisos de Cloud IAM, permitiendo una gestión de acceso granular y coherente con el resto de tus recursos de GCP.

3.  **Conexión con Cloud Build:** Puedes configurar "triggers" (disparadores) en Cloud Build para que inicien automáticamente un pipeline de CI/CD cada vez que se hace un `push` a una rama específica o se crea una etiqueta en un repositorio.

4.  **Sincronización con Repositorios Externos:** Una de sus características más potentes es la capacidad de sincronizar (mirroring) repositorios de GitHub o Bitbucket. Esto te permite seguir usando las herramientas y flujos de trabajo de GitHub/Bitbucket para la colaboración, mientras que el código se copia automáticamente a Cloud Source Repositories para ser utilizado por los servicios de CI/CD de GCP.

5.  **Búsqueda de Código (Source Code Search):** Proporciona una potente herramienta de búsqueda que te permite buscar código en todos tus repositorios utilizando expresiones regulares.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear un Repositorio y Conectarlo a un Remoto Local
**Contexto:** Crearemos un nuevo repositorio en Cloud Source Repositories y lo configuraremos como un remoto para un repositorio Git local, simulando el inicio de un nuevo proyecto.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable sourcerepo.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REPO_NAME="mi-primera-app"
export LOCAL_DIR="mi-primera-app-local"

# Crear un directorio local para simular el proyecto
mkdir $LOCAL_DIR
cd $LOCAL_DIR
git init
echo "# Mi Primera App" > README.md
git add README.md
git commit -m "Initial commit"
```

#### ACT (Implementación del escenario)
*Creamos el repositorio en GCP y luego lo añadimos como un remoto a nuestro repositorio Git local.*
```bash
# 1. Crear el repositorio en Cloud Source Repositories
echo "\n=== Creando repositorio en GCP... ==="
gcloud source repos create $REPO_NAME

# 2. Añadir el repositorio de GCP como un remoto llamado 'google'
# El SDK de gcloud puede inyectar credenciales automáticamente
echo "\n=== Configurando remoto local... ==="
git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME

# 3. Hacer push de la rama principal al nuevo remoto
echo "\n=== Haciendo push a Cloud Source Repositories... ==="
git push --all google
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que el repositorio existe en GCP y que podemos listar las ramas, viendo la rama `main` o `master` que acabamos de subir.*
```bash
# 1. Listar los repositorios en el proyecto
echo "\n=== Verificando repositorios en GCP... ==="
gcloud source repos list --filter="name~projects/$PROJECT_ID/repos/$REPO_NAME"

# 2. Clonar el repositorio en un nuevo directorio para verificar el contenido
echo "\n=== Clonando para verificar... ==="
cd ..
gcloud source repos clone $REPO_NAME cloned-repo
cat cloned-repo/README.md
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el repositorio en la nube y los directorios locales
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud source repos delete $REPO_NAME --quiet
rm -rf $LOCAL_DIR
rm -rf cloned-repo
```

---

## 💡 Lecciones Aprendidas

*   **Integración es su Fuerte:** La razón principal para usar Cloud Source Repositories es su integración nativa y sin fricciones con Cloud Build y otras herramientas de GCP.
*   **No es un "GitHub Killer":** No intenta reemplazar las funcionalidades sociales y de gestión de proyectos de GitHub/Bitbucket. Por eso, el modelo de sincronización es tan útil.
*   **La Autenticación es Sencilla:** Al usar `gcloud`, la autenticación con los repositorios es transparente, sin necesidad de gestionar claves SSH o tokens de acceso manualmente.

---

## ⚠️ Errores y Confusiones Comunes

*   **Esperar funcionalidades de gestión de proyectos:** Cloud Source Repositories no tiene Issues, Pull Requests (en el sentido completo de GitHub), o tableros Kanban. Es puramente un host de Git.
*   **Confundir la sincronización con una migración:** La sincronización es continua. Si quieres moverte completamente desde GitHub, debes importar el repositorio y luego desactivar la sincronización.
*   **Problemas de permisos:** Si `gcloud` no puede acceder, casi siempre es un problema de permisos de IAM. Asegúrate de que el principal (usuario o SA) tiene el rol `source.repository.writer` o similar.

---

## 🎯 Tips de Examen

*   **Integración con Cloud Build:** Si un escenario describe la necesidad de iniciar un pipeline de CI/CD automáticamente desde un repositorio Git dentro de GCP, la respuesta es una combinación de Cloud Source Repositories y Cloud Build Triggers.
*   **Sincronización (Mirroring):** Si una empresa quiere usar Cloud Build pero su equipo de desarrollo se niega a dejar GitHub/Bitbucket, la solución es sincronizar el repositorio externo con Cloud Source Repositories.
*   **`gcloud source repos clone`:** Es el comando para clonar un repositorio, una alternativa a `git clone` que gestiona la autenticación automáticamente.

---

## 🧾 Resumen

Cloud Source Repositories es una solución de hosting de Git robusta y segura, diseñada para integrarse perfectamente en el flujo de trabajo de desarrollo y CI/CD de Google Cloud. Aunque no compite en funcionalidades de colaboración con plataformas como GitHub, su principal valor reside en actuar como el "pegamento" nativo entre tu código fuente y los potentes servicios de automatización y despliegue de GCP.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#️-cloud-source-repositories)
