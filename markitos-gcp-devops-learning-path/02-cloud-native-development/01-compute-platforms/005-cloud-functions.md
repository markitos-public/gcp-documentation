# 🚀 Cloud Functions (Serverless FaaS)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-cloud-functions-serverless-faas)

---

## 🧭 Descripción

Cloud Functions es la plataforma de Funciones como Servicio (FaaS) de Google Cloud. Es una solución de cómputo serverless y basada en eventos que te permite ejecutar pequeños fragmentos de código (funciones) en respuesta a eventos de la nube, sin tener que gestionar servidores ni entornos de ejecución. Es la herramienta perfecta para crear lógica reactiva, procesar datos en tiempo real o actuar como "pegamento" entre diferentes servicios de GCP.

---

## 📘 Detalles

### Disparadores (Triggers)

Una función siempre se ejecuta en respuesta a un disparador. Los principales tipos de disparadores son:

1.  **HTTP:** La función se ejecuta cuando recibe una petición HTTP a su URL única. Es ideal para webhooks o APIs muy simples.

2.  **Event-driven (Basados en eventos):** La función se ejecuta en respuesta a un evento que ocurre en otro servicio de GCP. Los más comunes son:
    *   **Cloud Storage:** Se dispara cuando un objeto es creado, borrado o actualizado en un bucket.
    *   **Cloud Pub/Sub:** Se dispara cuando se publica un mensaje en un tema de Pub/Sub.
    *   **Firestore/Firebase:** Se dispara cuando los datos cambian en la base de datos.
    *   **Cloud Scheduler:** Permite invocar una función en un horario recurrente (como un cron job).

### Generaciones de Cloud Functions

Existen dos generaciones con características diferentes:

*   **1st Gen (1ª Generación):** La versión original. Más simple, pero con limitaciones como un tiempo máximo de ejecución de 9 minutos.
*   **2nd Gen (2ª Generación):** La versión moderna, construida sobre Cloud Run y Eventarc. Ofrece un rendimiento mejorado, tiempos de ejecución más largos (hasta 60 minutos), y puede manejar múltiples eventos por función.

### Características Clave

*   **Sin Servidores:** No hay que aprovisionar, parchear ni gestionar servidores.
*   **Pago por Invocación:** Solo pagas cuando tu función se está ejecutando. Si no hay eventos, no hay costo.
*   **Escalado Automático:** Google escala automáticamente el número de instancias de tu función para manejar el volumen de eventos entrantes.
*   **Entornos de Ejecución Gestionados:** Soporta lenguajes populares como Node.js, Python, Go, Java, etc. Tú solo proporcionas el código fuente.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear una Función que se Dispara con la Subida de un Fichero
**Contexto:** Crearemos una función de 2ª generación que se activa cada vez que se sube un nuevo fichero a un bucket de Cloud Storage. La función simplemente registrará en los logs el nombre del fichero procesado.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable run.googleapis.com functions.googleapis.com storage.googleapis.com eventarc.googleapis.com logging.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export BUCKET_NAME="trigger-bucket-$PROJECT_ID"
export FUNCTION_NAME="gcs-event-handler"

# Crear el bucket que actuará como disparador
gsutil mb -l $REGION gs://$BUCKET_NAME

# Crear el código fuente de la función
mkdir function_source_gcs
cat <<EOT > function_source_gcs/main.py
import functions_framework
import base64

# El decorador @functions_framework.cloud_event se suscribe a eventos
@functions_framework.cloud_event
def handle_gcs_event(cloud_event):
    # Los datos del evento vienen codificados en base64
    data = cloud_event.data
    name = data["name"]
    bucket = data["bucket"]
    print(f"¡Nuevo fichero detectado! Nombre: {name}, Bucket: {bucket}")
EOT
```

#### ACT (Implementación del escenario)
*Desplegamos la función especificando que su disparador (`--trigger-event-filters`) es la creación de objetos en nuestro bucket.*
```bash
# Desplegar la función de 2ª generación
gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=python310 \
    --region=$REGION \
    --source=./function_source_gcs \
    --entry-point=handle_gcs_event \
    --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
    --trigger-event-filters="bucket=$BUCKET_NAME"
```

#### ASSERT (Verificación de funcionalidades)
*Subimos un fichero al bucket y luego comprobamos los logs para ver si la función se ha ejecutado y ha impreso el mensaje.*
```bash
# 1. Subir un fichero de prueba al bucket para disparar la función
echo "hello world" > test.txt
gsutil cp test.txt gs://$BUCKET_NAME/

# 2. Esperar unos segundos y luego comprobar los logs
echo "\n=== Esperando a que la función se ejecute... Comprobando logs: ==="
sleep 15
gcloud functions logs read $FUNCTION_NAME --region=$REGION --limit=10 | grep "¡Nuevo fichero detectado!"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la función, el bucket y los ficheros locales
gcloud functions delete $FUNCTION_NAME --region=$REGION --quiet
gsutil rm -r gs://$BUCKET_NAME
rm -rf function_source_gcs
rm test.txt
```

---

## 💡 Lecciones Aprendidas

*   **Piensa en Eventos:** Cloud Functions brilla cuando piensas en términos de "si ocurre ESTO, entonces haz AQUELLO".
*   **Funciones Pequeñas y Enfocadas:** Una función debe hacer una sola cosa y hacerla bien. Evita crear funciones monolíticas complejas.
*   **Idempotencia:** Diseña tus funciones para que, si reciben el mismo evento dos veces, el resultado final sea el mismo. Los sistemas de eventos pueden, en raras ocasiones, entregar un evento más de una vez.

---

## ⚠️ Errores y Confusiones Comunes

*   **Usar Cloud Functions para procesos de larga duración:** La 1ª Gen tiene un límite de 9 minutos. La 2ª Gen (hasta 60 min) es mejor, pero para tareas muy largas (horas), es preferible usar Cloud Run Jobs o un workflow orquestado.
*   **No gestionar las dependencias:** Tu código puede tener dependencias (librerías). Debes declararlas en un fichero como `requirements.txt` (Python) o `package.json` (Node.js) para que se instalen durante el despliegue.
*   **Ignorar los "cold starts":** Al igual que Cloud Run, las funciones que no se han invocado en un tiempo pueden experimentar una latencia inicial (arranque en frío) mientras se aprovisiona una instancia para ejecutarla.

---

## 🎯 Tips de Examen

*   **Evento -> Función:** Si el escenario describe una acción que debe ocurrir en respuesta a un evento de GCP (subir fichero, mensaje en cola, cambio en BD), la respuesta es casi siempre Cloud Functions.
*   **Diferencia entre 1ª y 2ª Gen:** La 2ª Gen está construida sobre Cloud Run, lo que le da mayor rendimiento y tiempos de ejecución más largos.
*   **Disparador HTTP vs. Evento:** Un disparador HTTP es para invocar la función directamente a través de una URL. Un disparador de evento es para reaccionar a sucesos en otros servicios de GCP.

---

## 🧾 Resumen

Cloud Functions es la navaja suiza del cómputo serverless en GCP. Te permite ejecutar código de forma económica y escalable en respuesta a una gran variedad de eventos, sin preocuparte en absoluto por la infraestructura subyacente. Es la herramienta ideal para automatizar tareas, procesar datos en tiempo real y conectar servicios para construir arquitecturas reactivas y eficientes.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-functions-serverless-faas)
