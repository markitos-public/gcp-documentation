# ☁️ Políticas de Denegación de IAM y Mínimo Privilegio

## 📑 Índice

* [🧭 Descripción](#-descripción)
* [📘 Detalles de IAM Deny](#-detalles-de-iam-deny)
* [⚠️ **Prerrequisito Clave: Requiere Organización de GCP**](#️-prerrequisito-clave-requiere-organización-de-gcp)
* [🔬 Laboratorio Práctico: Mínimo Privilegio (Denegar por Defecto)](#-laboratorio-práctico-mínimo-privilegio-denegar-por-defecto)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Descripción

Este documento cubre dos conceptos de seguridad fundamentales en IAM:
1.  **Políticas de Denegación de IAM (IAM Deny):** Una característica avanzada para establecer barreras de seguridad que anulan cualquier permiso concedido.
2.  **Principio de Mínimo Privilegio (Denegar por Defecto):** El concepto de que el acceso es denegado simplemente por no haber sido concedido explícitamente.

---

## 📘 Detalles de IAM Deny

### 🔹 La Regla de Oro: Denegar Siempre Gana

El modelo de evaluación de IAM considera las políticas de concesión y las de denegación. El acceso a un recurso solo se permite si:
1.  Hay una política de concesión (Allow Policy) que otorga el permiso.
2.  **NO** hay una política de denegación explícita (Deny Policy) que revoque ese permiso.

### 🔹 Estructura de una Política de Denegación

Una política de denegación consta de reglas que especifican:
*   **Principales Denegados (Denied Principals):** La identidad o conjunto de identidades a las que se les deniega el permiso.
*   **Permisos Denegados (Denied Permissions):** La lista de permisos exactos que se están denegando.
*   **Excepciones (Exception Permissions):** Opcionalmente, permisos que están exentos de la regla de denegación.
*   **Condición de Denegación (Denial Condition):** Opcionalmente, una expresión CEL que debe evaluarse como verdadera para que la denegación se aplique.

### 🔹 Puntos de Vinculación (Attachment Points)

Las políticas de denegación solo se pueden adjuntar a nivel de **proyecto, carpeta u organización**.

---

## ⚠️ **Prerrequisito Clave: Requiere Organización de GCP**

Un requisito fundamental para las Políticas de Denegación explícitas es:

**Para crear o gestionar Políticas de Denegación de IAM, el proyecto debe formar parte de una Organización de Google Cloud.**

Los proyectos independientes (standalone) no tienen acceso a esta funcionalidad. Esto se manifiesta de las siguientes maneras:
*   Los comandos de `gcloud` para gestionar políticas de denegación no estarán disponibles.
*   El rol necesario, **`Administrador de denegación` (`roles/iam.denyAdmin`)**, no estará visible ni podrá ser asignado. Este rol, que contiene el permiso `iam.googleapis.com/denypolicies.create`, solo puede ser otorgado a nivel de Organización.

---

## 🔬 Laboratorio Práctico: Mínimo Privilegio (Denegar por Defecto)

Este laboratorio funcional demuestra el **Principio de Mínimo Privilegio**. Veremos cómo una acción es denegada porque el permiso nunca fue concedido, un concepto fundamental que complementa a las políticas de denegación explícitas.

### ARRANGE (Preparación)

```bash
# 1. Variables Esenciales
export PROJECT_ID="markitos-mdk-gcp"
export USER_EMAIL="markitos.es.info@gmail.com"
export SA_NAME="min-priv-sa-lab"
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
export BUCKET_NAME="min-priv-bucket-$(date +%s)"

# 2. Crear el bucket y un objeto para lectura
gcloud storage buckets create gs://$BUCKET_NAME --project=$PROJECT_ID
gcloud storage cp - gs://$BUCKET_NAME/allow_file.txt << EOF
Acceso de Lectura Permitido
EOF
```

### ACT (Implementación del Mínimo Privilegio)

```bash
# 1. Crear la Service Account
gcloud iam service-accounts create $SA_NAME --display-name="Min Privilege Lab SA"

# 2. Asignar el rol de MÍNIMO PRIVILEGIO (Solo Lectura de Objetos)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

# 3. Permitir la Impersonación a tu usuario
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --member="user:$USER_EMAIL" \
  --role="roles/iam.serviceAccountTokenCreator"
```

### ASSERT (Verificación del Mínimo Privilegio)

```bash
# 1. PRUEBA DE LECTURA (ALLOW) - DEBE SER EXITOSO ✅
echo "Probando que la SA puede LEER (Permiso concedido)..''
gcloud storage cat gs://$BUCKET_NAME/allow_file.txt \
  --impersonate-service-account=$SA_EMAIL

# 2. PRUEBA DE ESCRITURA (DENY POR OMISIÓN) - DEBE FALLAR 🚫
echo "Probando que la SA NO puede ESCRIBIR (Permiso omitido/denegado)..''
gcloud storage cp - gs://$BUCKET_NAME/deny_file.txt \
  --impersonate-service-account=$SA_EMAIL << EOF
Este contenido debería ser denegado
EOF
# SALIDA ESPERADA: Un error de "Permission denied". ¡Esto confirma el Mínimo Privilele!
```

### CLEANUP (Limpieza)

```bash
gcloud storage rm -r gs://$BUCKET_NAME --quiet
gcloud iam service-accounts delete $SA_EMAIL --quiet
```

---

## 💡 Lecciones Aprendidas

*   **Denegar por Defecto:** El modelo de seguridad de GCP es denegar todo acceso que no esté explícitamente permitido. El laboratorio lo demuestra.
*   **Denegación Explícita (IAM Deny):** Es una capa de seguridad adicional para establecer límites firmes que no se pueden sobrepasar, pero requiere una Organización de GCP.
*   **Centraliza la Gobernanza:** Las políticas de denegación explícitas son ideales para que un equipo de seguridad central establezca reglas para toda una organización.

---

## ⚠️ Errores y Confusiones Comunes

*   **Confundir Denegación por Defecto con Denegación Explícita:** No tener un permiso no es lo mismo que tener un permiso denegado por una política de IAM Deny. El laboratorio muestra el primer caso.
*   **Adjuntar Deny Policies al Recurso Incorrecto:** Recordar que solo se pueden adjuntar a nivel de organización, carpeta o proyecto.
*   **Pensar que Deny Policies no soportan condiciones:** Las versiones modernas de IAM Deny **sí soportan** condiciones para aplicar la denegación de forma más granular.

---

## 🎯 Tips de Examen

*   **Denegar Anula Conceder (Deny wins):** El concepto más importante de las políticas de denegación explícitas.
*   **Mínimo Privilegio:** Concede solo los permisos necesarios. Si un permiso no está concedido, está denegado por defecto.
*   **Puntos de Vinculación de Deny Policies:** Organización, carpeta o proyecto.
*   **Requisito de Organización para Deny Policies:** Entiende que no están disponibles para proyectos independientes.

---

## 🧾 Resumen

IAM en GCP utiliza un enfoque de seguridad en capas. El **Mínimo Privilegio** (denegar por defecto) es la base. Las **Políticas de Denegación (IAM Deny)** son una herramienta de seguridad avanzada, superpuesta, que proporciona un control negativo explícito. Actúan como una red de seguridad infalible, pero su uso requiere que los proyectos estén gestionados dentro de una **Organización de GCP**.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**
*The Artisan Path*
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-políticas-de-denegación-de-iam-y-mínimo-privilegio)