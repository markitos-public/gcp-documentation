# ☁️ Caso Práctico: Pipeline Automatizado de Rotación de Secretos

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🏛️ Arquitectura de la Solución](#️-arquitectura-de-la-solución)
* [🔬 Laboratorio Práctico (Implementación)](#-laboratorio-práctico-implementación)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Una aplicación crítica se conecta a una base de datos Cloud SQL usando un usuario y una contraseña. Por política de seguridad, esta contraseña debe ser rotada (cambiada) cada 30 días. Realizar este proceso manualmente es propenso a errores, requiere tiempo y puede causar interrupciones en el servicio si no se coordina perfectamente.

**Objetivo:** Diseñar e implementar un pipeline automatizado y sin interrupciones (zero-downtime) que rote la contraseña de la base de datos, la actualice en Secret Manager y garantice que la aplicación siempre use la credencial más reciente.

---

## 🏛️ Arquitectura de la Solución

La solución integra varios servicios de GCP para crear un flujo de eventos automatizado:

1.  **Cloud Scheduler:** Actúa como el disparador (`trigger`). Se configura un trabajo (cron job) para que se ejecute cada 30 días. Este trabajo enviará un mensaje a un tópico de Pub/Sub.

2.  **Pub/Sub:** Sirve como el bus de mensajería que desacopla el disparador de la lógica de acción. Recibe el mensaje de Cloud Scheduler y lo reenvía a su suscriptor.

3.  **Cloud Functions:** Es el cerebro de la operación. Una Cloud Function se suscribe al tópico de Pub/Sub. Cuando recibe un mensaje, ejecuta el código de rotación:
    a.  **Genera una nueva contraseña segura.**
    b.  **Se conecta a la instancia de Cloud SQL** usando el usuario administrador de la base de datos (cuya contraseña también está en Secret Manager).
    c.  **Ejecuta un comando SQL** para cambiar la contraseña del usuario de la aplicación (ej. `ALTER USER app_user IDENTIFIED BY 'new_password';`).
    d.  **Añade la nueva contraseña como una nueva versión** al secreto correspondiente en Secret Manager.

4.  **Secret Manager:** Almacena de forma segura la contraseña del usuario de la aplicación. La aplicación está configurada para solicitar siempre la versión `latest` de este secreto.

5.  **Aplicación (ej. en GKE o Cloud Run):** La aplicación está diseñada para ser resiliente. En su código de inicio, o periódicamente, solicita la versión `latest` del secreto. Si la conexión a la base de datos falla, reintenta obtener la credencial de Secret Manager antes de volver a conectarse. Esto asegura que, poco después de la rotación, la aplicación recogerá la nueva contraseña automáticamente.

![Arquitectura de Rotación de Secretos](https://storage.googleapis.com/gcp-devops-kulture-images/secret-rotation-architecture.png) *(Nota: Esta es una URL de imagen conceptual)*

---

## 🔬 Laboratorio Práctico (Implementación)

Este laboratorio describe los pasos para construir la arquitectura. Se enfoca en la creación de los componentes y el código de la Cloud Function.

### ARRANGE (Preparación)

```bash
# 1. Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export DB_INSTANCE_NAME="app-db-instance"
export DB_USER="app_user"
export ADMIN_SECRET_ID="db-admin-password"
export APP_SECRET_ID="db-app-password"
export TOPIC_ID="secret-rotation-topic"
export FUNCTION_NAME="rotate-db-password-fn"

# 2. Habilitar APIs
gcloud services enable \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    pubsub.googleapis.com \
    cloudfunctions.googleapis.com \
    cloudscheduler.googleapis.com \
    cloudbuild.googleapis.com

# 3. Crear instancia de Cloud SQL (ej. PostgreSQL) y un usuario
# (Este paso puede tardar varios minutos)
gcloud sql instances create $DB_INSTANCE_NAME --database-version=POSTGRES_13 --region=$REGION --root-password="ADMIN_INITIAL_PASSWORD"
gcloud sql users create $DB_USER --instance=$DB_INSTANCE_NAME --password="APP_INITIAL_PASSWORD"

# 4. Almacenar las contraseñas iniciales en Secret Manager
echo -n "ADMIN_INITIAL_PASSWORD" | gcloud secrets create $ADMIN_SECRET_ID --replication-policy=automatic --data-file=-
echo -n "APP_INITIAL_PASSWORD" | gcloud secrets create $APP_SECRET_ID --replication-policy=automatic --data-file=-

# 5. Crear el tópico de Pub/Sub
gcloud pubsub topics create $TOPIC_ID

# 6. Crear una cuenta de servicio para la Cloud Function
export FUNCTION_SA="cf-rotator-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts create cf-rotator-sa --display-name="Cloud Function Secret Rotator SA"

# 7. Asignar permisos a la cuenta de servicio
# Necesita acceder a Secret Manager y conectarse a Cloud SQL
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${FUNCTION_SA}" \
    --role="roles/secretmanager.secretAccessor" # Para leer la pass de admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${FUNCTION_SA}" \
    --role="roles/secretmanager.secretVersionAdder" # Para añadir nueva pass de app
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${FUNCTION_SA}" \
    --role="roles/cloudsql.client" # Para conectarse a la BD
```

### ACT (Implementación de la Cloud Function)

```bash
# 1. Crear el directorio para el código de la función
mkdir rotator_function && cd rotator_function

# 2. Crear el archivo de dependencias (requirements.txt)
cat > requirements.txt <<EOF
google-cloud-secret-manager
pg8000
google-cloud-sql-connector
EOF

# 3. Crear el código de la función (main.py)
# Este es un ejemplo conceptual en Python.
cat > main.py <<EOF
import os
import random
import string
from google.cloud.sql.connector import Connector
from google.cloud import secretmanager

def rotate_password(event, context):
    project_id = os.environ.get("PROJECT_ID")
    db_instance_name = os.environ.get("DB_INSTANCE_NAME")
    db_user = os.environ.get("DB_USER")
    admin_secret_id = os.environ.get("ADMIN_SECRET_ID")
    app_secret_id = os.environ.get("APP_SECRET_ID")

    # 1. Generar nueva contraseña
    new_password = ''.join(random.choices(string.ascii_letters + string.digits, k=32))

    # 2. Obtener contraseña de admin desde Secret Manager
    sm_client = secretmanager.SecretManagerServiceClient()
    admin_secret_name = f"projects/{project_id}/secrets/{admin_secret_id}/versions/latest"
    response = sm_client.access_secret_version(name=admin_secret_name)
    admin_password = response.payload.data.decode("UTF-8")

    # 3. Conectarse a la BD y cambiar la contraseña del usuario de la app
    connector = Connector()
    conn = connector.connect(
        f"{project_id}:{os.environ.get('REGION')}:{db_instance_name}",
        "pg8000",
        user="postgres", # Usuario admin de postgres
        password=admin_password,
        db="postgres"
    )
    cursor = conn.cursor()
    cursor.execute(f"ALTER USER {db_user} WITH PASSWORD '{new_password}';")
    conn.commit()
    conn.close()
    connector.close()

    # 4. Añadir la nueva contraseña como nueva versión en Secret Manager
    app_secret_parent = f"projects/{project_id}/secrets/{app_secret_id}"
    sm_client.add_secret_version(
        parent=app_secret_parent,
        payload={'data': new_password.encode("UTF-8")}
    )

    print(f"Successfully rotated password for user {db_user}")
EOF

# 4. Desplegar la Cloud Function
gcloud functions deploy $FUNCTION_NAME \
    --runtime python39 \
    --trigger-topic $TOPIC_ID \
    --entry-point rotate_password \
    --service-account $FUNCTION_SA \
    --region $REGION \
    --set-env-vars PROJECT_ID=$PROJECT_ID,REGION=$REGION,DB_INSTANCE_NAME=$DB_INSTANCE_NAME,DB_USER=$DB_USER,ADMIN_SECRET_ID=$ADMIN_SECRET_ID,APP_SECRET_ID=$APP_SECRET_ID

cd ..
```

### ASSERT (Disparo y Verificación)

```bash
# 1. Disparar la función manualmente publicando un mensaje en Pub/Sub
gcloud pubsub topics publish $TOPIC_ID --message="Rotate now!"

# 2. Verificar los logs de la Cloud Function para confirmar la ejecución
sleep 30 # Dar tiempo a la función para ejecutarse
gcloud functions logs read $FUNCTION_NAME --region $REGION --limit=10 | grep "Successfully rotated"
# SALIDA ESPERADA: Debería mostrar el mensaje de éxito.

# 3. Verificar que se ha creado una nueva versión del secreto de la aplicación
gcloud secrets versions list $APP_SECRET_ID
# SALIDA ESPERADA: Debería mostrar la versión 1 (inicial) y la versión 2 (rotada).

# 4. (Opcional) Conectarse a la BD con la nueva contraseña para confirmar
export NEW_PASSWORD=$(gcloud secrets versions access latest --secret=$APP_SECRET_ID)
# (Aquí irían los pasos para conectarse a la BD con psql y la nueva contraseña)
```

### CLEANUP (Limpieza)

```bash
# Eliminar la Cloud Function, Pub/Sub, Secretos y la instancia de Cloud SQL
gcloud functions delete $FUNCTION_NAME --region $REGION --quiet
gcloud pubsub topics delete $TOPIC_ID --quiet
gcloud secrets delete $ADMIN_SECRET_ID --quiet
gcloud secrets delete $APP_SECRET_ID --quiet
gcloud sql instances delete $DB_INSTANCE_NAME --quiet
rm -rf rotator_function
# ... (y el resto de la limpieza)
```

---

## 💡 Lecciones Aprendidas

*   **La Automatización Robusta se Basa en el Desacoplamiento:** El uso de Pub/Sub entre el scheduler y la función es clave. Si la función falla, el mensaje puede ser reintentado, y permite que múltiples sistemas reaccionen al mismo evento de rotación si fuera necesario.
*   **El Poder de la Versión `latest`:** La aplicación no necesita saber nada sobre la rotación. Su contrato es simple: "dame siempre la última contraseña". Esto desacopla completamente la lógica de la aplicación de la gestión del ciclo de vida de las credenciales.
*   **Seguridad en Capas:** La cuenta de servicio de la función necesita permisos muy específicos en IAM. Un atacante que comprometiera la función solo podría hacer lo que esos permisos le permiten, demostrando el poder del principio de mínimo privilegio.

---

## 🧾 Resumen

La rotación automática de secretos es un patrón de DevSecOps maduro que mejora drásticamente la postura de seguridad de una aplicación. Mediante la orquestación de servicios gestionados como Cloud Scheduler, Pub/Sub, Cloud Functions y Secret Manager, es posible crear un sistema robusto y sin intervención humana que gestiona el ciclo de vida de las credenciales, reduce el riesgo de secretos estáticos de larga duración y elimina la posibilidad de error humano en un proceso crítico.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-pipeline-automatizado-de-rotación-de-secretos)
