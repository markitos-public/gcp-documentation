# ☁️ Mejores Prácticas de IAM (IAM Best Practices)

## 📑 Índice

* [🧭 Descripción](#-descripción)
* [📘 Lista de Mejores Prácticas](#-lista-de-mejores-prácticas)
* [🔬 Laboratorio Práctico (Auditoría)](#-laboratorio-práctico-auditoría)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Descripción

La gestión de identidades y accesos (IAM) es la base de la seguridad en Google Cloud. Aplicar las mejores prácticas de IAM no es solo una recomendación, sino un requisito fundamental para proteger los recursos, prevenir accesos no autorizados y mantener una postura de seguridad robusta. Este capítulo resume las prácticas más importantes que deben seguirse para utilizar IAM de manera efectiva y segura, actuando como una lista de verificación para cualquier administrador o desarrollador de GCP.

---

## 📘 Lista de Mejores Prácticas

### 1. Aplicar el Principio de Mínimo Privilegio (Principle of Least Privilege)

*   **Qué es:** Conceder a cada principal (usuario, cuenta de servicio) solo los permisos estrictamente necesarios para realizar su función, y nada más.
*   **Cómo hacerlo:**
    *   **Prefiere roles predefinidos sobre los básicos:** En lugar de usar roles amplios como `Editor`, usa roles granulares como `roles/compute.instanceAdmin` o `roles/storage.objectCreator`.
    *   **Usa roles personalizados si es necesario:** Si ningún rol predefinido se ajusta, crea un rol personalizado con el conjunto exacto de permisos requeridos.

### 2. Usar Cuentas de Servicio para Aplicaciones

*   **Qué es:** Las aplicaciones y las VMs no deben autenticarse con credenciales de usuario. Deben usar cuentas de servicio, que son identidades diseñadas para cargas de trabajo de máquina a máquina.
*   **Cómo hacerlo:**
    *   **Una cuenta de servicio por aplicación:** Crea una cuenta de servicio dedicada para cada aplicación o microservicio. Esto permite concederle permisos específicos y auditar su actividad de forma aislada.
    *   **Evita la cuenta de servicio por defecto de Compute Engine:** Esta cuenta tiene el rol de `Editor` por defecto, lo cual es demasiado permisivo. Siempre crea y asigna una cuenta de servicio específica a tus VMs.

### 3. Gestionar el Acceso a Nivel de Grupo

*   **Qué es:** En lugar de asignar roles a usuarios individuales, asígnalos a Grupos de Google (`security-auditors@miempresa.com`). La gestión de la membresía del grupo se realiza en Google Workspace, no en IAM.
*   **Cómo hacerlo:**
    *   Crea grupos basados en roles o funciones (ej. `gcp-network-admins`, `gcp-billing-viewers`).
    *   Asigna los roles de IAM a estos grupos.
    *   Para conceder o revocar permisos a un usuario, simplemente añádelo o elimínalo del grupo correspondiente. Esto simplifica enormemente la administración.

### 4. Utilizar la Jerarquía de Recursos para Heredar Políticas

*   **Qué es:** Las políticas de IAM se heredan de arriba hacia abajo en la jerarquía de recursos (Organización -> Carpetas -> Proyectos -> Recursos).
*   **Cómo hacerlo:**
    *   **Asigna roles en el nivel más alto posible:** Si un grupo de auditores necesita ver todos los proyectos, asígnales el rol `Viewer` a nivel de Organización, en lugar de repetirlo en cada proyecto.
    *   **Usa proyectos para aislar entornos:** Separa los entornos de desarrollo, pruebas y producción en proyectos diferentes, cada uno con sus propias políticas de IAM.

### 5. Auditar Regularmente las Políticas de IAM

*   **Qué es:** Revisar periódicamente quién tiene acceso a qué para identificar y eliminar permisos innecesarios.
*   **Cómo hacerlo:**
    *   **Usa el Analizador de Políticas (Policy Analyzer):** Una herramienta de IAM que te ayuda a responder preguntas como "¿Quién tiene permiso para eliminar este bucket?" o "¿Qué permisos tiene esta cuenta de servicio sobre este proyecto?".
    *   **Revisa los Logs de Auditoría de IAM:** Monitoriza los eventos de `SetIamPolicy` para saber cuándo y quién está cambiando las políticas de IAM.
    *   **Usa Recomendaciones de IAM (IAM Recommender):** Este servicio analiza el uso de permisos y sugiere automáticamente la eliminación de roles o permisos que no se han utilizado en los últimos 90 días.

### 6. Proteger las Cuentas de Servicio

*   **Qué es:** Las cuentas de servicio son un objetivo de alto valor para los atacantes. Es crucial limitar su poder y proteger sus credenciales.
*   **Cómo hacerlo:**
    *   **No exportes claves de cuenta de servicio:** Evita crear y descargar archivos JSON con las claves. Es una mala práctica de seguridad. En su lugar, usa la suplantación de identidad de cuentas de servicio o la federación de identidades de carga de trabajo.
    *   **Rota las claves regularmente:** Si es absolutamente necesario usar claves, rótalas periódicamente.

---

## 🔬 Laboratorio Práctico (Auditoría)

**Escenario:** Usaremos las herramientas de IAM para auditar y mejorar la seguridad de un proyecto. Identificaremos un permiso excesivo y usaremos el Recomendador de IAM para obtener una sugerencia de mejora.

### ARRANGE (Preparación)

```bash
# 1. Variables
export PROJECT_ID=$(gcloud config get-value project)
export SA_NAME="overprivileged-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 2. Habilitar la API del Recomendador
gcloud services enable recommender.googleapis.com

# 3. Crear una cuenta de servicio con un rol demasiado permisivo (Editor)
gcloud iam service-accounts create $SA_NAME
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/editor"

# 4. Usar la cuenta de servicio para una acción simple (para generar datos de uso)
# Le damos permiso para actuar como sí misma (necesario para impersonate)
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

# Usamos la SA solo para listar buckets, aunque tiene permisos de Editor
gsutil ls --impersonate-service-account=$SA_EMAIL
```

### ACT (Auditoría y Análisis)

*El Recomendador de IAM puede tardar hasta 24 horas en generar una recomendación después de que se crea una nueva asignación. Los siguientes comandos muestran cómo se consultaría una vez que los datos se han procesado.*

```bash
# 1. Usar el Analizador de Políticas para ver qué puede hacer la SA
# gcloud asset analyze-iam-policy: Analiza quién tiene qué acceso a qué recurso.
# --project: (Requerido) El proyecto donde se realiza el análisis.
# --full-resource-name: (Requerido) El recurso sobre el que preguntamos.
# --identity: (Requerido) El principal sobre el que preguntamos.
# --permissions: (Requerido) El permiso que queremos verificar.
# Preguntamos: ¿Puede esta SA eliminar buckets de storage?
gcloud asset analyze-iam-policy --project=$PROJECT_ID \
    --full-resource-name="//storage.googleapis.com/projects/_" \
    --identity="serviceAccount:${SA_EMAIL}" \
    --permissions="storage.buckets.delete"
# SALIDA ESPERADA: Indicará que el permiso está concedido a través del rol de Editor.

# 2. Listar las recomendaciones de IAM para la cuenta de servicio
# (NOTA: Esto puede no devolver nada inmediatamente. Se necesita tiempo para el análisis)
# gcloud recommender recommendations list: Lista las sugerencias de mejora.
# --recommender: (Requerido) El tipo de recomendador a consultar (en este caso, de políticas de IAM).
# --filter: (Opcional) Filtra para encontrar recomendaciones para un recurso o principal específico.
gcloud recommender recommendations list \
    --project=$PROJECT_ID \
    --recommender=google.iam.policy.Recommender \
    --filter="targetResources:compute.googleapis.com AND targetResources:${SA_EMAIL}"
```

### ASSERT (Remediación)

*Asumimos que el Recomendador ha sugerido cambiar el rol `Editor` por `Storage Object Viewer` porque es el único permiso que se ha usado.*

```bash
# 1. Aplicar la recomendación (remediación manual)
# Primero, quitamos el rol excesivo
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/editor"

# Segundo, añadimos el rol de mínimo privilegio
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.objectViewer"

# 2. Verificar que la SA ya no puede realizar acciones de escritura
# Este comando ahora debería fallar
gsutil mb gs://test-bucket-delete-me-${PROJECT_ID} --impersonate-service-account=$SA_EMAIL || echo "Fallo esperado: Permiso denegado."
```

### CLEANUP (Limpieza)

```bash
# Eliminar la cuenta de servicio y sus asignaciones
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.objectViewer"
gcloud iam service-accounts delete $SA_EMAIL --quiet
```

---

## 💡 Lecciones Aprendidas

*   **La Seguridad en la Nube es un Proceso Continuo:** No es suficiente configurar IAM una vez. El uso de los recursos cambia, y las políticas deben ser auditadas y ajustadas regularmente.
*   **Aprovecha las Herramientas Automatizadas:** Servicios como el Recomendador de IAM son increíblemente valiosos. Automatizan la tediosa tarea de analizar logs de uso para encontrar permisos excesivos, algo que es casi imposible de hacer manualmente a escala.
*   **La Jerarquía es tu Aliada para la Organización:** Una buena estructura de carpetas y proyectos es la base para una estrategia de IAM limpia y manejable.

---

## 🧾 Resumen

Las mejores prácticas de IAM giran en torno al principio de mínimo privilegio y la auditoría continua. Al preferir roles predefinidos y personalizados sobre los básicos, gestionar usuarios a través de grupos, utilizar cuentas de servicio dedicadas para las aplicaciones y auditar regularmente los permisos con herramientas como el Recomendador de IAM, se puede reducir drásticamente la superficie de ataque y construir un entorno de Google Cloud seguro, gobernado y fácil de administrar.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-mejores-prácticas-de-iam-iam-best-practices)
