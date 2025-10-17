# 🔑 Cuentas de Servicio (Service Accounts) en IAM

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-cuentas-de-servicio-service-accounts-en-iam)

---

## 🧭 Descripción

Este es un capítulo de profundización sobre las Cuentas de Servicio (Service Accounts), uno de los conceptos más críticos en la seguridad de GCP. Mientras que los usuarios humanos se autentican con contraseñas y 2FA, las aplicaciones y cargas de trabajo (workloads) necesitan su propia identidad para interactuar con las APIs de Google Cloud de forma segura. Esa identidad es la Cuenta de Servicio.

---

## 📘 Detalles

Una cuenta de servicio es un tipo especial de **principal** en Cloud IAM que representa una identidad no humana.

### Tipos de Cuentas de Servicio

1.  **Gestionadas por el usuario (User-managed):** Son las que tú creas en tu proyecto. Tienes control total sobre ellas y eres responsable de su seguridad.
    *   **Default Service Account:** Cada proyecto viene con una Cuenta de Servicio de Compute Engine por defecto, que tiene el rol de Editor. Es muy permisiva y **no se recomienda su uso en producción**.
2.  **Gestionadas por Google (Google-managed):** Son cuentas de servicio creadas y gestionadas por Google cuando habilitas ciertas APIs. Actúan en tu nombre para realizar tareas en segundo plano (ej. `service-PROJECT_NUMBER@gcp-sa-cloud-storage.iam.gserviceaccount.com`).

### Claves de Cuentas de Servicio (Service Account Keys)

Una clave de cuenta de servicio es un fichero JSON que contiene una credencial de larga duración. Permite a una aplicación autenticarse como la cuenta de servicio desde **cualquier lugar**, incluso fuera de GCP. **Las claves son un riesgo de seguridad significativo.** Si una clave se filtra, un atacante puede usarla para acceder a tus recursos.

**Mejor Práctica:** ¡EVITA LAS CLAVES SIEMPRE QUE SEA POSIBLE!

### Alternativas Seguras a las Claves

1.  **Cuentas de Servicio Adjuntas (Attached Service Accounts):** Es la forma preferida de autenticación dentro de GCP. Cuando creas una VM, un Cloud Function o un pod de GKE, puedes "adjuntarle" una cuenta de servicio. El servicio adquiere la identidad de esa cuenta automáticamente a través del servidor de metadatos, sin necesidad de gestionar claves.

2.  **Workload Identity Federation:** Es el método moderno para que cargas de trabajo que corren **fuera de GCP** (en AWS, Azure, on-premise) se autentiquen en GCP **sin usar claves**. Funciona estableciendo una relación de confianza entre GCP y un proveedor de identidad externo.

### 🔹 El Permiso "actAs": ¿Por qué una SA necesita permisos sobre sí misma?

Este es uno de los conceptos más confusos de IAM. A menudo verás un comando como este, que le da a una cuenta de servicio permiso para actuar como sí misma:

```bash
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"
```

A primera vista, parece redundante. ¿Por qué una cuenta de servicio necesitaría permiso para usarse a sí misma?

**La Analogía de la Fábrica y el Robot:**

*   Piensa en una **Cuenta de Servicio (SA)** como un **robot trabajador** autónomo.
*   Piensa en una **Máquina Virtual (VM)** como una **fábrica**.

Para que una VM pueda usar los poderes de una SA, primero debes "adjuntar" la SA a la VM. Cuando haces esto, la VM hereda la identidad del robot.

El sistema de seguridad de GCP, en su rigor, se pregunta: "¿Tiene esta fábrica permiso para usar este robot?". El permiso para "usar" un robot (una SA) es `iam.serviceAccounts.actAs`, que está incluido en el rol `roles/iam.serviceAccountUser`.

Cuando la VM se inicia, el sistema de Google Cloud (actuando en nombre de la VM) intenta obtener credenciales del robot (la SA). Para que esto funcione, el robot debe tener una **"autolicencia"** que le permita ser usado por el recurso al que está adjunto.

En resumen, este comando no le da a la SA el poder de hacer algo nuevo. En cambio, **le da permiso a la SA para ser utilizada por un recurso de GCP (como una VM) al que está adjunta.** Sin esta autolicencia, no podrías asignar la SA a una VM para que la VM la use.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Autenticación Local con una Clave de Cuenta de Servicio
**Contexto:** Simularemos un caso de uso de desarrollo local donde una aplicación en tu portátil necesita subir ficheros a un bucket. Usaremos una clave JSON, pero destacaremos las advertencias de seguridad.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable iam.googleapis.com storage.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export SA_NAME="local-dev-sa"
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
export BUCKET_NAME="bucket-for-local-dev-$PROJECT_ID"
export KEY_FILE="./sa-key.json"

# Crear bucket y cuenta de servicio
gsutil mb gs://$BUCKET_NAME

# gcloud iam service-accounts create: Crea una nueva cuenta de servicio.
# $SA_NAME: Es el ID único para la nueva cuenta de servicio.
# --display-name: Es un nombre descriptivo y legible para la SA.
gcloud iam service-accounts create $SA_NAME --display-name="Local Dev SA"
```

#### ACT (Implementación del escenario)
*Damos permiso a la SA solo para escribir en el bucket y descargamos la clave.*
```bash
# 1. Asignar el rol específico en el recurso específico (el bucket)
gsutil iam ch serviceAccount:$SA_EMAIL:objectCreator gs://$BUCKET_NAME

# 2. Crear y descargar la clave JSON (¡OPERACIÓN PELIGROSA!)
echo "⚠️  Creando una clave de cuenta de servicio. ¡Manéjala con cuidado!" 
gcloud iam service-accounts keys create $KEY_FILE --iam-account=$SA_EMAIL
```

#### ASSERT (Verificación de funcionalidades)
*Activamos la SA y verificamos que podemos escribir en el bucket, pero no realizar otras acciones, como listar buckets.*
```bash
# 1. Activar la cuenta de servicio usando la clave
gcloud auth activate-service-account --key-file=$KEY_FILE

# 2. Intentar subir un fichero (debería funcionar)
echo "hello" > test.txt
echo "\n=== Intentando subir fichero (debería funcionar)... ==="
gsutil cp test.txt gs://$BUCKET_NAME/

# 3. Intentar listar buckets (debería fallar)
echo "\n=== Intentando listar buckets (debería fallar)... ==="
gsutil ls || echo "Fallo esperado. ¡Principio de privilegio mínimo funcionando!"

# 4. Volver a la autenticación de usuario
gcloud auth login
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la clave local, el bucket y la SA
echo "\n=== Eliminando recursos de laboratorio... ==="
rm $KEY_FILE
rm test.txt
gsutil rm -r gs://$BUCKET_NAME
gcloud iam service-accounts delete $SA_EMAIL --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Las claves son el último recurso:** Solo deberías usar claves de SA si no hay absolutamente ninguna otra forma de autenticar tu carga de trabajo.
*   **Identidad por Carga de Trabajo:** El paradigma moderno es asignar identidades a las cargas de trabajo (VMs, contenedores), no distribuir credenciales.
*   **La Cuenta de Servicio Default es un riesgo:** El rol de Editor que tiene por defecto es demasiado amplio. Siempre crea y asigna cuentas de servicio específicas para tus aplicaciones.

---

## ⚠️ Errores y Confusiones Comunes

*   **Commitear claves a Git:** Es el error de seguridad más grave y común. Las claves JSON nunca deben estar en el control de versiones.
*   **Reutilizar la misma cuenta de servicio para múltiples aplicaciones:** Dificulta la aplicación del privilegio mínimo y la auditoría.
*   **No rotar las claves:** Si debes usar claves, deben ser rotadas periódicamente para minimizar el riesgo en caso de que se filtren.

---

## 🎯 Tips de Examen

*   **Pregunta clave:** "¿Cuál es la forma MÁS SEGURA para que una VM de Compute Engine acceda a Cloud Storage?" **Respuesta:** Asignarle una cuenta de servicio con los roles necesarios (Attached Service Account).
*   **Workload Identity Federation:** Si la pregunta involucra autenticar desde AWS, Azure u on-premise SIN claves, la respuesta es Workload Identity Federation.
*   **Diferencia entre `iam.serviceAccountUser` y `iam.serviceAccountTokenCreator`:** `serviceAccountUser` permite adjuntar una SA a un recurso. `serviceAccountTokenCreator` permite impersonar a una SA para obtener tokens de corta duración.

---

## 🧾 Resumen

Las Cuentas de Servicio son la piedra angular de la seguridad programática en GCP. Permiten a las aplicaciones y servicios autenticarse de forma segura para acceder a las APIs de Google. La práctica recomendada es evitar el uso de claves de larga duración y, en su lugar, aprovechar las identidades de carga de trabajo nativas de la nube, como las cuentas de servicio adjuntas, para aplicar el principio de privilegio mínimo de forma eficaz.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cuentas-de-servicio-service-accounts-en-iam)
