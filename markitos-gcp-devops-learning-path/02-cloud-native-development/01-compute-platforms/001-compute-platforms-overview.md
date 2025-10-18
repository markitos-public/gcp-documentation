# 🚀 Visión General de Plataformas de Cómputo

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-visión-general-de-plataformas-de-cómputo)

---

## 🧭 Descripción

El "cómputo" es el cerebro de cualquier aplicación: es donde se ejecuta el código. Google Cloud ofrece un espectro completo de plataformas de cómputo, desde máquinas virtuales en las que tienes control total (IaaS) hasta plataformas totalmente gestionadas donde solo subes tu código (PaaS y FaaS). Este capítulo es un mapa que te guiará a través de las principales opciones de cómputo en GCP, ayudándote a entender cuál es la mejor para cada caso de uso.

---

## 📘 Detalles

Podemos visualizar las opciones de cómputo en un espectro que va de "más control, más gestión" a "menos control, menos gestión".

1.  **Compute Engine (IaaS - Infraestructura como Servicio):**
    *   **¿Qué es?** Máquinas Virtuales (VMs) que puedes configurar a tu gusto. Es el equivalente a tener un servidor físico, pero en la nube.
    *   **Control:** Total. Eliges el SO, las librerías, la configuración de red, todo.
    *   **Caso de uso:** Cargas de trabajo tradicionales, aplicaciones que requieren un SO específico, sistemas que necesitan configuraciones de hardware o red muy particulares.

2.  **Google Kubernetes Engine (GKE) (Híbrido IaaS/PaaS):**
    *   **¿Qué es?** Un servicio gestionado de Kubernetes para orquestar contenedores.
    *   **Control:** Alto. Gestionas tus contenedores, pods y deployments, pero Google gestiona el plano de control de Kubernetes. En modo Autopilot, Google gestiona también los nodos.
    *   **Caso de uso:** Aplicaciones basadas en microservicios, portabilidad entre nubes, despliegues escalables y resilientes.

3.  **App Engine (PaaS - Plataforma como Servicio):**
    *   **¿Qué es?** Una plataforma totalmente gestionada para desplegar aplicaciones escritas en lenguajes específicos (Python, Java, Go, etc.).
    *   **Control:** Medio. No gestionas servidores ni SO. Te centras en el código de tu aplicación. Hay dos sabores: Standard (más restrictivo, pero escala a cero) y Flexible (usa contenedores, más configurable).
    *   **Caso de uso:** Aplicaciones web y APIs monolíticas o de tamaño medio que necesitan escalar rápidamente.

4.  **Cloud Run (Serverless Containers - PaaS):**
    *   **¿Qué es?** Una plataforma para ejecutar contenedores sin estado (stateless) en un entorno totalmente gestionado.
    *   **Control:** Bajo. Solo te preocupas de tu imagen de contenedor. Escala automáticamente, incluso a cero.
    *   **Caso de uso:** Microservicios, APIs web, tareas en segundo plano. Es el estándar moderno para muchas nuevas aplicaciones en GCP.

5.  **Cloud Functions (FaaS - Functions as a Service):**
    *   **¿Qué es?** Una plataforma para ejecutar pequeños fragmentos de código (funciones) en respuesta a eventos (ej. una subida a Cloud Storage, un mensaje en Pub/Sub).
    *   **Control:** Mínimo. Solo escribes el código de tu función.
    *   **Caso de uso:** Lógica reactiva, procesamiento de datos en tiempo real, ETLs ligeros, "pegamento" entre servicios.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Desplegar la Misma App en 3 Niveles de Abstracción
**Contexto:** Desplegaremos una aplicación web "hello world" muy simple en Compute Engine (IaaS), Cloud Run (PaaS/Containers) y Cloud Functions (FaaS) para experimentar de primera mano las diferencias en el proceso de despliegue y gestión.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable compute.googleapis.com run.googleapis.com cloudfunctions.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"

# Crear código de la aplicación
# Para Compute Engine y Cloud Run, usaremos un contenedor pre-hecho.
# Para Cloud Functions, crearemos el código fuente.
mkdir function_source
cat <<EOT > function_source/main.py
import functions_framework

@functions_framework.http
def hello_http(request):
    return "Hello from Cloud Functions!"
EOT
```

#### ACT (Implementación del escenario)
```bash
# 1. Despliegue en IaaS (Compute Engine)
gcloud compute instances create-with-container vm-iaas --zone=${REGION}-b --container-image=gcr.io/google-samples/hello-app:1.0

# 2. Despliegue en PaaS (Cloud Run)
gcloud run deploy service-paas --image=gcr.io/google-samples/hello-app:1.0 --region=$REGION --allow-unauthenticated

# 3. Despliegue en FaaS (Cloud Functions)
gcloud functions deploy function-faas --runtime=python39 --trigger-http --allow-unauthenticated --source=./function_source --region=$REGION --entry-point=hello_http
```

#### ASSERT (Verificación de funcionalidades)
*Obtenemos las URLs de cada servicio para verificar que responden.*
```bash
# 1. Obtener IP de la VM (requiere crear regla de firewall no mostrada aquí por brevedad)
export VM_IP=$(gcloud compute instances describe vm-iaas --zone=${REGION}-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "IaaS (VM) accesible en: http://$VM_IP (tras abrir firewall)"

# 2. Obtener URL de Cloud Run
export RUN_URL=$(gcloud run services describe service-paas --region=$REGION --format="value(status.url)")
echo "PaaS (Cloud Run) accesible en: $RUN_URL"

# 3. Obtener URL de Cloud Functions
export FUNC_URL=$(gcloud functions describe function-faas --region=$REGION --format="value(https.trigger.url)")
echo "FaaS (Cloud Function) accesible en: $FUNC_URL"
```

#### CLEANUP (Limpieza de recursos)
```bash
gcloud compute instances delete vm-iaas --zone=${REGION}-b --quiet
gcloud run services delete service-paas --region=$REGION --quiet
gcloud functions delete function-faas --region=$REGION --quiet
rm -rf function_source
```

---

## 💡 Lecciones Aprendidas

*   **Elige según el nivel de control que necesites:** Si no necesitas gestionar el SO, no uses IaaS. Si tu aplicación está en un contenedor, Cloud Run es a menudo la mejor opción.
*   **Serverless no significa "sin servidores":** Significa que *tú* no tienes que gestionarlos. Google lo hace por ti.
*   **Contenedores como lenguaje universal:** Escribir tu aplicación en un contenedor te da la máxima flexibilidad para moverla entre Compute Engine, GKE y Cloud Run.

---

## ⚠️ Errores y Confusiones Comunes

*   **Usar Compute Engine para todo:** Es el error más común de quienes vienen de un mundo on-premise. A menudo, una solución PaaS o FaaS es más barata y eficiente.
*   **Confundir Cloud Run con Cloud Functions:** Cloud Run ejecuta contenedores completos (con las librerías que quieras). Cloud Functions ejecuta solo fragmentos de código en un entorno de ejecución predefinido.
*   **Ignorar el "cold start" en serverless:** Las plataformas serverless que escalan a cero pueden tener una pequeña latencia en la primera petición (arranque en frío). Hay que tenerlo en cuenta para aplicaciones sensibles a la latencia.

---

## 🎯 Tips de Examen

*   **El espectro de control:** El examen te dará un escenario y te pedirá que elijas la plataforma con el nivel de gestión adecuado. Aprende el espectro IaaS -> GKE -> PaaS -> FaaS.
*   **Contenedores -> GKE o Cloud Run:** Si el escenario menciona Docker o contenedores, la respuesta casi siempre será GKE (para orquestación compleja) o Cloud Run (para servicios simples).
*   **Eventos -> Cloud Functions:** Si el escenario describe una lógica que debe ejecutarse en respuesta a un evento (ej. "cuando se suba un fichero a un bucket..."), la respuesta es Cloud Functions.

---

## 🧾 Resumen

Google Cloud ofrece un abanico de servicios de cómputo para cubrir cualquier necesidad, desde el control total de IaaS con Compute Engine hasta la simplicidad de FaaS con Cloud Functions. La elección correcta depende del equilibrio entre el control que deseas mantener y la carga de gestión que estás dispuesto a asumir. Las plataformas modernas basadas en contenedores como GKE y Cloud Run ofrecen un punto intermedio ideal para la mayoría de las nuevas aplicaciones nativas de la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-visión-general-de-plataformas-de-cómputo)
