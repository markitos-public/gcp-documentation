# 🚀 Cloud Run (Serverless Containers)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-cloud-run-serverless-containers)

---

## 🧭 Descripción

Cloud Run es una plataforma de cómputo totalmente gestionada (serverless) que te permite ejecutar contenedores sin estado (stateless) que son invocables a través de peticiones web o eventos. Combina la simplicidad de una experiencia PaaS con la flexibilidad de los contenedores. Con Cloud Run, simplemente proporcionas tu imagen de contenedor y Google se encarga de todo lo demás: aprovisionamiento, escalado (incluso a cero) y gestión de la infraestructura. Es la opción ideal para microservicios, APIs web y aplicaciones que no necesitan un control a nivel de VM.

---

## 📘 Detalles

### Dos Sabores de Cloud Run

1.  **Cloud Run Services:** Diseñado para ejecutar código que responde a peticiones web. Cada servicio tiene un endpoint HTTPS único y estable. Escala automáticamente el número de instancias de contenedor según el tráfico, pudiendo escalar a cero si no hay peticiones, lo que optimiza enormemente los costos.

2.  **Cloud Run Jobs:** Diseñado para ejecutar código que realiza un trabajo y luego finaliza (ej. procesar un fichero, enviar emails). Un job ejecuta una o más tareas en paralelo hasta que se completan. No está pensado para servir tráfico web continuo.

### Características Clave

*   **Cualquier Lenguaje, Cualquier Librería:** Al estar basado en contenedores, puedes usar cualquier lenguaje de programación, librería o binario. Si lo puedes poner en un contenedor Docker, lo puedes ejecutar en Cloud Run.
*   **Escalado Automático Rápido:** Puede escalar de cero a miles de instancias en segundos para manejar picos de tráfico.
*   **Modelo de Pago por Uso:** Solo pagas por la CPU y la memoria que tu código consume mientras está procesando una petición, redondeado a los 100ms más cercanos. Si tu servicio escala a cero, no pagas nada.
*   **Integración con el Ecosistema de GCP:** Se integra de forma nativa con otros servicios como Cloud Build (para CI/CD), Artifact Registry (para almacenar contenedores) y Cloud Logging/Monitoring (para observabilidad).
*   **Revisiones (Revisions):** Cada vez que despliegas un cambio en un servicio, se crea una nueva "revisión" inmutable. Cloud Run te permite dividir el tráfico entre diferentes revisiones, facilitando los despliegues Canary y Blue/Green.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Desplegar un Servicio y Dividir el Tráfico entre dos Versiones
**Contexto:** Desplegaremos una primera versión de una aplicación web. Luego, desplegaremos una segunda versión con un cambio y configuraremos Cloud Run para que envíe el 90% del tráfico a la versión antigua y el 10% a la nueva (un despliegue Canary).

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable run.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export SERVICE_NAME="hello-canary-service"
```

#### ACT (Implementación del escenario)
*Desplegamos la v1.0. Luego, desplegamos la v2.0 sin enviarle tráfico todavía. Finalmente, actualizamos el servicio para dividir el tráfico.*
```bash
# 1. Desplegar la primera versión (v1.0)
echo "\n=== Desplegando v1.0... ==="
gcloud run deploy $SERVICE_NAME \
    --image="gcr.io/google-samples/hello-app:1.0" \
    --region=$REGION \
    --allow-unauthenticated

# 2. Desplegar la segunda versión (v2.0) sin enviarle tráfico
echo "\n=== Desplegando v2.0 (sin tráfico)... ==="
gcloud run deploy $SERVICE_NAME \
    --image="gcr.io/google-samples/hello-app:2.0" \
    --region=$REGION \
    --no-traffic

# 3. Actualizar el servicio para dividir el tráfico 90% a v1 y 10% a v2
# Obtenemos los nombres de las revisiones
export REV_V1=$(gcloud run revisions list --service=$SERVICE_NAME --region=$REGION --filter="~gcr.io/google-samples/hello-app:1.0" --format="value(REVISION")
export REV_V2=$(gcloud run revisions list --service=$SERVICE_NAME --region=$REGION --filter="~gcr.io/google-samples/hello-app:2.0" --format="value(REVISION")

echo "\n=== Dividiendo el tráfico (90% a $REV_V1, 10% a $REV_V2)... ==="
gcloud run services update-traffic $SERVICE_NAME \
    --region=$REGION \
    --to-revisions=$REV_V1=90,$REV_V2=10
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos la división de tráfico del servicio y accedemos a la URL para ver las dos versiones.*
```bash
# 1. Verificar la división de tráfico
echo "\n=== Verificando la configuración de tráfico... ==="
gcloud run services describe $SERVICE_NAME --region=$REGION --format="yaml(spec.traffic)"

# 2. Acceder a la URL varias veces para ver las dos respuestas
export SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
echo "\n🚀 Accede a la URL varias veces para ver las dos versiones: $SERVICE_URL"
for i in {1..10}; do curl -s $SERVICE_URL | grep "Version"; done
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el servicio de Cloud Run
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud run services delete $SERVICE_NAME --region=$REGION --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Cloud Run es para contenedores sin estado:** Tu contenedor no debe guardar estado en el sistema de ficheros local, ya que las instancias son efímeras. Usa servicios externos como Cloud Storage o bases de datos para el estado.
*   **El escalado a cero es una ventaja y una consideración:** Es fantástico para los costos, pero puede introducir "cold starts" (latencia en la primera petición) si no se configura un número mínimo de instancias.
*   **Las revisiones son tu red de seguridad:** La gestión de revisiones y la división de tráfico hacen que los despliegues sean mucho más seguros y controlados que un simple reemplazo.

---

## ⚠️ Errores y Confusiones Comunes

*   **Intentar ejecutar una base de datos en Cloud Run:** No es la herramienta adecuada. Cloud Run está diseñado para cargas de trabajo de cómputo sin estado, no para almacenamiento persistente.
*   **No configurar un mínimo de instancias para servicios sensibles a la latencia:** Si tu aplicación necesita responder siempre en milisegundos, configura `--min-instances=1` para tener siempre una instancia caliente, a costa de un pequeño aumento en el precio.
*   **Confundir el puerto del contenedor con el puerto del servicio:** Tu contenedor debe escuchar peticiones en el puerto que especifica la variable de entorno `PORT` (por defecto 8080). Cloud Run se encarga de dirigir el tráfico externo (80/443) a ese puerto.

---

## 🎯 Tips de Examen

*   **Contenedor sin estado + HTTP = Cloud Run:** Si un escenario describe una aplicación web en un contenedor que debe ser escalable y rentable, Cloud Run es casi siempre la respuesta.
*   **División de Tráfico (Traffic Splitting):** Es una característica clave. Si la pregunta menciona despliegues Canary o Blue/Green, piensa en Cloud Run.
*   **Cloud Run vs. App Engine Flexible:** Son similares (ambos ejecutan contenedores), pero Cloud Run es más moderno, escala más rápido (a cero) y tiene un modelo de pago más granular.

---

## 🧾 Resumen

Cloud Run representa el punto ideal en el espectro de cómputo serverless, ofreciendo la flexibilidad de los contenedores con la simplicidad operativa de una plataforma totalmente gestionada. Su capacidad para escalar a cero, su modelo de pago por uso y sus potentes funcionalidades de despliegue lo convierten en la opción por defecto para construir microservicios, APIs y aplicaciones web modernas en Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-run-serverless-containers)
