# ☁️ Security Command Center (SCC): Tu Panel Único de Seguridad

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

**Security Command Center (SCC)** es la plataforma centralizada de gestión de la postura de seguridad y riesgos de Google Cloud. Su propósito es proporcionar un único panel de control para el inventario de recursos, la detección de vulnerabilidades, la identificación de amenazas y la monitorización del cumplimiento normativo en toda tu organización de GCP. SCC agrega hallazgos de seguridad de múltiples fuentes, permitiendo a los equipos de seguridad priorizar y remediar riesgos de manera eficiente.

---

## 📘 Detalles

SCC se ofrece en dos niveles: **Standard** (gratuito) y **Premium** (de pago), que ofrece capacidades de detección de amenazas más avanzadas.

### 🔹 Componentes y Servicios Integrados

SCC no es un único servicio, sino un concentrador que integra los resultados de varios servicios de seguridad:

1.  **Asset Inventory:** Descubre y cataloga todos los recursos (proyectos, VMs, buckets, etc.) de tu organización, proporcionando una base para el análisis de seguridad.

2.  **Security Health Analytics:** Escanea de forma automática y continua tus recursos de GCP en busca de malas configuraciones comunes, como buckets de Cloud Storage públicos, reglas de firewall demasiado permisivas, falta de encriptación o políticas de IAM arriesgadas. Es el corazón de la gestión de la postura de seguridad.

3.  **Web Security Scanner:** Escanea tus aplicaciones web en App Engine, GKE y Compute Engine en busca de vulnerabilidades comunes como Cross-Site Scripting (XSS), librerías obsoletas o contenido mixto.

4.  **Event Threat Detection (Premium):** Utiliza los logs de auditoría y otros flujos de logs para detectar amenazas en casi tiempo real. Puede identificar actividades sospechosas como malware, minería de criptomonedas, exfiltración de datos y ataques de fuerza bruta.

5.  **Container Threat Detection (Premium):** Detecta ataques comunes en tiempo de ejecución dentro de tus contenedores, como la ejecución de un binario malicioso, una shell inversa o la carga de librerías inesperadas.

6.  **Vulnerability Assessment (integrado con Artifact Analysis):** Muestra los hallazgos de vulnerabilidades de las imágenes de contenedor directamente en SCC.

### 🔹 Hallazgos (Findings)

El concepto central en SCC es el **hallazgo (finding)**. Un hallazgo es un registro de un posible problema de seguridad o una mala configuración. Cada hallazgo incluye:
*   **Categoría:** El tipo de problema (ej. `PUBLIC_BUCKET_ACL`).
*   **Severidad:** `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.
*   **Recurso afectado:** El recurso específico de GCP que tiene el problema.
*   **Pasos de remediación:** Recomendaciones sobre cómo solucionar el problema.
*   **Estado:** `ACTIVE`, `INACTIVE` o `MUTED`.

Los equipos de seguridad pueden gestionar el ciclo de vida de un hallazgo, silenciándolo si es un falso positivo o marcándolo como solucionado.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Crearemos intencionadamente un recurso mal configurado (un bucket de Cloud Storage público) y usaremos la CLI para ver cómo Security Command Center lo detecta como un hallazgo.

### ARRANGE (Preparación)

```bash
# 1. Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='json' | jq -r '.[] | if .type=="organization" then .id else empty end')
export BUCKET_NAME="scc-demo-public-bucket-$PROJECT_ID"

# 2. Habilitar las APIs necesarias
# La activación de SCC a menudo se hace a nivel de organización en la consola.
gcloud services enable securitycenter.googleapis.com storage.googleapis.com

# 3. Crear el bucket mal configurado
# Le damos acceso de lectura público a todos los usuarios.
gsutil mb gs://$BUCKET_NAME
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
```

### ACT (Implementación)

```bash
# Security Health Analytics escanea periódicamente. Para acelerar, podemos simular la espera.
# En un entorno real, el hallazgo puede tardar desde minutos hasta horas en aparecer.
echo "Recurso mal configurado creado. Esperando a que el escáner de SCC lo detecte..."
# NOTA: No hay un comando para forzar un escaneo de un recurso específico vía CLI.
# El siguiente paso de ASSERT se debe ejecutar tras un tiempo de espera.

echo "Esperando 2 minutos para la detección..."
sleep 120
```

### ASSERT (Verificación)

```bash
# 1. Listar los hallazgos activos en la organización/proyecto
# Filtramos por la categoría "PUBLIC_BUCKET_ACL" para encontrar nuestro problema específico.
echo "=== Buscando hallazgos de buckets públicos... ==="
gcloud scc findings list $ORG_ID \
    --filter="category=\"PUBLIC_BUCKET_ACL\" AND state=\"ACTIVE\" AND resourceName:\"$BUCKET_NAME\""

# 2. Obtener los detalles de un hallazgo específico
# Primero, obtenemos el nombre completo del hallazgo
export FINDING_NAME=$(gcloud scc findings list $ORG_ID --filter="category=\"PUBLIC_BUCKET_ACL\" AND resourceName:\"$BUCKET_NAME\"" --format="value(name)")

if [ -n "$FINDING_NAME" ]; then
    echo "✅ Hallazgo encontrado: $FINDING_NAME"
    echo "--- Detalles del Hallazgo ---"
    gcloud scc findings describe $FINDING_NAME
else
    echo "❌ Aún no se ha encontrado el hallazgo. Puede que el escaneo tarde más tiempo."
fi
```

### CLEANUP (Limpieza)

```bash
# 1. Corregir la mala configuración (remediación)
gsutil iam ch -d allUsers:objectViewer gs://$BUCKET_NAME

# 2. Eliminar el bucket
gsutil rb gs://$BUCKET_NAME

# 3. Marcar el hallazgo como solucionado (opcional, SCC lo hará automáticamente)
# if [ -n "$FINDING_NAME" ]; then
#     gcloud scc findings update $FINDING_NAME --state="INACTIVE"
# fi

echo "✅ Laboratorio completado - Recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Visibilidad Centralizada:** La mayor ventaja de SCC es tener un único lugar para ver todos los problemas de seguridad de GCP, en lugar de tener que consultar múltiples consolas y servicios.
*   **De la Detección a la Acción:** SCC no solo te dice qué está mal, sino que a menudo te da los comandos exactos de `gcloud` para solucionarlo, acelerando la remediación.
*   **La Gestión de la Postura es Continua:** La seguridad no es un proyecto de una sola vez. Herramientas como Security Health Analytics monitorizan continuamente tu entorno, adaptándose a los cambios y a las nuevas amenazas.

---

## ⚠️ Errores y Confusiones Comunes

*   **Fatiga de Hallazgos:** Activar SCC puede generar miles de hallazgos al principio. Es crucial tener un proceso para priorizar (por severidad, por tipo de recurso) y silenciar (`mute`) los riesgos aceptados para no verse abrumado.
*   **Pensar que SCC lo Arregla Todo Automáticamente:** SCC es una herramienta de **detección y recomendación**. No remedia los problemas por sí solo. La remediación (manual o automatizada a través de scripts o Pub/Sub) es responsabilidad del usuario.
*   **Ignorar el Nivel de Organización:** SCC es más potente cuando se activa a nivel de organización, ya que proporciona una vista completa de todos los proyectos. Activarlo solo en un proyecto limita su visibilidad.

---

## 🎯 Tips de Examen

*   **SCC = Panel Único de Cristal:** Asocia SCC con la idea de una vista centralizada de seguridad.
*   **Conoce los Servicios Integrados:** Recuerda los nombres de los componentes clave: **Security Health Analytics** (malas configuraciones), **Event Threat Detection** (amenazas en logs), **Web Security Scanner** (vulnerabilidades web).
*   **Diferencia entre Tiers:** **Standard** es gratuito e incluye escaneo de malas configuraciones básicas. **Premium** es de pago y añade detección de amenazas avanzada (Event/Container Threat Detection) y escaneo de cumplimiento normativo.
*   **Concepto de `Finding`:** Un `finding` es el registro de un problema de seguridad. Es la unidad de trabajo fundamental en SCC.

---

## 🧾 Resumen

Security Command Center es el centro neurálgico de la seguridad en Google Cloud. Al agregar, priorizar y gestionar hallazgos de seguridad de toda tu organización, te permite pasar de un enfoque reactivo a uno proactivo en la gestión de riesgos. Proporciona la visibilidad y la inteligencia necesarias para identificar y remediar vulnerabilidades, detectar amenazas y mantener una postura de seguridad robusta en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-security-command-center-scc-tu-panel-único-de-seguridad)
