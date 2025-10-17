
# 📜 002: Cloud Storage

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Conceptos Fundamentales](#conceptos-fundamentales)
3.  [Ubicaciones de Buckets](#ubicaciones-de-buckets)
4.  [Gestión del Ciclo de Vida de los Objetos (Object Lifecycle Management)](#gestión-del-ciclo-de-vida-de-los-objetos-object-lifecycle-management)
5.  [Seguridad y Control de Acceso](#seguridad-y-control-de-acceso)
6.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

**Cloud Storage** es el servicio de almacenamiento de objetos de Google Cloud. Es un servicio unificado que ofrece una durabilidad y disponibilidad líderes en la industria, diseñado para almacenar y recuperar cualquier cantidad de datos, en cualquier momento y desde cualquier lugar. Es la base para una multitud de casos de uso, incluyendo el hosting de sitios web estáticos, el almacenamiento de backups, la distribución de contenido multimedia y la creación de data lakes para análisis.

### Conceptos Fundamentales

*   **Objeto (Object):** Es la unidad de datos que almacenas. Un objeto consta de los datos del archivo en sí y sus metadatos (nombre, tamaño, tipo de contenido, etc.). Los objetos son **inmutables**: no puedes editar un objeto, solo puedes reemplazarlo por una nueva versión.

*   **Bucket:** Es un contenedor para tus objetos. Cada bucket tiene un nombre **globalmente único** (a través de todo GCP). Piensa en ellos como los contenedores de nivel superior.

*   **Jerarquía Plana:** Aunque puedes nombrar a tus objetos con barras (`/`) para simular una estructura de directorios (ej. `images/archive/photo.jpg`), Cloud Storage no tiene directorios reales. Es una ilusión para la organización; internamente, la estructura es plana.

### Ubicaciones de Buckets

La ubicación de un bucket es una decisión crítica que se toma en el momento de su creación y no se puede cambiar. Afecta a la latencia, la disponibilidad y el costo.

1.  **Regional:**
    *   **Concepto:** Los datos se almacenan de forma redundante en múltiples zonas dentro de una única región (ej. `us-central1`).
    *   **Caso de Uso:** Almacenar datos cerca de tus clústeres de Compute Engine o GKE para un rendimiento máximo. Ideal para análisis de datos y cargas de trabajo sensibles a la latencia.

2.  **Dual-region:**
    *   **Concepto:** Los datos se replican de forma redundante en dos regiones específicas.
    *   **Caso de Uso:** Alta disponibilidad y acceso de alto rendimiento para cargas de trabajo que se ejecutan en dos regiones. Ofrece un mejor SLA que una sola región.

3.  **Multi-region:**
    *   **Concepto:** Los datos se almacenan de forma geo-redundante en múltiples regiones dentro de un gran área geográfica (ej. `US`, `EU`, `ASIA`).
    *   **Caso de Uso:** Servir contenido a usuarios distribuidos globalmente (sitios web, streaming). Ofrece la máxima disponibilidad frente a desastres a nivel de región.

### Gestión del Ciclo de Vida de los Objetos (Object Lifecycle Management)

Esta es una potente herramienta de automatización de costos. Permite definir reglas que se aplican automáticamente a los objetos de un bucket.

*   **Reglas:** Se basan en condiciones como la edad del objeto, su clase de almacenamiento, si es una versión antigua, etc.
*   **Acciones:**
    *   **Cambiar la clase de almacenamiento:** Mueve automáticamente los objetos de una clase de acceso frecuente (Standard) a una de acceso infrecuente (Nearline, Coldline, Archive) a medida que envejecen. (Ej. `SetStorageClass` a `Nearline` después de 30 días).
    *   **Eliminar:** Borra objetos automáticamente después de un cierto período. (Ej. `Delete` objetos con más de 365 días de antigüedad).

### Seguridad y Control de Acceso

*   **IAM (Identity and Access Management):** Es el método de control de acceso principal y recomendado. Los permisos (roles) se pueden aplicar a nivel de proyecto, de bucket o incluso a objetos individuales.
    *   Roles comunes: `roles/storage.objectViewer` (leer objetos), `roles/storage.objectCreator` (crear objetos), `roles/storage.objectAdmin` (control total sobre objetos).

*   **Acceso Público Uniforme (Uniform Bucket-Level Access):** Es una configuración de seguridad recomendada que deshabilita las ACLs (Access Control Lists) heredadas y garantiza que solo IAM controle el acceso. Simplifica enormemente la gestión de permisos y previene exposiciones accidentales.

*   **URLs Firmadas (Signed URLs):** Proporcionan acceso de tiempo limitado a un objeto específico a través de una URL única y firmada criptográficamente. Ideal para permitir que un usuario descargue un archivo privado sin darle permisos de IAM permanentes.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear un bucket, subir un archivo y luego aplicar una regla de ciclo de vida.

```bash
# El nombre del bucket debe ser globalmente único. Usa tu ID de proyecto.
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="my-unique-bucket-$PROJECT_ID"

# 1. Crear un bucket regional
gsutil mb -l US-CENTRAL1 gs://$BUCKET_NAME

# 2. Crear un archivo de prueba y subirlo
echo "Hola Cloud Storage" > sample.txt
gsutil cp sample.txt gs://$BUCKET_NAME

# 3. Crear una regla de ciclo de vida (lifecycle.json)
cat > lifecycle.json << EOL
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 365}
    }
  ]
}
EOL

# 4. Aplicar la regla al bucket
gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME

# 5. Test (Verificación): Comprobar la configuración del ciclo de vida
gsutil lifecycle get gs://$BUCKET_NAME
# Esperado: Debería devolver la configuración JSON que acabamos de aplicar.
```

### 💡 Tips de Examen

*   **Nombre de Bucket:** Recuerda que los nombres de bucket son **globalmente únicos**.
*   **Inmutabilidad:** Los objetos son inmutables. Una "actualización" es en realidad una operación de `subir-y-reemplazar`.
*   **Ubicación:** Si la pregunta habla de **baja latencia** para cómputo en la misma región, la respuesta es una ubicación **Regional**. Si habla de **servir contenido a nivel mundial** o de **máxima disponibilidad**, es **Multi-regional**.
*   **Optimización de costos:** Si se menciona el ahorro de costos para datos a los que no se accede con frecuencia, la respuesta es **Object Lifecycle Management** para cambiar la clase de almacenamiento.

### ✍️ Resumen

Cloud Storage es la navaja suiza del almacenamiento en GCP. Su escalabilidad, durabilidad y modelo de precios de pago por uso lo convierten en la opción ideal para una amplia gama de datos no estructurados. La correcta elección de la ubicación del bucket y el uso de políticas de ciclo de vida son fundamentales para optimizar tanto el rendimiento como los costos. La seguridad se gestiona de forma preferente a través de IAM, con el Acceso Público Uniforme como mejor práctica.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-002-cloud-storage)
