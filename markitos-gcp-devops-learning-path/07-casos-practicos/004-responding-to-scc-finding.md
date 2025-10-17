# ☁️ Caso Práctico: Respuesta a Hallazgo de API Key Expuesta en SCC

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🚨 Proceso de Respuesta a Incidentes (IR)](#-proceso-de-respuesta-a-incidentes-ir)
* [🔬 Laboratorio Práctico (Simulación y Remediación)](#-laboratorio-práctico-simulación-y-remediación)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Security Command Center (SCC) genera un hallazgo de severidad `CRITICAL` con la categoría `API_KEY_EXPOSED`. El hallazgo indica que una clave de API de Google Cloud ha sido detectada en un repositorio público de GitHub. Esto representa un riesgo de seguridad inminente, ya que un actor malicioso podría usar esa clave para autenticarse en las APIs de GCP y acceder o modificar recursos, generando costos inesperados o una brecha de datos.

**Objetivo:** Seguir un plan de respuesta a incidentes para contener la amenaza, remediar el problema y establecer medidas preventivas para que no vuelva a ocurrir.

---

## 🚨 Proceso de Respuesta a Incidentes (IR)

Se sigue el ciclo estándar de respuesta a incidentes: Identificación, Contención, Erradicación y Recuperación, seguido de Lecciones Aprendidas (Post-mortem).

1.  **Identificación (Ya realizada por SCC):** SCC ha identificado el problema. El primer paso es analizar el hallazgo en la consola de SCC para obtener toda la información posible:
    *   **Activo afectado:** ¿Qué clave de API específica está expuesta?
    *   **Fuente:** ¿Dónde fue encontrada? (ej. URL de GitHub).
    *   **Permisos de la clave:** ¿Qué APIs puede usar esta clave? ¿Tiene alguna restricción (por IP, por API)? Esto es crucial para evaluar el impacto potencial.

2.  **Contención (Paso más urgente):** El objetivo es detener el posible abuso de la clave lo más rápido posible. La mejor manera de hacerlo es **deshabilitar o regenerar la clave de API**.
    *   **NO la elimines inmediatamente.** Deshabilitarla permite investigar su uso reciente. Si la eliminas, pierdes la capacidad de auditarla.
    *   Navega a `APIs y Servicios > Credenciales` en la consola de GCP.
    *   Localiza la clave expuesta y edítala. Puedes añadir una restricción de IP (ej. a `127.0.0.1`) como medida de contención inmediata o, preferiblemente, regenerar el valor de la clave. La regeneración invalida el valor antiguo expuesto.

3.  **Análisis y Erradicación:**
    *   **Auditar el uso de la clave:** Usa el Explorador de Métricas o los Logs de Auditoría para ver si la clave ha sido utilizada desde IPs sospechosas. Filtra por el `credential_id` de la clave expuesta.
        ```bash
        # Ejemplo de filtro en Cloud Logging
        protoPayload.authenticationInfo.principalEmail: "service-<project_number>@api-key-redacted.iam.gserviceaccount.com"
        AND protoPayload.requestMetadata.callerIp != "IPs_CONOCIDAS"
        ```
    *   **Eliminar el secreto del repositorio público:** Ve a la URL de GitHub proporcionada por SCC y elimina el archivo que contiene la clave. Si está en el historial de commits, se debe purgar el historial, lo cual es un proceso complejo. La forma más segura es asumir que la clave está permanentemente comprometida.
    *   **Identificar la causa raíz:** ¿Cómo llegó la clave a GitHub? Revisa los commits recientes. Generalmente, es un desarrollador que ha hardcodeado la clave en el código por error.

4.  **Recuperación y Post-mortem:**
    *   Una vez que la clave ha sido rotada y se ha verificado que no hay actividad maliciosa, se puede cerrar el incidente.
    *   **Lecciones Aprendidas:** Realiza una reunión post-mortem para discutir por qué ocurrió el incidente y cómo prevenirlo en el futuro.

---

## 🔬 Laboratorio Práctico (Simulación y Remediación)

Este laboratorio simula la detección y respuesta a una clave expuesta.

### ARRANGE (Preparación del Problema)

```bash
# 1. Variables
export PROJECT_ID=$(gcloud config get-value project)

# 2. Habilitar APIs
gcloud services enable apikeys.googleapis.com securitycenter.googleapis.com

# 3. Crear una clave de API sin restricciones (¡NO HACER EN PRODUCCIÓN!)
export KEY_NAME="my-leaked-api-key"
gcloud alpha services api-keys create --display-name=$KEY_NAME --project=$PROJECT_ID
export LEAKED_KEY_STRING=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# 4. Simular la fuga (NO lo subas a un GitHub público real)
# Creamos un archivo local que simula el código comprometido.
echo "API_KEY = \"${LEAKED_KEY_STRING}\"" > config.py

# 5. Simular el hallazgo de SCC
# En un escenario real, SCC lo detectaría automáticamente si se sube a GitHub.
# Aquí, crearemos un hallazgo manualmente para simular la alerta.
# (Este paso es complejo y solo para demostración, nos enfocaremos en la respuesta)
```

### ACT (Respuesta al Incidente)

*Asumimos que SCC nos ha alertado sobre la clave `$KEY_NAME`.*

```bash
# 1. Identificar la clave y sus permisos (usando gcloud)
gcloud alpha services api-keys list --filter="displayName=$KEY_NAME"
# Esto nos mostrará si tiene restricciones o no.

# 2. CONTENCIÓN: Rotar la clave. Esto invalida el valor antiguo.
# La rotación se hace regenerando la clave. El nombre y el ID no cambian.
gcloud alpha services api-keys update $KEY_NAME --regenerate-key

# 3. Opcional: Verificar que la clave ha cambiado
export NEW_KEY_STRING=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
if [ "$LEAKED_KEY_STRING" != "$NEW_KEY_STRING" ]; then
    echo "Éxito: La clave ha sido rotada."
fi
```

### ASSERT (Verificación y Prevención)

```bash
# 1. ERRADICACIÓN: Eliminar el archivo local que contiene la clave
rm config.py

# 2. PREVENCIÓN: Implementar buenas prácticas
# La solución correcta es usar Secret Manager.

# a. Almacenar el nuevo valor de la clave en Secret Manager
export SECRET_ID="production-api-key"
gcloud secrets create $SECRET_ID --replication-policy=automatic
echo -n $NEW_KEY_STRING | gcloud secrets versions add $SECRET_ID --data-file=-

# b. Modificar la aplicación para que lea la clave desde Secret Manager
# (Esto sería un cambio en el código de la aplicación)
# Ejemplo conceptual en Python:
# from google.cloud import secretmanager
# client = secretmanager.SecretManagerServiceClient()
# name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
# response = client.access_secret_version(name=name)
# api_key = response.payload.data.decode("UTF-8")

# 3. PREVENCIÓN: Añadir restricciones a la clave de API
# Restringir la clave para que solo pueda ser usada desde ciertas IPs o para ciertas APIs.
gcloud alpha services api-keys update $KEY_NAME --add-restriction=api-targets=storage.googleapis.com
```

### CLEANUP (Limpieza)

```bash
# Eliminar la clave de API
gcloud alpha services api-keys delete $KEY_NAME

# Eliminar el secreto de Secret Manager
gcloud secrets delete $SECRET_ID --quiet
```

---

## 💡 Lecciones Aprendidas

*   **La Velocidad de Contención es Crítica:** El tiempo que transcurre entre la exposición y la invalidación de la clave es la ventana de oportunidad para un atacante. La rotación o desactivación de la clave debe ser el primer reflejo.
*   **La Prevención es Mejor que la Cura:** El incidente nunca habría ocurrido si la clave no se hubiera hardcodeado. El uso de herramientas como **Secret Manager** y la educación a los desarrolladores son las defensas más efectivas.
*   **Usa Scanners de Pre-commit:** Implementa herramientas como `gitleaks` o `truffleHog` en hooks de pre-commit o en el pipeline de CI para detectar secretos *antes* de que lleguen a un repositorio remoto.
*   **Principio de Mínimo Privilegio para Claves de API:** Nunca crees claves sin restricciones. Siempre restríngelas por IP, por tipo de aplicación (Android/iOS) o por API. Esto limita enormemente el daño que una clave expuesta puede causar.

---

## 🧾 Resumen

Responder a una clave de API expuesta es un sprint de seguridad. El proceso implica una contención inmediata (rotar/deshabilitar la clave), seguida de una investigación para auditar su uso y erradicar la fuente de la fuga. Sin embargo, la lección más importante es la prevención: utilizar Secret Manager para gestionar credenciales y aplicar restricciones de mínimo privilegio en las claves de API son las estrategias fundamentales para evitar que este tipo de incidentes ocurran en primer lugar.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-respuesta-a-hallazgo-de-api-key-expuesta-en-scc)
