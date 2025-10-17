# ☁️ Terraform en GCP: Gestionando Infraestructura como Código

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

**Terraform** es una herramienta de código abierto de HashiCorp para aprovisionar y gestionar infraestructura de forma segura y eficiente utilizando un lenguaje declarativo llamado HashiCorp Configuration Language (HCL). En el contexto de GCP, Terraform permite a los equipos de DevSecOps definir toda su infraestructura en la nube —desde redes VPC y proyectos hasta clústeres de GKE y bases de datos Cloud SQL— en archivos de código. Este código se puede versionar, reutilizar y compartir, promoviendo la automatización, la consistencia y la repetibilidad en la gestión del ciclo de vida de los recursos de la nube.

---

## 📘 Detalles

El uso de Terraform con GCP se centra en el **Proveedor de Google Cloud (Google Cloud Provider)**, que actúa como un puente entre la API de Terraform y las APIs de los servicios de GCP. El flujo de trabajo principal de Terraform es `init -> plan -> apply`.

### 🔹 Flujo de Trabajo de Terraform

1.  **Write (Escribir):** Se define la infraestructura deseada en archivos `.tf` usando HCL. Por ejemplo, para crear una red VPC, se usaría un recurso `google_compute_network`.
2.  **Init (Inicializar):** El comando `terraform init` prepara el directorio de trabajo. Su función principal es descargar los proveedores necesarios (como el de Google Cloud) y configurar el backend para el almacenamiento del estado.
3.  **Plan (Planificar):** El comando `terraform plan` crea un plan de ejecución. Terraform compara el estado deseado (definido en tus archivos `.tf`) con el estado actual de la infraestructura (almacenado en el archivo de estado) y determina qué cambios son necesarios (crear, modificar o destruir recursos). Este paso es crucial para verificar los cambios antes de aplicarlos.
4.  **Apply (Aplicar):** El comando `terraform apply` ejecuta el plan de acción generado en el paso anterior, realizando las llamadas a las APIs de GCP para llevar la infraestructura al estado deseado.

### 🔹 Estado (State)

Terraform mantiene un **archivo de estado** (generalmente `terraform.tfstate`) que mapea los recursos definidos en tu código con los recursos reales en la nube. Este archivo es fundamental para que Terraform sepa qué infraestructura está gestionando. En un entorno de equipo, es una mejor práctica almacenar este archivo de estado de forma remota y segura, por ejemplo, en un **bucket de Cloud Storage**, para permitir el trabajo colaborativo y evitar conflictos. A esto se le llama "Remote Backend".

### 🔹 Proveedor de Google Cloud

El proveedor se configura en un bloque `provider "google"`. Aquí se especifica el proyecto, la región y las credenciales a utilizar. La autenticación puede gestionarse de varias maneras, pero la forma más común y segura en un entorno de GCP es a través de la **suplantación de identidad de cuentas de servicio (Service Account Impersonation)** o utilizando las credenciales por defecto del entorno donde se ejecuta Terraform (ej. en Cloud Shell o una VM de Compute Engine).

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio utiliza Terraform para crear un bucket de Cloud Storage.

### ARRANGE (Preparación)

```bash
# Terraform ya viene preinstalado en Cloud Shell. Estos comandos se ejecutan allí.

# Crear un directorio para nuestro proyecto de Terraform
mkdir terraform-gcs-demo
cd terraform-gcs-demo

# Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET_NAME="tf-demo-bucket-${PROJECT_ID}"

# Crear el archivo de configuración principal de Terraform: main.tf
cat > main.tf << EOM
# Configura el proveedor de Google Cloud
provider "google" {
  project = "${PROJECT_ID}"
  region  = "europe-west1"
}

# Define un recurso: un bucket de Cloud Storage
resource "google_storage_bucket" "demo_bucket" {
  name          = "${BUCKET_NAME}" # El nombre del bucket debe ser único globalmente
  location      = "EU"
  force_destroy = true # Permite eliminar el bucket aunque contenga objetos

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# Define una salida para mostrar el nombre del bucket después de la creación
output "bucket_self_link" {
  value = google_storage_bucket.demo_bucket.self_link
}
EOM
```

### ACT (Implementación)

```bash
# 1. Inicializar Terraform
# Descarga el proveedor de Google Cloud y prepara el backend local.
terraform init

# 2. Crear el plan de ejecución
# Muestra los cambios que Terraform va a realizar (crear 1 bucket).
terraform plan

# 3. Aplicar los cambios
# Crea el bucket en GCP. Terraform pedirá confirmación.
terraform apply --auto-approve
```

### ASSERT (Verificación)

```bash
# 1. Verificar la salida de Terraform
# El comando 'apply' debería haber mostrado la salida 'bucket_self_link'.

# 2. Verificar el estado de Terraform
# Muestra los recursos que Terraform está gestionando actualmente.
terraform show

# 3. Verificar el recurso en GCP usando gcloud
# Confirma que el bucket existe realmente en Cloud Storage.
gsutil ls | grep gs://${BUCKET_NAME}/
```

### CLEANUP (Limpieza)

```bash
# Utilizar Terraform para destruir la infraestructura gestionada.
# Esto leerá el archivo de estado y eliminará todos los recursos definidos.
terraform destroy --auto-approve

# Volver al directorio padre y eliminar la carpeta del proyecto
cd ..
rm -rf terraform-gcs-demo
```

---

## 💡 Lecciones Aprendidas

*   **Mentalidad Declarativa:** Con Terraform, no describes *cómo* crear la infraestructura (pasos imperativos), sino *qué* infraestructura quieres que exista (declarativo). Terraform se encarga del resto.
*   **El Plan es tu Red de Seguridad:** `terraform plan` es posiblemente el comando más importante. Siempre revisa el plan antes de aplicar cualquier cambio para evitar sorpresas costosas o destructivas.
*   **El Estado es Sagrado:** El archivo de estado es la única fuente de verdad de Terraform. Perderlo o corromperlo puede desincronizar tu código de la realidad. Usa siempre un backend remoto en proyectos serios.

---

## ⚠️ Errores y Confusiones Comunes

*   **Editar Recursos Manualmente:** Si creas un recurso con Terraform y luego lo modificas manualmente a través de la Consola de GCP, tu estado de Terraform quedará desactualizado. La próxima vez que ejecutes `plan` o `apply`, Terraform intentará revertir tus cambios manuales. A esto se le llama "state drift".
*   **Almacenar el Estado en Git:** Nunca, bajo ninguna circunstancia, subas el archivo `terraform.tfstate` a un repositorio de Git, especialmente si es público. Puede contener información sensible y no maneja bien los cambios concurrentes de varios usuarios.
*   **No Usar un Backend Remoto para Equipos:** Si varios desarrolladores ejecutan Terraform desde sus máquinas locales con un estado local, crearán recursos duplicados o entrarán en conflicto. El backend remoto (ej. un bucket de GCS) con bloqueo de estado es esencial para el trabajo en equipo.

---

## 🎯 Tips de Examen

*   **Flujo `plan`/`apply`:** Las preguntas de examen a menudo se centran en el propósito del flujo de trabajo. **`plan`** es para **verificar** y **`apply`** es para **ejecutar**.
*   **Gestión de Estado (State):** Si una pregunta habla de colaboración, equipos o un entorno de CI/CD para Terraform, la respuesta correcta siempre implica un **backend remoto** (como Cloud Storage) para el archivo de estado.
*   **Terraform vs. Cloud Deployment Manager:** Terraform es de código abierto y multi-nube. **Cloud Deployment Manager** es la herramienta de IaC nativa de GCP, usa plantillas YAML y es específica de Google Cloud. Terraform es generalmente preferido por su ecosistema más grande y su flexibilidad.

---

## 🧾 Resumen

Terraform es la herramienta estándar de la industria para implementar Infraestructura como Código en GCP. A través de su lenguaje declarativo (HCL) y su flujo de trabajo `plan/apply`, permite a los equipos definir, versionar y gestionar de forma segura y predecible toda su infraestructura en la nube, desde una simple VM hasta complejas topologías de red, tratando los recursos de la nube como componentes de software.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-terraform-en-gcp-gestionando-infraestructura-como-código)
