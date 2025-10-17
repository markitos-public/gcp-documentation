# ☁️ Cloud Monitoring

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

Cloud Monitoring es el servicio de monitorización gestionado e integrado de Google Cloud. Su función principal es recopilar métricas, eventos y metadatos de los servicios de GCP, de sondeos de tiempo de actividad (uptime checks), de la instrumentación de aplicaciones y de una gran variedad de componentes de aplicaciones comunes.

El problema que resuelve es fundamental para cualquier operación de TI moderna: proporcionar visibilidad completa sobre el rendimiento, el tiempo de actividad y el estado general de las aplicaciones y la infraestructura, permitiéndote encontrar y solucionar problemas de forma proactiva y rápida.

---

## 📘 Detalles

Cloud Monitoring se articula en torno a varios conceptos clave que trabajan juntos para proporcionar una observabilidad completa.

### 🔹 Metrics Scope (Ámbito de Métricas)

Históricamente, Monitoring se configuraba por proyecto. El modelo moderno y recomendado se basa en un **Metrics Scope**. Un proyecto cuyo ámbito de métricas aloja a otros proyectos puede ver y monitorizar las métricas de todos los proyectos que contiene, ofreciendo un "panel único de cristal" para la observabilidad de toda una organización o entorno. Esto simplifica enormemente la gestión en arquitecturas multi-proyecto.

### 🔹 Componentes Clave

*   **Métricas (Metrics):** Son el corazón de Monitoring. Una métrica es una serie temporal de puntos de datos numéricos. Existen varios tipos:
    *   **Métricas del sistema:** Recopiladas automáticamente de los servicios de GCP (ej. uso de CPU de una VM, latencia de un Load Balancer).
    *   **Métricas personalizadas (Custom Metrics):** Métricas que envías desde tu propia aplicación utilizando librerías cliente como OpenTelemetry o directamente a la API de Monitoring.
    *   **Métricas basadas en logs (Logs-based Metrics):** Métricas numéricas que se derivan del contenido de los logs en Cloud Logging (ej. contar el número de veces que aparece un error específico).

*   **Dashboards:** Son la principal herramienta de visualización. Permiten crear representaciones gráficas de tus métricas en forma de widgets (gráficos de líneas, medidores, tablas, etc.). Puedes usar los dashboards predefinidos que ofrece GCP para muchos servicios o crear los tuyos propios para correlacionar la información que más te interese.

*   **Alertas (Alerting):** Permiten definir políticas que te notificarán cuando se cumpla una condición específica. Una política de alertas consta de tres partes:
    1.  **Condición:** Define qué se vigila y cuándo se dispara la alerta (ej. "si el uso de CPU supera el 80% durante 5 minutos"). Puede basarse en métricas, uptime checks, o incluso en la ausencia de datos.
    2.  **Canales de Notificación:** Especifica dónde se enviará la notificación (Email, SMS, PagerDuty, Slack, Webhooks, etc.).
    3.  **Documentación:** Un campo opcional donde puedes incluir instrucciones para el equipo que reciba la alerta (playbooks, guías de troubleshooting, etc.).

*   **Sondeos de Tiempo de Actividad (Uptime Checks):** Son pruebas automatizadas que verifican la disponibilidad de tus servicios desde distintas ubicaciones del mundo. Pueden ser públicos (verificando un endpoint HTTP/HTTPS/TCP desde fuera de tu red) o privados (verificando un recurso dentro de tu VPC). Son esenciales para medir la disponibilidad desde la perspectiva del usuario.

*   **Grupos (Groups):** Permiten agrupar recursos de GCP (VMs, bases de datos, etc.) por nombre, etiquetas, región u otros criterios. Esto facilita la creación de dashboards y políticas de alertas que se aplican a un conjunto de recursos en lugar de a uno solo.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Crearemos una instancia de Compute Engine con un servidor web básico. Luego, configuraremos un Uptime Check público para monitorizar su disponibilidad y una política de alertas que nos notifique por email si el servicio deja de estar accesible.

### ARRANGE (Preparación)

```bash
# Variables del proyecto y configuración
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export ZONE="europe-west1-b"
export INSTANCE_NAME="web-monitor-demo"
export EMAIL_TO_NOTIFY="tu_email@example.com" # <-- CAMBIA ESTO A TU EMAIL

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Habilitar APIs necesarias
echo "Habilitando APIs de Compute Engine y Monitoring..."
gcloud services enable compute.googleapis.com monitoring.googleapis.com

# Crear una instancia de GCE con un servidor Nginx
echo "Creando instancia de Compute Engine..."
gcloud compute instances create $INSTANCE_NAME \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server \
    --metadata=startup-script='''#! /bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    echo "Instancia web lista" > /var/www/html/index.html
    '''

# Crear regla de firewall para permitir tráfico HTTP
echo "Creando regla de firewall..."
gcloud compute firewall-rules create allow-http --allow=tcp:80 --target-tags=http-server

# Obtener IP externa de la instancia
export INSTANCE_IP=$(gcloud compute instances describe $INSTANCE_NAME --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Instancia creada con IP: $INSTANCE_IP"
```

### ACT (Implementación)

```bash
# 1. Crear un canal de notificación por email
echo "Creando canal de notificación..."
gcloud monitoring channels create \
    --display-name="Administradores por Email" \
    --type="email" \
    --channel-labels="email_address=$EMAIL_TO_NOTIFY"

# Guarda el nombre del canal creado para usarlo después (el formato es projects/PROJECT_ID/notificationChannels/CHANNEL_ID)
export CHANNEL_NAME=$(gcloud monitoring channels list --filter="displayName='Administradores por Email'" --format='value(name)')
echo "Canal creado: $CHANNEL_NAME"
# IMPORTANTE: Revisa tu email y verifica la suscripción al canal.

# 2. Crear un sondeo de tiempo de actividad (Uptime Check)
echo "Creando Uptime Check..."
gcloud monitoring uptime-checks create http $INSTANCE_NAME-uptime-check \
    --host=$INSTANCE_IP \
    --path="/" \
    --port=80

# 3. Crear una política de alertas basada en el Uptime Check
echo "Creando política de alertas..."
gcloud monitoring policies create \
    --display-name="Web Server Inaccesible" \
    --policy-filter='metric.type="monitoring.googleapis.com/uptime_check/check_passed" AND resource.type="uptime_url" AND metric.label.check_id.ends_with("'$INSTANCE_NAME-uptime-check'")' \
    --condition-display-name="El Uptime Check ha fallado" \
    --condition-trigger-count=1 \
    --condition-trigger-period=60s \
    --condition-absence-trigger-window=300s \
    --condition-absence-trigger-count=1 \
    --notification-channels=$CHANNEL_NAME \
    --documentation-content="El servidor web en la instancia $INSTANCE_NAME no está respondiendo. Verificar el estado de la VM y la configuración del firewall."
```

### ASSERT (Verificación)

```bash
# Verificar la creación del Uptime Check
echo "=== VERIFICANDO UPTIME CHECK ==="
gcloud monitoring uptime-checks list --filter="displayName~'$INSTANCE_NAME'"

# Verificar la creación del canal de notificación
echo "=== VERIFICANDO CANAL DE NOTIFICACIÓN ==="
gcloud monitoring channels list --filter="displayName='Administradores por Email'"

# Verificar la creación de la política de alertas
echo "=== VERIFICANDO POLÍTICA DE ALERTAS ==="
gcloud monitoring policies list --filter="displayName='Web Server Inaccesible'"
```

### CLEANUP (Limpieza)

```bash
echo "⚠️  Eliminando recursos de laboratorio..."
gcloud monitoring policies delete $(gcloud monitoring policies list --filter="displayName='Web Server Inaccesible'" --format='value(name)') --quiet
gcloud monitoring channels delete $(gcloud monitoring channels list --filter="displayName='Administradores por Email'" --format='value(name)') --quiet
gcloud monitoring uptime-checks delete $(gcloud monitoring uptime-checks list --filter="displayName~'$INSTANCE_NAME'" --format='value(id)') --quiet
gcloud compute firewall-rules delete allow-http --quiet
gcloud compute instances delete $INSTANCE_NAME --quiet

echo "✅ Laboratorio completado - Recursos eliminados"
```

---

## 💡 Lecciones Aprendidas

*   **La monitorización es proactiva, no reactiva:** Configurar alertas y dashboards te permite detectar problemas antes de que impacten a tus usuarios.
*   **El contexto es clave en las alertas:** Una buena alerta no solo te dice *qué* falló, sino que su campo de documentación te puede decir *por qué* y *cómo* solucionarlo.
*   **Monitoriza desde fuera y desde dentro:** Los Uptime Checks te dan la perspectiva del usuario (externa), mientras que las métricas de la instancia te dan la perspectiva del sistema (interna). Ambas son necesarias.

---

## ⚠️ Errores y Confusiones Comunes

*   **Métricas vs. Logs:** Confundir Cloud Monitoring con Cloud Logging. **Monitoring** es para datos numéricos y series temporales (CPU, latencia). **Logging** es para registros de eventos (logs de aplicación, auditoría). Son servicios complementarios.
*   **La alerta no se disparó:** Un error común es configurar mal el filtro de la condición, usar un período de agregación incorrecto o un umbral demasiado alto. La CLI requiere filtros precisos.
*   **Olvidar verificar el canal de notificación:** Crear un canal de email y no hacer clic en el enlace de verificación que llega al correo. La alerta se disparará, pero la notificación nunca llegará.

---

## 🎯 Tips de Examen

*   Recuerda los 3 tipos de métricas: **del sistema** (automáticas), **personalizadas** (de tu app) y **basadas en logs**.
*   Comprende el concepto de **Metrics Scope** y su utilidad para monitorizar múltiples proyectos desde un único lugar.
*   Identifica las 3 partes de una política de alertas: **condición** (qué se vigila), **canal de notificación** (a quién se avisa) y **documentación** (qué hacer).
*   Diferencia entre Uptime Checks **públicos** (desde Internet) y **privados** (dentro de tu VPC para recursos sin IP externa).

---

## 🧾 Resumen

Cloud Monitoring es el sistema nervioso central de la observabilidad en GCP. Proporciona las herramientas para rastrear el rendimiento, visualizar datos y alertar sobre problemas en toda tu infraestructura y aplicaciones. Dominarlo es un paso esencial para mantener sistemas saludables, fiables y resilientes en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-monitoring)
