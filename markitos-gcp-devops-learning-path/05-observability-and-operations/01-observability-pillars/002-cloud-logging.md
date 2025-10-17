# ☁️ Cloud Logging

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

Cloud Logging es un servicio de gestión de registros (logs) totalmente gestionado y en tiempo real. Su propósito es proporcionar un lugar centralizado para el almacenamiento, la búsqueda, el análisis y la creación de alertas sobre datos de logs procedentes de servicios de Google Cloud, aplicaciones personalizadas, sistemas on-premises e incluso otras nubes.

Resuelve el desafío crítico de la gestión de logs a escala, permitiéndote realizar un troubleshooting eficaz de aplicaciones e infraestructura, llevar a cabo análisis de seguridad, y mantener el cumplimiento de normativas al ofrecer un único punto de verdad para todos tus registros.

---

## 📘 Detalles

Cloud Logging es más que un simple visor de logs. Es un sistema completo con varios componentes que trabajan en conjunto.

### 🔹 Log Router y Sinks (Receptores)

El **Log Router** es el corazón de Logging. Actúa como un concentrador central que procesa todos los logs que llegan a tu proyecto o organización. Basándose en reglas que tú defines, el Log Router reenvía los logs a diferentes destinos a través de **Sinks** (receptores).

Un Sink es una regla que define dos cosas:
1.  **Filtro:** Qué logs se van a enrutar (ej. `severity=ERROR` o `resource.type="gce_instance"`). Se pueden crear filtros de inclusión (solo estos) y de exclusión (todos menos estos).
2.  **Destino:** A dónde se enviarán los logs filtrados. Los destinos principales son:
    *   **Cloud Storage:** Para archivado a largo plazo y bajo costo (cold storage).
    *   **BigQuery:** Para análisis complejos y a gran escala (analytics).
    *   **Pub/Sub:** Para integrar los logs con otros sistemas o flujos de trabajo en tiempo real (streaming).
    *   **Otro Bucket de Logging:** Para centralizar logs de varios proyectos en un único bucket.

### 🔹 Log Buckets y Vistas

Los **Log Buckets** son los contenedores donde se almacenan los logs dentro de Cloud Logging. Permiten configurar la retención de datos y el control de acceso. Existen tres tipos:
*   `_Required`: Un bucket especial que siempre existe y almacena los logs de auditoría. No se puede modificar ni eliminar.
*   `_Default`: El bucket por defecto donde se envían la mayoría de los logs si no se especifica otra cosa. Su retención por defecto es de 30 días.
*   **Buckets definidos por el usuario:** Puedes crear tus propios buckets con políticas de retención personalizadas (de 1 día a 10 años).

Las **Vistas de Logs (Log Views)** permiten un control de acceso aún más fino, dando a los usuarios acceso solo a un subconjunto de los logs dentro de un bucket.

### 🔹 Explorador de Registros (Log Explorer)

Es la interfaz gráfica principal para interactuar con tus logs. Permite buscar, visualizar y analizar logs en tiempo real utilizando el **Lenguaje de Consultas de Logging (Logging Query Language)**, una sintaxis potente para filtrar por recurso, severidad, contenido del payload, y mucho más.

### 🔹 Métricas y Alertas Basadas en Logs

Cloud Logging se integra a la perfección con Cloud Monitoring. Puedes crear:
*   **Métricas basadas en Logs:** Convierten la información de los logs en métricas numéricas. Por ejemplo, puedes contar el número de veces que aparece un error específico en tus logs y visualizarlo en un dashboard de Monitoring.
*   **Alertas basadas en Logs:** Crean políticas de alerta que se disparan cuando aparece un patrón de log específico, sin necesidad de crear una métrica intermedia. Son ideales para eventos que son importantes pero poco frecuentes (ej. un log de seguridad crítico).

### 🔹 El Agente de Operaciones (Ops Agent)

Para VMs (en GCP o on-premise), el **Ops Agent** es el agente unificado y recomendado por Google. Combina la recolección de logs (usando Fluent Bit) y métricas (usando OpenTelemetry) en un único agente, simplificando la instalación y configuración en comparación con los agentes heredados (Logging Agent y Monitoring Agent).

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Escribiremos un log estructurado personalizado desde nuestra terminal. Crearemos un Sink para filtrar solo esos logs y enviarlos a un bucket de Cloud Storage para su archivado. Finalmente, crearemos una métrica basada en logs para contarlos.

### ARRANGE (Preparación)

```bash
# Variables del proyecto y configuración
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export BUCKET_NAME="log-archive-bucket-$PROJECT_ID"
export SINK_NAME="custom-log-sink"
export LOG_NAME="my-custom-log"

# Habilitar APIs necesarias
echo "Habilitando APIs de Logging, Storage y Monitoring..."
gcloud services enable logging.googleapis.com storage.googleapis.com monitoring.googleapis.com

# Crear bucket de Cloud Storage para el archivado
echo "Creando bucket de Cloud Storage..."
gsutil mb -l $REGION gs://$BUCKET_NAME

# Obtener la cuenta de servicio del sink (se crea automáticamente)
# El sink writer identity se crea después de crear el sink, por lo que este paso es posterior.
```

### ACT (Implementación)

```bash
# 1. Escribir un log estructurado (JSON) personalizado
echo "Escribiendo log estructurado..."
gcloud logging write $LOG_NAME '{"message": "Inicio de proceso batch", "status": "SUCCESS", "batch_id": "12345"}' --payload-type=json --severity=INFO

# 2. Crear un Sink para enrutar los logs personalizados a Cloud Storage
echo "Creando sink..."
gcloud logging sinks create $SINK_NAME storage.googleapis.com/$BUCKET_NAME \
    --log-filter="logName=projects/$PROJECT_ID/logs/$LOG_NAME AND jsonPayload.status='SUCCESS'"

# 3. Otorgar permisos a la cuenta de servicio del Sink sobre el bucket
# Obtenemos la identidad del escritor del sink
export SINK_WRITER_IDENTITY=$(gcloud logging sinks describe $SINK_NAME --format='value(writerIdentity)')
echo "Otorgando permisos a $SINK_WRITER_IDENTITY..."
gsutil iam ch $SINK_WRITER_IDENTITY:objectCreator gs://$BUCKET_NAME

# 4. Crear una métrica basada en logs para contar los logs de éxito
echo "Creando métrica basada en logs..."
gcloud logging metrics create batch-success-metric \
    --description="Cuenta los procesos batch exitosos" \
    --filter="logName=projects/$PROJECT_ID/logs/$LOG_NAME AND jsonPayload.status='SUCCESS'"
```

### ASSERT (Verificación)

```bash
# Verificar la creación del Sink
echo "=== VERIFICANDO SINK ==="
gcloud logging sinks describe $SINK_NAME

# Verificar la creación de la métrica
echo "=== VERIFICANDO MÉTRICA ==="
gcloud logging metrics describe batch-success-metric

# Escribir otro log para probar el sink y la métrica
echo "Escribiendo otro log para generar datos..."
gcloud logging write $LOG_NAME '{"message": "Fin de proceso batch", "status": "SUCCESS", "batch_id": "12346"}' --payload-type=json --severity=INFO

# La verificación final requiere esperar unos minutos a que el log sea procesado y exportado.
# Después de unos 5 minutos, puedes verificar el bucket:
# gsutil ls gs://$BUCKET_NAME
```

### CLEANUP (Limpieza)

```bash
echo "⚠️  Eliminando recursos de laboratorio..."
gcloud logging metrics delete batch-success-metric --quiet
gcloud logging sinks delete $SINK_NAME --quiet
gsutil rm -r gs://$BUCKET_NAME

echo "✅ Laboratorio completado - Recursos eliminados"
```

---

## 💡 Lecciones Aprendidas

*   **Los logs son más que texto para debug:** Son una fuente de datos muy rica. Al enviarlos a BigQuery, puedes realizar análisis de negocio, y al enviarlos a Pub/Sub, puedes disparar flujos de trabajo automatizados.
*   **El logging estructurado (JSON) es tu mejor aliado:** Permite realizar consultas y filtros increíblemente potentes y precisos sobre los campos del log, algo imposible con texto plano.
*   **Los Sinks son la clave para la gestión de logs a escala:** Permiten implementar estrategias de almacenamiento por niveles (ej. "hot" en Logging, "warm/cold" en GCS) y segregar logs por motivos de seguridad o cumplimiento.

---

## ⚠️ Errores y Confusiones Comunes

*   **Permisos del Sink:** El error más común es olvidar dar permisos a la cuenta de servicio del Sink (`writerIdentity`) sobre el destino. El sink se crea, pero los logs nunca llegan. La consola de GCP suele avisar de esto.
*   **Filtros incorrectos:** Escribir un filtro para un sink o en el Log Explorer que no captura los logs esperados. Es importante probar los filtros en el Log Explorer antes de aplicarlos a un sink.
*   **Desconocer la retención por defecto:** Asumir que los logs se guardan para siempre. El bucket `_Default` tiene una retención de 30 días. Si necesitas más tiempo, debes crear un sink a GCS/BigQuery o configurar un bucket personalizado.

---

## 🎯 Tips de Examen

*   Conoce los 4 destinos principales de un Sink: **Cloud Storage**, **BigQuery**, **Pub/Sub** y **otro Bucket de Logging**.
*   Entiende la función del **Log Router**: es el componente central que recibe todos los logs y los dirige según las reglas de los sinks.
*   Diferencia el bucket `_Required` (logs de auditoría, inmutable) del bucket `_Default` (logs generales, retención de 30 días).
*   Recuerda que el **Ops Agent** es el agente unificado y recomendado para recolectar tanto logs como métricas de las VMs.

---

## 🧾 Resumen

Cloud Logging ofrece una solución centralizada, escalable y en tiempo real para la gestión de todos tus registros. A través de su potente lenguaje de consulta, sus capacidades de enrutamiento con Sinks y su profunda integración con el resto de la suite de operaciones, constituye la base para un troubleshooting efectivo, análisis de seguridad e inteligencia operacional en GCP.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-logging)
