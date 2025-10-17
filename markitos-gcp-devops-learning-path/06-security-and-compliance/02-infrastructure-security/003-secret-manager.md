# ☁️ Secret Manager: Almacenamiento Seguro de Secretos de Aplicación

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

**Secret Manager** es un servicio de Google Cloud diseñado para almacenar, gestionar y acceder de forma segura a secretos de aplicación como claves de API, contraseñas de bases de datos, certificados TLS y otras credenciales. Proporciona un lugar centralizado y seguro para este tipo de información sensible, eliminando la necesidad de almacenarlos en el código fuente, en archivos de configuración o en variables de entorno, prácticas que son inseguras y difíciles de gestionar. Secret Manager se integra con IAM para un control de acceso granular y proporciona un registro de auditoría completo de quién accedió a qué secreto y cuándo.

---

## 📘 Detalles

Secret Manager ofrece una API simple para el ciclo de vida completo de un secreto, desde su creación hasta su destrucción, pasando por el control de versiones.

### 🔹 Jerarquía y Componentes

1.  **Secreto (Secret):** Es el recurso principal que agrupa y gestiona un conjunto de versiones. Un secreto tiene un nombre lógico (ej. `prod-db-password`) y políticas de IAM y de replicación asociadas. La política de replicación define si el secreto se replica automáticamente en múltiples regiones de GCP o si se restringe a una sola.

2.  **Versión del Secreto (Secret Version):** Cada secreto puede tener múltiples versiones. Una versión contiene el *payload* real del secreto (la cadena de bytes que conforma la contraseña o la clave de API). Las versiones son inmutables. Cuando se actualiza un secreto, se crea una nueva versión. Las versiones pueden tener estados: `ENABLED`, `DISABLED` o `DESTROYED`.

3.  **Control de Acceso (IAM):** El acceso a los secretos se controla rigurosamente a través de roles de IAM. El rol más importante es `roles/secretmanager.secretAccessor`, que concede permiso para *leer el valor* de las versiones de un secreto. Otros roles permiten gestionar los secretos y sus versiones (`roles/secretmanager.admin`) sin necesariamente poder leer su contenido.

### 🔹 Integración con Cloud KMS

Por defecto, los secretos en Secret Manager se cifran en reposo con claves gestionadas por Google. Sin embargo, para un mayor control, se puede configurar un secreto para que utilice una clave gestionada por el cliente (CMEK - Customer-Managed Encryption Key) almacenada en **Cloud KMS**. Esto añade una capa adicional de protección, ya que para acceder al secreto, una entidad necesita permisos de IAM tanto en Secret Manager (`secretAccessor`) como en Cloud KMS (`cryptoKeyDecrypter`).

### 🔹 Rotación y Notificaciones

Secret Manager no rota automáticamente los secretos, pero facilita este proceso. Se pueden configurar notificaciones a través de Pub/Sub para que se envíe un mensaje cuando un secreto se acerca a su fecha de expiración (definida por el usuario). Este mensaje puede activar una Cloud Function que ejecute la lógica de rotación (ej. generar una nueva contraseña en la base de datos y añadirla como nueva versión en Secret Manager).

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio muestra cómo crear un secreto, acceder a él desde la línea de comandos y luego limpiarlo.

### ARRANGE (Preparación)

```bash
# 1. Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export SECRET_ID="my-api-key"

# 2. Habilitar la API de Secret Manager
gcloud services enable secretmanager.googleapis.com

# 3. Crear un secreto (el contenedor lógico)
gcloud secrets create $SECRET_ID \
    --replication-policy="automatic"

# 4. Conceder a tu propio usuario el permiso para acceder al secreto
# (Normalmente se lo darías a una cuenta de servicio)
export USER_EMAIL=$(gcloud config get-value account)
gcloud secrets add-iam-policy-binding $SECRET_ID \
    --member="user:${USER_EMAIL}" \
    --role="roles/secretmanager.secretAccessor"
```

### ACT (Implementación)

```bash
# 1. Añadir la primera versión del secreto
# El payload del secreto se puede pasar directamente o desde un archivo.
# Usamos -n para evitar que se añada un salto de línea al final.
echo -n "s3cr3t-ap1-k3y-v4lu3" | gcloud secrets versions add $SECRET_ID --data-file=-

# 2. Acceder a la versión más reciente (latest) del secreto
# El comando `access` recupera el payload del secreto.
export RETRIEVED_SECRET=$(gcloud secrets versions access latest --secret=$SECRET_ID)
```

### ASSERT (Verificación)

```bash
# 1. Verificar que el secreto recuperado es el correcto
# Comparamos el valor original con el que obtuvimos de Secret Manager.
if [ "$RETRIEVED_SECRET" == "s3cr3t-ap1-k3y-v4lu3" ]; then
    echo "Éxito: El secreto recuperado coincide con el original."
else
    echo "Error: El secreto recuperado NO coincide."
fi

# 2. Describir el secreto para ver sus metadatos
gcloud secrets describe $SECRET_ID

# 3. Listar las versiones del secreto (debería mostrar la versión 1)
gcloud secrets versions list $SECRET_ID
```

### CLEANUP (Limpieza)

```bash
# Eliminar el secreto y todas sus versiones
# Esta acción es irreversible.
gcloud secrets delete $SECRET_ID --quiet

# Quitar el rol de IAM (opcional, ya que el secreto no existe)
gcloud secrets remove-iam-policy-binding $SECRET_ID \
    --member="user:${USER_EMAIL}" \
    --role="roles/secretmanager.secretAccessor" --condition=None --all
```

---

## 💡 Lecciones Aprendidas

*   **Los Secretos no Pertenecen al Código:** La lección más importante. Externalizar los secretos a un servicio gestionado como Secret Manager es una práctica de seguridad fundamental que reduce drásticamente la superficie de ataque.
*   **El Acceso a Secretos es un Evento Auditable:** Cada vez que una aplicación o un usuario accede a un secreto, se genera un log de auditoría. Esto proporciona una visibilidad crucial para la monitorización de la seguridad y la respuesta a incidentes.
*   **La Versión `latest` es una Abstracción Poderosa:** Las aplicaciones pueden simplemente solicitar la versión `latest` de un secreto. Esto desacopla la aplicación del proceso de rotación de secretos. Cuando se rota la contraseña, se añade una nueva versión, y la próxima vez que la aplicación solicite `latest`, recibirá el nuevo valor sin necesidad de un redespliegue.

---

## ⚠️ Errores y Confusiones Comunes

*   **Error: Dar Permisos de `secretAccessor` a Entidades Equivocadas:** Conceder este permiso a un grupo amplio de usuarios o a una cuenta de servicio utilizada por múltiples aplicaciones viola el principio de mínimo privilegio. Solo la aplicación específica que necesita el secreto debe tener acceso a él.
*   **Confusión: Secret Manager vs. Cloud KMS:** KMS gestiona **claves criptográficas** para realizar operaciones (cifrar/descifrar). Secret Manager gestiona **datos secretos** (como contraseñas) para ser entregados a una aplicación. Secret Manager *usa* cifrado (potencialmente con claves de KMS) para proteger los secretos que almacena.
*   **Problema: No Rotar los Secretos:** Secret Manager facilita la rotación, pero no la hace por ti. No establecer una política y un proceso de rotación para secretos de larga duración (como contraseñas de bases de datos) es una mala práctica de seguridad.

---

## 🎯 Tips de Examen

*   **Rol de IAM Clave:** `roles/secretmanager.secretAccessor` es el permiso para **leer** el valor de un secreto. Es el más sensible y el que más probablemente aparezca en preguntas.
*   **Control de Versiones:** Entiende que los secretos tienen versiones y que se puede acceder a una versión específica por su número o a la más reciente con el alias `latest`.
*   **Integración con CMEK:** Recuerda que puedes usar tus propias claves de Cloud KMS (Customer-Managed Encryption Keys) para una capa extra de protección de cifrado.
*   **Diferencia con KMS:** Prepárate para preguntas que pongan a prueba tu comprensión de la diferencia entre almacenar una clave de API (Secret Manager) y gestionar una clave de firma (KMS).

---

## 🧾 Resumen

Secret Manager es la solución nativa de GCP para el almacenamiento seguro y la gestión del ciclo de vida de los secretos de aplicación. Al centralizar las credenciales, controlar el acceso con IAM y proporcionar auditoría completa, permite a los desarrolladores construir aplicaciones más seguras y a los equipos de operaciones gestionar la seguridad a escala, eliminando la peligrosa práctica de codificar secretos en el software.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-secret-manager-almacenamiento-seguro-de-secretos-de-aplicación)
