# culture Conceptos SRE: SLO, SLI, SLA

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#culture-conceptos-sre-slo-sli-sla)

---

## 🧭 Descripción

La Ingeniería de Fiabilidad de Sitios (SRE) es una disciplina que aplica los principios de la ingeniería de software a los problemas de operaciones. En lugar de basarse en la intuición, SRE utiliza datos para medir y mejorar la fiabilidad de un servicio. Los conceptos de SLI, SLO y SLA son el lenguaje cuantitativo que permite a los equipos de SRE tomar decisiones basadas en datos sobre la fiabilidad y el desarrollo de nuevas funcionalidades.

---

## 📘 Detalles

Estos tres términos están intrínsecamente relacionados, pero miden cosas distintas.

1.  **SLI (Service Level Indicator - Indicador de Nivel de Servicio):** Es una medida cuantitativa de algún aspecto del nivel de servicio que se presta. Es una métrica directa sobre un evento. Un buen SLI debe ser representativo de la experiencia del usuario.
    *   **Ejemplo:** El porcentaje de peticiones HTTP que se completan correctamente (código 200) en menos de 100ms.
    *   **En simple:** Es el número que te dice si algo fue bueno o malo. Por ejemplo, ¿la web cargó rápido? (Sí/No). El SLI es el porcentaje de respuestas "Sí".

2.  **SLO (Service Level Objective - Objetivo de Nivel de Servicio):** Es el objetivo o valor deseado para un SLI durante un período de tiempo. Es un objetivo interno que el equipo se compromete a cumplir. Un SLO es la línea que separa "lo suficientemente fiable" de "no lo suficientemente fiable".
    *   **Ejemplo:** El 99.9% de las peticiones HTTP (nuestro SLI) deben completarse correctamente en el último mes.
    *   **En simple:** Es el objetivo que nos ponemos. De todas las veces que medimos el SLI, ¿qué porcentaje de veces tiene que ser "bueno"?

3.  **Error Budget (Presupuesto de Error):** Es el complemento del SLO (100% - SLO). Representa la cantidad de "infidelidad" permitida antes de que los usuarios se sientan insatisfechos. El equipo de desarrollo puede "gastar" este presupuesto en lanzar nuevas funcionalidades (que pueden introducir inestabilidad) o en mantenimiento arriesgado. Si el presupuesto se agota, todo el esfuerzo se centra en mejorar la fiabilidad.
    *   **Ejemplo:** Si nuestro SLO es del 99.9%, nuestro presupuesto de error es del 0.1%. Esto significa que podemos permitirnos que 1 de cada 1000 peticiones falle en un mes.
    *   **En simple:** Es el número de fallos que nos podemos permitir al mes sin que nuestros jefes o usuarios se enfaden. Es nuestro "margen para equivocarnos".

4.  **SLA (Service Level Agreement - Acuerdo de Nivel de Servicio):** Es un contrato explícito o implícito con los usuarios que incluye las consecuencias de no cumplir con los SLOs. Generalmente, si un SLA no se cumple, el cliente recibe una compensación (ej. un crédito en la factura). Los SLAs suelen ser más laxos que los SLOs para que el equipo tenga un margen de maniobra.
    *   **Ejemplo:** Si la disponibilidad mensual del servicio (nuestro SLO) cae por debajo del 99.0% (nuestro SLA), los clientes recibirán un 10% de descuento en su próxima factura.
    *   **En simple:** Es la promesa que le hacemos al cliente y lo que pasa si la rompemos. Normalmente, si fallamos más de la cuenta (incumplimos el SLA), le devolveemos dinero.

```bash
# Ejemplo ilustrativo: No hay un comando gcloud directo para ver un SLO.
# Sin embargo, puedes usar la API de Cloud Monitoring para crear y consultar SLOs.
# Este comando lista los servicios de monitoreo, que es el primer paso para definir un SLO.
gcloud service-directory services list --location=global
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear un SLO Básico en Cloud Monitoring
**Contexto:** Crearemos un SLO de disponibilidad para un servicio de App Engine (un ejemplo de PaaS). El SLO medirá el porcentaje de peticiones que no devuelven un error del servidor (código 5xx).

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs necesarias
gcloud services enable monitoring.googleapis.com appengine.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west"

# Crear una app de App Engine de prueba (si no existe)
gcloud app create --region=$REGION --quiet || echo "App Engine ya existe."

# Desplegar una app de "hello world" para tener un servicio que monitorizar
gcloud app deploy app.yaml --quiet
# (Necesitarás un fichero app.yaml y un main.py en el directorio)
# app.yaml: runtime: python39
# main.py: from flask import Flask; app = Flask(__name__); @app.route(\'/\'
# def hello(): return 'Hello, World!'
```

#### ACT (Implementación del escenario)
*Usamos un fichero de configuración YAML para definir el SLO y lo importamos con `gcloud`.*
```bash
# Crear un fichero slo-config.yaml
cat <<EOT > slo-config.yaml
serviceLevelObjective:
  displayName: "Disponibilidad del Frontend"
  goal: 0.995
  rollingPeriod: "2592000s" # 30 días
  serviceLevelIndicator:
    requestBased:
      goodTotalRatio:
        goodServiceFilter: "metric.type=\"appengine.googleapis.com/http/server/response_count\" resource.type=\"gae_app\" metric.label.response_code<500"
        totalServiceFilter: "metric.type=\"appengine.googleapis.com/http/server/response_count\" resource.type=\"gae_app\""
EOT

# Crear el SLO usando la API de Cloud Monitoring
# (Nota: gcloud alpha/beta puede tener comandos directos en el futuro)
# Por ahora, se haría a través de la API REST o librerías cliente.
# Este es un ejemplo conceptual de cómo se haría:
gcloud alpha monitoring slos create --project=$PROJECT_ID --service="default" --slo-from-file=slo-config.yaml
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que el SLO ha sido creado listando los SLOs para nuestro servicio.*
```bash
# Listar los SLOs para el servicio 'default' de App Engine
gcloud alpha monitoring slos list --project=$PROJECT_ID --service="default"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el SLO
export SLO_ID=$(gcloud alpha monitoring slos list --project=$PROJECT_ID --service="default" --filter="displayName='Disponibilidad del Frontend'" --format="value(name)")
gcloud alpha monitoring slos delete $SLO_ID --project=$PROJECT_ID --service="default" --quiet

# Opcional: Desactivar la app de App Engine
gcloud app services delete default --quiet
```

---

## 💡 Lecciones Aprendidas

*   **Mide lo que le importa al usuario:** Un buen SLI (y por tanto un buen SLO) debe reflejar la experiencia del usuario. La disponibilidad y la latencia son los más comunes.
*   **El Presupuesto de Error impulsa la innovación:** El Error Budget no es un fracaso, es una herramienta de gestión que permite al equipo tomar riesgos calculados. Si no gastas tu presupuesto de error, tu servicio es demasiado fiable y podrías estar innovando más rápido.
*   **SLOs son internos, SLAs son externos:** Los SLOs son objetivos internos para el equipo de ingeniería. Los SLAs son promesas a los clientes con consecuencias financieras.

---

## ⚠️ Errores y Confusiones Comunes

*   **Confundir SLO con SLA:** Un SLO es un objetivo, un SLA es un contrato. Tu SLO siempre debe ser más estricto que tu SLA.
*   **Elegir un mal SLI:** Medir el uso de la CPU de un servidor no es un buen SLI, porque no refleja directamente si el usuario está recibiendo una respuesta rápida y correcta.
*   **Aspirar al 100% de fiabilidad:** El 100% es un objetivo inalcanzable y extremadamente caro. La diferencia entre 99.99% y 100% puede costar millones y no ser perceptible para el usuario.

---

## 🎯 Tips de Examen

*   **Recuerda la jerarquía:** SLI (métrica) -> SLO (objetivo interno) -> SLA (contrato externo con consecuencias).
*   **Error Budget = 1 - SLO:** Si un SLO es del 99.9%, el presupuesto de error es del 0.1%.
*   **Asocia los términos:** SRE se basa en datos. Los SLIs son los datos. Los SLOs son los objetivos basados en esos datos.

---

## 🧾 Resumen

Los SLIs, SLOs y SLAs son las herramientas fundamentales de SRE para gestionar la fiabilidad de un servicio de forma objetiva y basada en datos. Permiten a los equipos de ingeniería equilibrar la velocidad de desarrollo de nuevas funcionalidades con la necesidad de mantener una plataforma estable y fiable para los usuarios, utilizando el presupuesto de error como guía para la toma de decisiones.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#culture-conceptos-sre-slo-sli-sla)
