# culture Monitorización y Alerting en SRE

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#culture-monitorización-y-alerting-en-sre)

---

## 🧭 Descripción

La monitorización en SRE va más allá de simplemente observar gráficos de CPU. Se centra en medir lo que realmente importa: la experiencia del usuario. El alerting (la generación de alertas) se trata con sumo cuidado para que cada alerta sea significativa y accionable, evitando la fatiga por alertas. El enfoque de SRE es pasar de un modelo reactivo (alertar cuando algo se rompe) a uno proactivo (alertar cuando el presupuesto de error está en peligro).

---

## 📘 Detalles

### Los Cuatro Golden Signals

Para cualquier servicio, SRE recomienda monitorizar cuatro señales fundamentales que indican la salud del sistema desde la perspectiva del usuario:

1.  **Latencia (Latency):** El tiempo que tarda en servirse una petición. Es crucial distinguir entre la latencia de las peticiones exitosas y las fallidas.
2.  **Tráfico (Traffic):** La cantidad de demanda que está soportando el sistema, medida en una métrica apropiada para el servicio (ej. peticiones HTTP por segundo).
3.  **Errores (Errors):** La tasa de peticiones que fallan, ya sea explícitamente (ej. códigos HTTP 500) o implícitamente (ej. una respuesta 200 con contenido incorrecto).
4.  **Saturación (Saturation):** Cuán "lleno" está el servicio. Es una medida de la utilización de los recursos más limitados (ej. uso de memoria, I/O de disco). La saturación predice problemas futuros de rendimiento.

### Filosofía de Alerting

El objetivo de las alertas en SRE no es notificar cada anomalía, sino solo aquellas que requieren intervención humana para solucionarse. Una buena alerta debe ser:

*   **Urgente:** Requiere atención inmediata.
*   **Accionable:** Especifica claramente qué se debe hacer.
*   **Importante:** Indica un impacto real en el servicio.

SRE se enfoca en alertar sobre la **tasa de consumo del presupuesto de error (Error Budget Burn Rate)**. Si el servicio empieza a consumir el presupuesto de error a una velocidad que amenaza con agotarlo antes de que termine el periodo del SLO, se dispara una alerta. Esto permite al equipo actuar *antes* de que el SLO se viole.

```bash
# Ejemplo ilustrativo: Listar las políticas de alertas en tu proyecto.
# Estas políticas definen cuándo se debe notificar a un humano.
gcloud alpha monitoring policies list
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear una Política de Alerta basada en Métricas
**Contexto:** Crearemos una política de alerta que nos notifique si el uso de CPU de una instancia de Compute Engine supera el 80% durante más de 5 minutos. Esto es un indicador de saturación y puede predecir problemas de latencia.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs necesarias
gcloud services enable monitoring.googleapis.com compute.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export VM_NAME="vm-to-monitor"
export ALERT_POLICY_NAME="high-cpu-usage-policy"

# Crear una VM de prueba para monitorizar
gcloud compute instances create $VM_NAME --zone=europe-west1-b --machine-type=e2-micro

# Crear un canal de notificación (ej. por email, requiere configuración en la consola)
# Para este lab, asumimos que ya existe un canal o lo creamos manualmente.
# export NOTIFICATION_CHANNEL_ID=$(gcloud alpha monitoring channels list --format='value(name)')
```

#### ACT (Implementación del escenario)
*Creamos una política de alerta que se dispara cuando la utilización de la CPU supera un umbral.*
```bash
# Crear la política de alerta desde un fichero de configuración
cat <<EOT > alert-policy.json
{
  "displayName": "Uso de CPU elevado en VM de prueba",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "Uso de CPU > 80% durante 5 minutos",
      "conditionThreshold": {
        "filter": "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\" resource.label.instance_id=\"$(gcloud compute instances describe $VM_NAME --zone=europe-west1-b --format='value(id)')\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.8,
        "duration": "300s",
        "trigger": {
          "count": 1
        }
      }
    }
  ]
}
EOT

gcloud alpha monitoring policies create --policy-from-file=alert-policy.json
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la política de alerta ha sido creada correctamente.*
```bash
# Listar las políticas de alerta y filtrar por nuestro nombre
gcloud alpha monitoring policies list --filter="displayName='Uso de CPU elevado en VM de prueba'"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la política de alerta y la VM
export POLICY_ID=$(gcloud alpha monitoring policies list --filter="displayName='Uso de CPU elevado en VM de prueba'" --format="value(name)")
gcloud alpha monitoring policies delete $POLICY_ID --quiet
gcloud compute instances delete $VM_NAME --zone=europe-west1-b --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Monitoriza síntomas, no causas:** El uso de CPU alto (causa) no es tan importante como una latencia elevada (síntoma que afecta al usuario).
*   **Las alertas deben ser accionables:** Si una alerta no te dice qué hacer, es ruido. Cada alerta debe estar ligada a un runbook o a un procedimiento claro.
*   **Alerta sobre el burn rate del presupuesto de error:** Es el método más sofisticado. Te permite actuar antes de violar tu SLO, pero requiere una buena definición de SLIs.

---

## ⚠️ Errores y Confusiones Comunes

*   **Fatiga por alertas (Alert Fatigue):** Crear demasiadas alertas de baja prioridad que el equipo de guardia empieza a ignorar. Es un problema grave que puede enmascarar incidentes reales.
*   **Monitorizar todo:** Recopilar miles de métricas sin un propósito claro solo añade ruido y complejidad. Céntrate en los Golden Signals.
*   **Alertar sobre umbrales estáticos sin contexto:** Una alerta de "CPU > 90%" puede ser normal para un job de batch, pero crítica para un servidor web interactivo. Las alertas deben tener contexto.

---

## 🎯 Tips de Examen

*   **Conoce los 4 Golden Signals:** Latencia, Tráfico, Errores y Saturación. El examen puede pedirte que identifiques cuál es el más apropiado para un escenario dado.
*   **Diferencia entre White-box y Black-box monitoring:** White-box es monitorizar el interior de tu sistema (métricas de la JVM, logs). Black-box es monitorizar desde fuera, como lo haría un usuario (probes de disponibilidad, tests sintéticos).
*   **El objetivo del alerting en SRE:** No es notificar cada problema, sino solo aquellos que requieren intervención humana y amenazan el SLO.

---

## 🧾 Resumen

La monitorización y el alerting en SRE son disciplinas enfocadas en la experiencia del usuario y la gestión proactiva de la fiabilidad. Al centrarse en los Cuatro Golden Signals y en alertar sobre la tasa de consumo del presupuesto de error, los equipos SRE evitan la fatiga por alertas y dedican su tiempo a solucionar problemas que realmente importan, antes de que impacten significativamente en el servicio.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#culture-monitorización-y-alerting-en-sre)
