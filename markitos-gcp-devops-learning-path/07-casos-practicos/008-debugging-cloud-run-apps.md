# ☁️ Caso Práctico: Debugging de Aplicaciones en Cloud Run

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🛠️ Kit de Herramientas de Debugging en Cloud Run](#️-kit-de-herramientas-de-debugging-en-cloud-run)
* [🕵️‍♂️ Proceso de Debugging por Síntomas](#️-proceso-de-debugging-por-síntomas)
* [🔬 Laboratorio Práctico (Simulación de Errores)](#-laboratorio-práctico-simulación-de-errores)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Un equipo despliega un nuevo servicio en Cloud Run. Al intentar acceder a la URL del servicio, reciben un error genérico del navegador como `HTTP 503 Service Unavailable` o `HTTP 500 Internal Server Error`. En otros casos, el despliegue mismo falla y no se puede crear una nueva revisión del servicio.

**Objetivo:** Proporcionar una guía "pasito a pasito" para diagnosticar por qué un servicio de Cloud Run no se despliega o no responde correctamente, utilizando las herramientas nativas de la plataforma.

---

## 🛠️ Kit de Herramientas de Debugging en Cloud Run

Cloud Run, al ser una plataforma serverless, abstrae la infraestructura, por lo que el debugging se centra en los logs y la configuración del servicio.

1.  **Pestaña de LOGS en la UI de Cloud Run:** Es el lugar principal para empezar. Filtra automáticamente los logs de tu servicio. Aquí verás tanto los logs de la aplicación (lo que escribes a `stdout` o `stderr`) como los logs del sistema de Cloud Run (ej. "Container Sandbox Exceeded Memory Limit").
2.  **Cloud Logging (Logs Explorer):** Ofrece una capacidad de filtrado y búsqueda mucho más potente que la pestaña de logs de la UI. Puedes correlacionar logs de varios servicios, crear métricas basadas en logs y guardas filtros complejos.
3.  **Pestaña de REVISIONES en la UI de Cloud Run:** Permite ver el historial de despliegues. Si un despliegue falla, aquí aparecerá un mensaje de error claro y conciso sobre la causa (ej. la imagen no se pudo descargar, el health check falló).
4.  **Cloud Trace:** Si está habilitado, permite ver el desglose de la latencia de las peticiones, igual que en el caso práctico de observabilidad.

---

## 🕵️‍♂️ Proceso de Debugging por Síntomas

### Escenario 1: El Despliegue Falla (No se crea la nueva revisión)

**Síntoma:** Al ejecutar `gcloud run deploy`, el comando falla o la UI muestra un error en la creación de la revisión.

1.  **Diagnóstico:** Ve a la pestaña **REVISIONES** del servicio en la consola de Cloud Run. Busca la revisión fallida. Tendrá un icono de error y un mensaje explicativo.
2.  **Causas Comunes y Soluciones:**
    *   **Error al Descargar la Imagen:** Similar a `ImagePullBackOff` en GKE. El mensaje dirá que no se pudo encontrar la imagen o que no hay permisos.
        *   **Solución:** Verificar que el nombre de la imagen es correcto y que la cuenta de servicio de Cloud Run (por defecto, `PROJECT_NUMBER-compute@developer.gserviceaccount.com`) tiene el rol `roles/artifactregistry.reader` para acceder al repositorio.
    *   **Fallo en el Health Check de Inicio:** Cloud Run necesita que tu contenedor inicie un servidor web y escuche en el puerto especificado (por defecto, `8080`) en un tiempo determinado. Si no lo hace, el despliegue se revierte.
        *   **Solución:** Asegúrate de que tu aplicación escucha en `0.0.0.0` (no en `localhost` o `127.0.0.1`) y en el puerto que Cloud Run espera (configurable a través de la variable de entorno `PORT`). Revisa los logs para ver si la aplicación falla antes de poder iniciar el servidor.

### Escenario 2: El Servicio Despliega, pero las Peticiones Fallan (HTTP 5xx)

**Síntoma:** La URL del servicio devuelve un error 500 o 503. La aplicación no responde como se espera.

1.  **Diagnóstico:** Ve directamente a la pestaña de **LOGS** del servicio.
2.  **Causas Comunes y Soluciones:**
    *   **Crash de la Aplicación (`Container Sandbox Exited with a Non-Zero Status`):** Este es el equivalente a `CrashLoopBackOff`. El log del sistema de Cloud Run te dirá que el contenedor se detuvo. Justo antes de ese log del sistema, encontrarás los **logs de tu aplicación** que muestran la excepción o el error que causó el fallo.
        *   **Solución:** Analiza el stack trace en los logs de tu aplicación. Puede ser un error de código, una variable de entorno que falta, un problema de conexión a una base de datos, etc.
    *   **Límite de Memoria Excedido (`Container Sandbox Exceeded Memory Limit`):** Tu aplicación está consumiendo más memoria de la que tiene asignada la revisión de Cloud Run.
        *   **Solución:** Optimiza el uso de memoria en tu aplicación o despliega una nueva revisión con un límite de memoria más alto (`--memory` en gcloud).
    *   **Timeout de la Petición:** La petición tarda más en procesarse que el timeout configurado en Cloud Run (por defecto, 5 minutos).
        *   **Solución:** Optimiza el código que causa la lentitud (usando Cloud Trace para encontrar el cuello de botella) o aumenta el timeout de la petición (`--timeout` en gcloud).
    *   **Problemas de Permisos de la Cuenta de Servicio:** La aplicación intenta acceder a otro servicio de GCP (ej. Cloud Storage, Secret Manager) pero su cuenta de servicio no tiene los roles de IAM necesarios.
        *   **Solución:** Revisa los logs en busca de errores de `Permission Denied`. Asigna los roles de IAM correctos a la cuenta de servicio asociada a la revisión de Cloud Run.

---

## 🔬 Laboratorio Práctico (Simulación de Errores)

Usaremos una aplicación simple de Python (Flask) para simular errores comunes.

### 1. Simular un Crash de Aplicación

```bash
# ARRANGE: Crear una app que falla al inicio si no tiene una variable de entorno
mkdir run-app-error && cd run-app-error
cat > main.py <<EOF
import os
from flask import Flask

app = Flask(__name__)

# La app falla si no se define esta variable
config_value = os.environ["REQUIRED_CONFIG"]

@app.route('/')
def hello_world():
    return f"Config: {config_value}!"

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

cat > Dockerfile <<EOF
FROM python:3.9-slim
WORKDIR /app
RUN pip install Flask
COPY . .
CMD ["python", "main.py"]
EOF

# ACT: Desplegar la app sin la variable de entorno requerida
# (Asumimos que gcloud build y deploy están configurados)
gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/run-app-error
gcloud run deploy run-app-error --image gcr.io/$(gcloud config get-value project)/run-app-error --allow-unauthenticated --region=europe-west1

# ASSERT: Diagnosticar el problema
# El despliegue podría fallar, o si despliega, las peticiones darán error 503.
# Ve a la pestaña de LOGS en la UI de Cloud Run.
# Verás un error de Python: "KeyError: 'REQUIRED_CONFIG'", seguido de un log del sistema
# indicando que el contenedor se detuvo.

# CLEANUP: Desplegar de nuevo con la variable de entorno para arreglarlo
gcloud run deploy run-app-error --image gcr.io/$(gcloud config get-value project)/run-app-error --set-env-vars=REQUIRED_CONFIG=hello --allow-unauthenticated --region=europe-west1
gcloud run services delete run-app-error --region=europe-west1 --quiet
cd .. && rm -rf run-app-error
```

---

## 💡 Lecciones Aprendidas

*   **Los Logs son tu Única Fuente de Verdad:** En un entorno serverless como Cloud Run, no puedes hacer `ssh` a la máquina. Tu capacidad para resolver problemas depende al 100% de la calidad de tus logs y de tu habilidad para interpretarlos.
*   **Distingue Logs del Sistema y Logs de la Aplicación:** Cloud Run emite logs del sistema (en color o con un icono en la UI) que te informan sobre el estado de la *plataforma* (memoria, timeouts). Estos te dan el contexto para entender los logs de tu *aplicación*.
*   **Escucha en `0.0.0.0`:** Un error de principiante muy común es que el servidor web de la aplicación escuche en `localhost` o `127.0.0.1`. Esto solo acepta conexiones desde dentro del propio contenedor. Debe escuchar en `0.0.0.0` para aceptar conexiones externas que le envía Cloud Run.

---

## 🧾 Resumen

El debugging en Cloud Run es un proceso centrado en los logs. Ya sea que un despliegue falle o que las peticiones a un servicio activo devuelvan errores, la respuesta casi siempre se encuentra en la pestaña de Logs de la consola. Al analizar tanto los logs del sistema de Cloud Run como los logs generados por la propia aplicación, se pueden diagnosticar rápidamente problemas que van desde errores de configuración y permisos hasta bugs en el código y límites de recursos.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-debugging-de-aplicaciones-en-cloud-run)
