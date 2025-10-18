# culture Trabajo Manual (Toil) y Presupuestos de Error

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#culture-trabajo-manual-toil-y-presupuestos-de-error)

---

## 🧭 Descripción

En SRE, no todo el trabajo operativo es igual. Una distinción clave es la que se hace con el "Toil" (trabajo manual, repetitivo y automatizable). El objetivo de un equipo SRE es minimizar el Toil para poder dedicar tiempo a la ingeniería a largo plazo. Los Presupuestos de Error (Error Budgets), derivados de los SLOs, son la herramienta que permite al equipo SRE equilibrar el lanzamiento de nuevas funcionalidades (que puede introducir riesgo) con el trabajo de fiabilidad.

---

## 📘 Detalles

### ¿Qué es el Toil?

El libro de SRE de Google define el Toil con cinco características clave. Es un trabajo que tiende a ser:

1.  **Manual:** Un humano tiene que realizar los pasos.
2.  **Repetitivo:** No es algo que haces una sola vez, sino una y otra vez.
3.  **Automatizable:** Si un humano puede seguir un runbook para hacerlo, una máquina también puede.
4.  **Táctico:** Es reactivo, no estratégico ni proactivo.
5.  **Sin valor a largo plazo:** No aporta una mejora permanente al servicio. Al terminarlo, el servicio está igual que antes.

El objetivo de un SRE es mantener el Toil por debajo del 50% de su tiempo. El resto del tiempo debe dedicarse a la ingeniería: automatización, mejoras de rendimiento, etc.

### El Rol del Presupuesto de Error (Error Budget)

Como vimos en el capítulo anterior, el Presupuesto de Error es `100% - SLO`. Este presupuesto no es un objetivo de fallos, sino una herramienta de gestión para la toma de decisiones:

*   **Si queda presupuesto de error:** El equipo tiene "permiso" para tomar riesgos. Se pueden lanzar nuevas funcionalidades, realizar mantenimientos o experimentar. El equipo de desarrollo y el de SRE están alineados.

*   **Si el presupuesto de error se agota:** ¡Se congelan los lanzamientos! Todo el esfuerzo del equipo de desarrollo se redirige a ayudar al equipo SRE a mejorar la fiabilidad del servicio. No se pueden introducir más riesgos hasta que el servicio vuelva a operar dentro de su SLO y se recupere el presupuesto.

Este mecanismo crea un sistema de auto-regulación que equilibra de forma natural la velocidad y la fiabilidad, eliminando los conflictos entre los equipos de desarrollo ("queremos ir rápido") y operaciones ("queremos que sea estable").

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Simulación de Gestión de un Presupuesto de Error
**Contexto:** No podemos "crear" Toil con `gcloud`, pero podemos simular cómo un equipo podría reaccionar a un presupuesto de error agotado. Imaginemos que nuestro servicio de App Engine del capítulo anterior ha agotado su presupuesto de error del 0.5% (SLO del 99.5%). La política del equipo dicta que se debe aumentar la capacidad para mejorar la fiabilidad antes de cualquier nuevo despliegue.

#### ARRANGE (Preparación del laboratorio)
*Asumimos que tenemos una aplicación en App Engine y que hemos detectado que el presupuesto de error se ha agotado debido a una sobrecarga.*
```bash
# Habilitar APIs necesarias
gcloud services enable appengine.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)

# Asumimos que ya hay una app desplegada. Verificamos su configuración actual.
echo "Configuración actual de App Engine:"
gcloud app services describe default
```

#### ACT (Implementación del escenario)
*La decisión, tras agotar el presupuesto de error, es escalar la aplicación para que sea más robusta. En App Engine Standard, esto se hace ajustando la clase de instancia y el número mínimo de instancias para reducir la latencia y los errores por sobrecarga.*
```bash
# Crear un fichero app.yaml con la nueva configuración de escalado
cat <<EOT > app.yaml
runtime: python39
instance_class: F2 # Aumentamos la clase de instancia
automatic_scaling:
  min_instances: 2 # Aseguramos tener al menos 2 instancias activas
EOT

# Desplegar la nueva versión con la configuración de escalado mejorada
# Esto es trabajo de ingeniería, no Toil, porque mejora el servicio a largo plazo.
echo "\nDesplegando nueva configuración para mejorar fiabilidad..."
gcloud app deploy app.yaml --quiet
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la nueva configuración de escalado ha sido aplicada correctamente al servicio.*
```bash
# Describir el servicio y filtrar por la configuración de escalado
echo "\nVerificando nueva configuración de escalado:"
gcloud app services describe default | grep -E "instanceClass|minTotalInstances"
```

#### CLEANUP (Limpieza de recursos)
*En un caso real, esta configuración se mantendría. Para nuestro laboratorio, podemos revertirla o simplemente tomar nota.*
```bash
echo "\n✅ Laboratorio completado. La configuración de escalado ha sido aplicada."
# Para revertir, se desplegaría un app.yaml con la configuración original.
```

---

## 💡 Lecciones Aprendidas

*   **El Toil es el enemigo de la ingeniería:** El objetivo no es ser un héroe que apaga fuegos (Toil), sino un ingeniero que construye un sistema a prueba de fuego (automatización).
*   **El Presupuesto de Error alinea a los equipos:** Crea un objetivo común para desarrolladores y SREs, eliminando la fricción tradicional entre "velocidad" y "estabilidad".
*   **No todo el trabajo operativo es Toil:** El trabajo de ingeniería proactivo, como la automatización, la mejora de la monitorización o el refactoring para la fiabilidad, no es Toil porque proporciona valor a largo plazo.

---

## ⚠️ Errores y Confusiones Comunes

*   **Recompensar el Toil:** Recompensar a los ingenieros por trabajar noches y fines de semana para solucionar problemas manualmente solo incentiva a que el sistema siga siendo frágil.
*   **Ver el Presupuesto de Error como un "permiso para fallar":** No se trata de aspirar a fallar, sino de usarlo como un colchón para la innovación y la toma de riesgos calculados.
*   **Calcular mal el Toil:** Subestimar cuánto tiempo se dedica al Toil es común. Es crucial medirlo para poder reducirlo.

---

## 🎯 Tips de Examen

*   **Identifica el Toil:** El examen puede describir un escenario y preguntarte si es Toil. Recuerda las 5 características: manual, repetitivo, automatizable, táctico, sin valor duradero.
*   **El Presupuesto de Error como mecanismo de control:** Si el presupuesto se agota, se detienen los lanzamientos. Esta es la consecuencia más importante.
*   **El objetivo de SRE es reducir el Toil:** Cualquier pregunta sobre la meta principal de un equipo SRE a largo plazo probablemente involucre la automatización y la eliminación del Toil.

---

## 🧾 Resumen

La gestión del Toil y el uso de Presupuestos de Error son dos de las prácticas más transformadoras de SRE. Permiten a los equipos de operaciones escalar sub-linealmente con el crecimiento del servicio, dedicando su tiempo a la ingeniería de valor a largo plazo. El Presupuesto de Error proporciona un lenguaje común y basado en datos para que toda la organización pueda tomar decisiones informadas sobre el equilibrio entre la fiabilidad y la innovación.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#culture-trabajo-manual-toil-y-presupuestos-de-error)
