# 🚀 App Engine (PaaS)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-app-engine-paas)

---

## 🧭 Descripción

App Engine es la oferta original de Plataforma como Servicio (PaaS) de Google Cloud. Es una plataforma totalmente gestionada para construir y desplegar aplicaciones a escala. App Engine abstrae toda la gestión de la infraestructura, permitiendo a los desarrolladores centrarse exclusivamente en escribir código. Es ideal para aplicaciones web y APIs que necesitan escalar de forma rápida y automática sin tener que preocuparse por servidores, parches o configuración de red.

---

## 📘 Detalles

App Engine se ofrece en dos entornos distintos, cada uno con sus propias características:

### 1. App Engine Standard Environment (Entorno Estándar)

*   **Concepto:** Tu código se ejecuta en un "sandbox" ligero dentro de un entorno de ejecución específico para un lenguaje (Python, Java, Go, PHP, etc.).
*   **Escalado:** Es extremadamente rápido y puede escalar desde cero instancias hasta miles en segundos. Es la opción más rentable si tu tráfico es esporádico, ya que puede escalar a cero y no pagar nada.
*   **Limitaciones:** Es más restrictivo. No puedes escribir en el sistema de ficheros local (salvo en `/tmp`), no puedes instalar binarios de terceros y estás limitado a las librerías y versiones que soporta el entorno de ejecución.

### 2. App Engine Flexible Environment (Entorno Flexible)

*   **Concepto:** Tu aplicación se empaqueta en un contenedor Docker y se ejecuta en una VM de Compute Engine gestionada por App Engine.
*   **Escalado:** Es más lento que el Estándar, ya que necesita arrancar VMs. No puede escalar a cero; siempre debe tener al menos una instancia corriendo.
*   **Flexibilidad:** Como su nombre indica, es mucho más flexible. Puedes usar cualquier lenguaje que pueda correr en un contenedor, instalar cualquier binario, escribir en el disco y acceder a la red de la VPC de forma más completa.

### Componentes de App Engine

Una aplicación de App Engine se compone de:

*   **Servicios (Services):** Una aplicación puede tener uno o más servicios. El servicio `default` es obligatorio. Esto te permite descomponer tu aplicación en componentes lógicos (ej. un servicio para el frontend y otro para la API de backend).
*   **Versiones (Versions):** Cada vez que despliegas tu código en un servicio, se crea una nueva versión. App Engine te permite dividir el tráfico entre diferentes versiones, facilitando los despliegues Canary o Blue/Green.
*   **Instancias (Instances):** Son las unidades de cómputo que ejecutan tu código. App Engine las crea y destruye automáticamente según la carga.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Desplegar una Aplicación en App Engine Standard y Dividir Tráfico
**Contexto:** Desplegaremos una aplicación simple en Python en el entorno Estándar. Luego, desplegaremos una segunda versión y dividiremos el tráfico para realizar un lanzamiento seguro.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable appengine.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west"

# Crear el código fuente de la aplicación (v1)
mkdir app_v1
cat <<EOT > app_v1/main.py
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return "Hello from App Engine v1!"
EOT

# Crear el fichero de configuración app.yaml para v1
cat <<EOT > app_v1/app.yaml
runtime: python39
EOT

# Crear el código fuente de la aplicación (v2)
mkdir app_v2
cat <<EOT > app_v2/main.py
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return "Hello from App Engine v2!"
EOT

# Crear el fichero de configuración app.yaml para v2
cat <<EOT > app_v2/app.yaml
runtime: python39
EOT

# Crear la aplicación de App Engine en la región (solo se hace una vez por proyecto)
gcloud app create --region=$REGION --quiet || echo "App Engine ya existe."
```

#### ACT (Implementación del escenario)
*Desplegamos v1 para que reciba todo el tráfico. Luego desplegamos v2 sin promocionarla. Finalmente, dividimos el tráfico.*
```bash
# 1. Desplegar la v1 y dirigir todo el tráfico a ella
echo "\n=== Desplegando v1... ==="
(cd app_v1 && gcloud app deploy --version=v1 --quiet)

# 2. Desplegar la v2 sin dirigirle tráfico
echo "\n=== Desplegando v2 (sin tráfico)... ==="
(cd app_v2 && gcloud app deploy --version=v2 --no-promote --quiet)

# 3. Dividir el tráfico 50/50 entre v1 y v2
echo "\n=== Dividiendo el tráfico 50/50... ==="
gcloud app services set-traffic default --splits=v1=0.5,v2=0.5 --quiet
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos la configuración del tráfico y accedemos a la URL para ver las dos versiones.*
```bash
# 1. Verificar la división de tráfico
echo "\n=== Verificando la configuración de tráfico... ==="
gcloud app services describe default

# 2. Acceder a la URL varias veces para ver las dos respuestas
export APP_URL=$(gcloud app browse --no-launch-browser)
echo "\n🚀 Accede a la URL varias veces para ver las dos versiones: $APP_URL"
for i in {1..10}; do curl -s $APP_URL; echo; done
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar las versiones y servicios (o desactivar la app)
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud app services delete default --quiet
rm -rf app_v1 app_v2
```

---

## 💡 Lecciones Aprendidas

*   **Standard para simplicidad y costo, Flexible para control:** Elige Standard si tu aplicación se ajusta a sus limitaciones y quieres el escalado a cero. Elige Flexible si necesitas control a nivel de contenedor o librerías personalizadas.
*   **`app.yaml` es el centro de control:** Este fichero de configuración es donde defines el entorno de ejecución, las variables de entorno, la configuración de escalado y mucho más.
*   **Servicios para microservicios:** Puedes desplegar cada microservicio de tu aplicación como un servicio diferente dentro de la misma app de App Engine, cada uno con su propio escalado y versiones.

---

## ⚠️ Errores y Confusiones Comunes

*   **Elegir la región incorrecta:** La región de una aplicación de App Engine se elige una sola vez y no se puede cambiar. Es una decisión importante al inicio del proyecto.
*   **Ignorar las diferencias entre Standard y Flexible:** Intentar usar una librería C nativa en Standard fallará. No entender que Flexible no escala a cero puede llevar a costos inesperados.
*   **Confundir App Engine con App Service (Azure) o Elastic Beanstalk (AWS):** Aunque son conceptualmente similares (PaaS), cada uno tiene sus propias características, ficheros de configuración y modelos de despliegue.

---

## 🎯 Tips de Examen

*   **Standard vs. Flexible:** Conoce las diferencias clave. Standard = sandbox, escalado a cero, rápido. Flexible = contenedores, no escala a cero, más control.
*   **División de Tráfico (Traffic Splitting):** Es una característica fundamental de App Engine para lanzamientos seguros. Si el escenario menciona un despliegue gradual, App Engine es una posible respuesta.
*   **`gcloud app deploy`:** Es el comando principal para desplegar tu aplicación. El fichero `app.yaml` debe estar en el directorio desde donde lo ejecutas.

---

## 🧾 Resumen

App Engine es la solución PaaS madura y robusta de Google Cloud, ideal para desarrolladores que quieren olvidarse de la infraestructura y centrarse en el código. Con sus dos entornos, Standard y Flexible, ofrece un abanico de opciones que va desde la máxima eficiencia de costos y simplicidad, hasta la flexibilidad de los contenedores, todo ello con potentes herramientas de versionado y escalado automático integradas.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-app-engine-paas)
