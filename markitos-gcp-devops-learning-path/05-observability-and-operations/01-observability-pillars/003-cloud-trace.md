# ☁️ Cloud Trace

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

Cloud Trace es el sistema de trazado distribuido de Google Cloud. Su función es recopilar datos de latencia de las aplicaciones para ayudarte a entender cómo se propaga una solicitud a través de los diferentes servicios y componentes de tu arquitectura. Es la herramienta clave para encontrar cuellos de botella de rendimiento.

En las arquitecturas de microservicios modernas, una única solicitud de un usuario puede viajar a través de docenas de servicios antes de completarse. Cloud Trace resuelve el problema de la opacidad en estos sistemas, permitiéndote visualizar todo el viaje de la solicitud, identificar qué servicio es lento y señalar la causa raíz de la latencia.

---

## 📘 Detalles

Para entender Cloud Trace, es fundamental conocer su terminología y cómo funciona la recopilación de datos.

### 🔹 Trazas, Spans y Latencia

*   **Traza (Trace):** Representa el viaje completo de una única solicitud a través del sistema. Conceptualmente, es un árbol de "spans". Cada traza tiene un ID único.
*   **Span:** Representa una única unidad de trabajo dentro de la solicitud, como una llamada RPC, una consulta a una base de datos o la ejecución de una sección de código. Cada span tiene un nombre, una hora de inicio, una hora de finalización y su propio ID. Los spans pueden anidarse para representar sub-operaciones.
*   **Latencia:** Es el tiempo total que tarda en completarse una solicitud. La magia de Cloud Trace es que desglosa esta latencia total en la suma de las latencias de cada span individual, permitiéndote ver exactamente en qué parte del proceso se está invirtiendo el tiempo.

### 🔹 Instrumentación

Para que Cloud Trace funcione, la aplicación debe ser **instrumentada**. Esto significa añadir código que genere y propague los datos de la traza (como el Trace ID) a medida que la solicitud viaja entre servicios.

*   **Instrumentación Automática:** Algunos servicios de GCP, como **App Engine Standard**, **Cloud Functions** y **Cloud Run**, tienen un nivel de instrumentación automática. Capturan las trazas para las solicitudes entrantes y salientes sin que necesites modificar tu código.
*   **Librerías de Instrumentación:** Para la mayoría de las aplicaciones (ej. en GKE o Compute Engine), necesitas usar librerías específicas para enviar los datos de traza a la API de Cloud Trace. Las más recomendadas son las basadas en estándares abiertos como **OpenTelemetry** (el estándar de facto actual) u OpenCensus.

### 🔹 Análisis e Informes

*   **Lista de Trazas (Trace List):** Es la vista principal de la consola, que muestra una lista de las trazas más recientes con su latencia total y el número de spans.
*   **Gráfico de Cascada (Waterfall Graph):** Es la herramienta de visualización más potente. Muestra los spans de una única traza en un diagrama de cascada, permitiéndote ver de forma intuitiva la secuencia de operaciones, su duración y dónde se produjeron los retrasos.
*   **Informes de Análisis (Analysis Reports):** Cloud Trace puede generar informes automáticos que analizan el rendimiento de tu aplicación, mostrando tendencias de latencia, identificando las solicitudes más lentas y permitiéndote comparar distribuciones de latencia a lo largo del tiempo.

### 🔹 Integración con Logging

Cloud Trace está profundamente integrado con Cloud Logging. Cuando una aplicación está correctamente instrumentada, los logs generados durante la ejecución de un span se etiquetan automáticamente con el ID de la traza. Esto te permite saltar directamente desde un span en el gráfico de cascada a los logs exactos que se produjeron durante esa operación, proporcionando un contexto de depuración inigualable.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** El trazado requiere instrumentación de código, por lo que un laboratorio puramente CLI es limitado. En su lugar, desplegaremos una aplicación simple en App Engine (que tiene instrumentación automática) para generar trazas y luego usaremos `gcloud` para verificar que se están recopilando.

### ARRANGE (Preparación)

```bash
# Variables del proyecto y configuración
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west"

# Habilitar APIs necesarias
echo "Habilitando APIs de App Engine y Trace..."
gcloud services enable appengine.googleapis.com trace.googleapis.com

# Crear una aplicación de App Engine (si no existe)
gcloud app create --region=$REGION

# Crear el código de una aplicación Python simple
mkdir gae-trace-demo
cd gae-trace-demo

cat > main.py <<EOF
from flask import Flask
import time
import random

app = Flask(__name__)

@app.route('/')
def hello():
    # Simular trabajo
    time.sleep(random.uniform(0.1, 0.5))
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080, debug=True)
EOF

cat > requirements.txt <<EOF
Flask==2.2.2
EOF

cat > app.yaml <<EOF
runtime: python39
EOF
```

### ACT (Implementación)

```bash
# 1. Desplegar la aplicación en App Engine
echo "Desplegando aplicación..."
gcloud app deploy --quiet

# 2. Obtener la URL de la aplicación desplegada
export APP_URL=$(gcloud app browse --no-launch-browser)
echo "Aplicación desplegada en: $APP_URL"

# 3. Enviar tráfico a la aplicación para generar trazas
echo "Enviando 10 peticiones para generar trazas..."
for i in {1..10}; do curl -s $APP_URL > /dev/null; sleep 1; done

# La CLI de gcloud no genera trazas, pero puede leerlas.
# Esperamos un poco para que las trazas se procesen.
echo "Esperando 60 segundos para que las trazas sean procesadas..."
sleep 60
```

### ASSERT (Verificación)

```bash
# Verificar que se han capturado trazas en los últimos 5 minutos
echo "=== VERIFICANDO TRAZAS ==="
# Usamos un filtro para la URI de nuestra app
TRACE_COUNT=$(gcloud trace traces list --filter="/uri:${APP_URL:8}" --limit=10 --format="value(traceId)" | wc -l)

if [ "$TRACE_COUNT" -gt 0 ]; then
    echo "✅ Se encontraron $TRACE_COUNT trazas. Verificación exitosa."
    # Describir la traza más reciente
    LATEST_TRACE_ID=$(gcloud trace traces list --filter="/uri:${APP_URL:8}" --limit=1 --format="value(traceId)")
    echo "--- Detalle de la traza más reciente ($LATEST_TRACE_ID) ---"
    gcloud trace traces describe $LATEST_TRACE_ID
else
    echo "❌ No se encontraron trazas. La verificación falló."
fi
```

### CLEANUP (Limpieza)

```bash
echo "⚠️  Eliminando recursos de laboratorio..."
# Deshabilitar la aplicación de App Engine para detener cargos
gcloud app services delete default --quiet
# Opcional: si quieres eliminar todo el proyecto de GAE
# gcloud projects delete $PROJECT_ID --quiet
cd ..
rm -rf gae-trace-demo

echo "✅ Laboratorio completado - Recursos eliminados"
```

---

## 💡 Lecciones Aprendidas

*   **El trazado distribuido es esencial para los microservicios:** Sin él, depurar la latencia en un sistema complejo es como buscar una aguja en un pajar. Es una herramienta indispensable, no un lujo.
*   **El gráfico de cascada es tu mejor amigo:** Aprender a leer e interpretar el "waterfall graph" es la habilidad clave para encontrar cuellos de botella. Te muestra visualmente dónde se detiene o ralentiza una solicitud.
*   **La instrumentación es el peaje de entrada:** Aunque requiere un esfuerzo inicial, las librerías modernas como OpenTelemetry simplifican enormemente el proceso. La inversión en instrumentación se paga con creces en tiempo de depuración.

---

## ⚠️ Errores y Confusiones Comunes

*   **Esperar trazado automático en todas partes:** Asumir que todos los servicios de GCP se trazan automáticamente. La realidad es que la mayoría (GKE, Compute Engine) requieren que instrumentes tu código manualmente.
*   **Trazas rotas (gráficos incompletos):** Ocurre cuando el "contexto de la traza" (el Trace ID) no se propaga correctamente de un servicio al siguiente. Esto rompe la cadena y resulta en una visualización incompleta.
*   **Muestreo (Sampling) mal configurado:** Trazar cada solicitud puede ser costoso y generar demasiados datos. El muestreo te permite trazar un porcentaje de las solicitudes. Si la tasa es muy baja, puedes perder datos importantes; si es muy alta, puede impactar en el rendimiento y los costos.

---

## 🎯 Tips de Examen

*   Conoce los conceptos clave: **Trace** (la solicitud completa), **Span** (una operación individual) y **Span Context** (la información que se propaga entre servicios).
*   Entiende que la **instrumentación** (manual o automática) es un requisito para poder usar Cloud Trace.
*   Recuerda que el objetivo principal de Trace es analizar la **latencia** y los cuellos de botella de rendimiento.
*   Asocia servicios como **App Engine Standard** y **Cloud Functions** con un nivel de recolección de trazas automática.

---

## 🧾 Resumen

Cloud Trace es el sistema de trazado distribuido que te ayuda a depurar problemas de latencia en aplicaciones complejas y basadas en microservicios. Al recopilar y visualizar los datos de latencia como una "cascada" de operaciones (spans), permite a los desarrolladores y SREs identificar con precisión los cuellos de botella de rendimiento y optimizar la experiencia del usuario final.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-trace)
