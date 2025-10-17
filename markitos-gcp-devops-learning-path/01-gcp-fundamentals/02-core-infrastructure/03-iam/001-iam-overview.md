# ☁️ Cloud Identity and Access Management (IAM)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-cloud-identity-and-access-management-iam)

---

## 🧭 Descripción

Cloud IAM es el sistema que te permite gestionar el control de acceso definiendo **quién** (identidad) puede hacer **qué** (rol/permiso) en **qué recurso**. Es el mecanismo de seguridad central de GCP que te permite aplicar el principio de privilegio mínimo (PoLP), asegurando que los usuarios y servicios solo tengan los permisos estrictamente necesarios para realizar su trabajo.

---

## 📘 Detalles

IAM se basa en tres componentes principales:

1.  **Principal (Quién):** Representa una identidad que puede solicitar acceso. Hay varios tipos:
    *   **Cuenta de Google:** Un usuario final (ej. `tu.email@gmail.com`).
    *   **Cuenta de Servicio (Service Account):** Una identidad para una aplicación o VM, no para un humano. Se usan para que los servicios se autentiquen entre sí.
    *   **Grupo de Google:** Una colección de cuentas de Google y/o cuentas de servicio.
    *   **Dominio de Google Workspace / Cloud Identity:** Todas las identidades de una organización.

2.  **Rol (Qué):** Un rol es una colección de permisos. En lugar de asignar permisos individuales, asignas roles, lo que simplifica enormemente la gestión.
    *   **Roles Básicos (Primitivos):** Roles históricos y muy amplios (Propietario, Editor, Visualizador). **No se recomiendan para producción** por ser demasiado permisivos.
    *   **Roles Predefinidos:** Roles granulares y específicos para cada servicio de GCP (ej. `roles/compute.instanceAdmin`, `roles/storage.objectViewer`). Son la opción recomendada.
    *   **Roles Personalizados (Custom):** Roles que puedes crear tú mismo con un conjunto de permisos específico.

3.  **Recurso (En qué):** El recurso de GCP al que se le está concediendo el acceso. Puede ser un proyecto, un bucket de Cloud Storage, una instancia de Compute Engine, etc. Los permisos se heredan hacia abajo en la jerarquía de recursos.

Una **política de IAM (IAM Policy)** es el objeto que une a uno o más principales con uno o más roles en un recurso específico.

```bash
# Ejemplo ilustrativo: Ver la política de IAM de tu proyecto actual.
# gcloud projects get-iam-policy: Obtiene la política de IAM completa de un proyecto.
# $PROJECT_ID: (Requerido) El ID del proyecto del que queremos ver la política.
# Muestra quién tiene qué roles en este proyecto.
gcloud projects get-iam-policy $PROJECT_ID
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear una Cuenta de Servicio y Asignarle un Rol Específico
**Contexto:** Crearemos una cuenta de servicio para una aplicación que necesita leer objetos de un bucket de Cloud Storage, pero no escribirlos ni borrarlos. Aplicaremos el principio de privilegio mínimo.
1
#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs necesarias
export PROJECT_ID=markitos-mdk-labs
gcloud services enable iam.googleapis.com storage.googleapis.com --project=$PROJECT_ID

# Variables de entorno
echo 'si ya estas en un proyecto podrias usar: export PROJECT_ID=$(gcloud config get-value project)'
export PROJECT_ID=$(gcloud config get-value project)
export SA_NAME="reader-app-sa"
export BUCKET_NAME="my-test-bucket-$PROJECT_ID"

# Crear un bucket de prueba
gsutil mb gs://$BUCKET_NAME

# Crear un fichero de prueba y subirlo
echo "hello world" > sample.txt
gsutil cp sample.txt gs://$BUCKET_NAME/
```

#### ACT (Implementación del escenario)
*Creamos la cuenta de servicio y luego le asignamos el rol predefinido `roles/storage.objectViewer` a nivel del bucket.*
```bash
# 1. Crear la cuenta de servicio
gcloud iam service-accounts create $SA_NAME --display-name="Reader App Service Account"

# 2. Asignar el rol a la cuenta de servicio en el bucket específico
export SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName='Reader App Service Account'" --format="value(email)")
gsutil iam ch serviceAccount:$SA_EMAIL:objectViewer gs://$BUCKET_NAME
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la cuenta de servicio puede leer objetos del bucket, pero no puede borrarlos.*
```bash
# Activar la cuenta de servicio para las siguientes operaciones
gcloud auth activate-service-account --key-file=<(gcloud iam service-accounts keys create - --iam-account=$SA_EMAIL)

# 1. Intentar leer el objeto (debería funcionar)
echo "=== Intentando leer (debería funcionar)... ==="
gsutil cat gs://$BUCKET_NAME/sample.txt

# 2. Intentar borrar el objeto (debería fallar)
echo "\n=== Intentando borrar (debería fallar)... ==="
gsutil rm gs://$BUCKET_NAME/sample.txt || echo "Fallo esperado. ¡Privilegio mínimo funcionando!"

# Volver a la autenticación de usuario
gcloud auth login
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el bucket y la cuenta de servicio
echo "\n=== Eliminando recursos de laboratorio... ==="
gsutil rm -r gs://$BUCKET_NAME
gcloud iam service-accounts delete $SA_EMAIL --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Siempre el Mínimo Privilegio:** No concedas roles de Editor o Propietario si un rol predefinido más restrictivo es suficiente. Es la regla de oro de la seguridad en la nube.
*   **Las Cuentas de Servicio son para las Máquinas:** Usa cuentas de servicio para que tus aplicaciones y VMs se autentiquen. No uses tus credenciales de usuario.
*   **Asigna roles en el recurso más bajo posible:** Si un usuario solo necesita acceso a un bucket, asígnale el rol en ese bucket, no en todo el proyecto.

---

## ⚠️ Errores y Confusiones Comunes

*   **Usar roles básicos (Propietario/Editor/Visualizador):** Es el error más común y peligroso. Son demasiado amplios para producción y violan el principio de privilegio mínimo.
*   **Confundir un rol con una política:** Un rol es una colección de permisos. Una política es la que une a un principal con un rol en un recurso.
*   **Dejar claves de cuentas de servicio expuestas:** Las claves JSON de las cuentas de servicio son credenciales muy potentes. Nunca las subas a un repositorio de código público.

---

## 🎯 Tips de Examen

*   **IAM es la respuesta para "quién puede hacer qué en qué recurso".** Cualquier pregunta sobre permisos se resuelve con IAM.
*   **Conoce los 3 tipos de roles:** Básico (Owner, Editor, Viewer), Predefinido (ej. `roles/compute.admin`) y Personalizado. El examen te pedirá que elijas el más apropiado.
*   **Entiende la herencia:** Una política de IAM aplicada a un proyecto se hereda a todos los recursos dentro de ese proyecto. Los permisos son aditivos (la unión de todas las políticas).

---

## 🧾 Resumen

Cloud IAM es el sistema nervioso de la seguridad en GCP. A través de la combinación de Principales, Roles y Políticas aplicadas a Recursos, te permite implementar un control de acceso granular y seguro. Dominar el principio de privilegio mínimo y el uso de roles predefinidos y cuentas de servicio es esencial para proteger tu infraestructura en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-identity-and-access-management-iam)
