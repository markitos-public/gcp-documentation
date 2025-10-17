# ☁️ Artifact Analysis: Escaneo de Vulnerabilidades y Metadatos

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

**Artifact Analysis** es un servicio de Google Cloud que proporciona escaneo de vulnerabilidades y gestión de metadatos para artefactos de software, principalmente imágenes de contenedor almacenadas en Artifact Registry o Container Registry. Su función es identificar vulnerabilidades conocidas en paquetes del sistema operativo y lenguajes de programación (Go, Java, Node.js, Python), y actuar como un repositorio central para metadatos sobre los artefactos, como información de compilación, resultados de pruebas o atestaciones de Binary Authorization. Resuelve el problema de la visibilidad de la seguridad dentro de la cadena de suministro de software.

---

## 📘 Detalles

Artifact Analysis funciona de manera automática o bajo demanda, integrándose estrechamente con los registros de contenedores de GCP.

### 🔹 Escaneo de Vulnerabilidades

1.  **Activación:** Se puede habilitar el escaneo automático en Artifact Registry. Cuando una nueva imagen es subida (`push`), Artifact Analysis la escanea automáticamente.
2.  **Fuentes de Datos:** Utiliza bases de datos de vulnerabilidades y exposiciones comunes (CVEs) para los paquetes del sistema operativo (Debian, Ubuntu, CentOS, etc.) y para dependencias de aplicaciones.
3.  **Resultados:** Los resultados, llamados "ocurrencias" (`occurrences`) de tipo `VULNERABILITY`, se almacenan en Artifact Analysis. Cada ocurrencia detalla la vulnerabilidad encontrada, su severidad (CVSS score), el paquete afectado y, si está disponible, las versiones que corrigen el problema.
4.  **Tipos de Escaneo:**
    *   **Escaneo al subir:** Se realiza automáticamente en imágenes nuevas.
    *   **Escaneo continuo:** Artifact Analysis monitorea continuamente las imágenes ya escaneadas. Si se descubre una nueva vulnerabilidad en una base de datos que afecta a una imagen existente, se crea una nueva ocurrencia.

### 🔹 Gestión de Metadatos (Ocurrencias y Notas)

Artifact Analysis utiliza un modelo de **Notas** y **Ocurrencias** para almacenar metadatos:

*   **Nota (Note):** Es una descripción de alto nivel de un tipo de metadato, creada por una "autoridad" (un proyecto de GCP). Por ejemplo, una `Note` podría definir qué es una "vulnerabilidad de paquete" o qué significa una "atestación de QA". Las notas son plantillas.
*   **Ocurrencia (Occurrence):** Es una instanciación de una `Note` para un artefacto específico. Por ejemplo, una ocurrencia de vulnerabilidad vincula una `Note` de vulnerabilidad específica con el `digest` de una imagen de contenedor, indicando que *esa* imagen tiene *esa* vulnerabilidad.

Este modelo permite almacenar cualquier tipo de metadato estructurado, como:
*   **`VULNERABILITY`**: Resultados del escáner.
*   **`BUILD_DETAILS`**: Información sobre cómo se construyó el artefacto (proveniente de Cloud Build).
*   **`ATTESTATION`**: Atestaciones firmadas por Binary Authorization.
*   **`DEPLOYMENT`**: Registros de dónde y cuándo se ha desplegado un artefacto.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio muestra cómo subir una imagen a Artifact Registry, ver los resultados del escaneo de vulnerabilidades y consultar las ocurrencias.

### ARRANGE (Preparación)

```bash
# 1. Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export REPO_NAME="app-images"
export IMAGE_NAME="vulnerable-app"
export IMAGE_TAG="1.0"

# 2. Habilitar las APIs necesarias
gcloud services enable \
    artifactregistry.googleapis.com \
    containeranalysis.googleapis.com

# 3. Crear un repositorio de Artifact Registry
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Application images repository"

# 4. Configurar la autenticación de Docker
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# 5. Crear una imagen de contenedor vulnerable de ejemplo
# Usaremos una imagen pública conocida por tener vulnerabilidades para este ejemplo.
# En un caso real, aquí construirías tu propia imagen.
# Tiramos de una imagen base antigua de Debian.
cat > Dockerfile <<EOF
FROM debian:9
RUN apt-get update && apt-get install -y curl
CMD ["echo", "Hello, I am a vulnerable image!"]
EOF

export IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t $IMAGE_URI .
```

### ACT (Implementación)

```bash
# 1. Subir la imagen a Artifact Registry
# Esto activará automáticamente el escaneo de vulnerabilidades.
docker push $IMAGE_URI

# 2. Esperar a que el escaneo se complete
# El escaneo puede tardar unos minutos. Podemos listar las ocurrencias para ver el progreso.
# Primero, obtenemos el digest de la imagen subida.
export IMAGE_DIGEST=$(gcloud container images describe $IMAGE_URI --format='get(image_summary.digest)')
export RESOURCE_URL="https://${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}@${IMAGE_DIGEST}"

echo "Esperando a que aparezcan los resultados del escaneo para $RESOURCE_URL..."
# Bucle simple para esperar a que las ocurrencias de vulnerabilidad estén disponibles.
for i in {1..10}; do 
    VULNS=$(gcloud container images list-vulnerabilities --resource-url=$RESOURCE_URL --format='value(vulnerability.severity)'); 
    if [ -n "$VULNS" ]; then 
        echo "¡Resultados encontrados!"; 
        break; 
    fi; 
    echo "Intento $i: Aún no hay resultados, esperando 15 segundos..."; 
    sleep 15;
done
```

### ASSERT (Verificación)

```bash
# 1. Listar las vulnerabilidades encontradas para la imagen
# Este comando muestra un resumen de las vulnerabilidades encontradas.
gcloud container images list-vulnerabilities --resource-url=$RESOURCE_URL

# 2. Filtrar por vulnerabilidades de severidad CRITICAL
# Podemos usar el filtro para enfocarnos en los problemas más graves.
gcloud container images list-vulnerabilities --resource-url=$RESOURCE_URL --filter="vulnerability.severity=CRITICAL"

# 3. Describir una vulnerabilidad específica para obtener más detalles
# Primero, obtenemos el ID de una vulnerabilidad CRITICAL.
export ANY_CRITICAL_VULN=$(gcloud container images list-vulnerabilities --resource-url=$RESOURCE_URL --filter="vulnerability.severity=CRITICAL" --limit=1 --format="value(vulnerability.vulnerability)")

# Luego, usamos el ID para obtener la ocurrencia completa.
gcloud alpha container vulnerability-occurrences describe $ANY_CRITICAL_VULN --project=$PROJECT_ID

# 4. Listar todas las ocurrencias (no solo vulnerabilidades) para la imagen
# Esto muestra todos los metadatos asociados, como detalles de build, etc.
gcloud container occurrences list --resource-url=$RESOURCE_URL
```

### CLEANUP (Limpieza)

```bash
# Eliminar la imagen de Artifact Registry
gcloud artifacts docker images delete $IMAGE_URI --delete-tags --quiet

# Eliminar el repositorio de Artifact Registry
gcloud artifacts repositories delete $REPO_NAME --location=$REGION --quiet

# Eliminar el archivo Dockerfile local
rm Dockerfile
```

---

## 💡 Lecciones Aprendidas

*   **La Visibilidad es el Primer Paso:** No puedes protegerte contra lo que no puedes ver. Artifact Analysis proporciona la visibilidad esencial sobre las dependencias y vulnerabilidades ocultas en tus contenedores.
*   **Automatización como Clave de la Seguridad:** El escaneo automático al subir una imagen (`on-push`) y el escaneo continuo transforman la seguridad de un proceso manual y esporádico a uno automático e integrado en el ciclo de vida del software.
*   **Más Allá de las Vulnerabilidades:** Aunque el escaneo es su caso de uso más visible, el verdadero poder de Artifact Analysis es su capacidad para actuar como un almacén central de metadatos de seguridad (atestaciones, builds, etc.), permitiendo políticas de gobernanza complejas.

---

## ⚠️ Errores y Confusiones Comunes

*   **Error: No usar un `digest` de imagen:** Al consultar ocurrencias, siempre se debe usar la URL del recurso con el `digest` (`@sha256:...`), no con un `tag` (`:latest`). Los metadatos están vinculados al contenido inmutable de la imagen.
*   **Confusión: Artifact Analysis vs. Binary Authorization:** Artifact Analysis *encuentra* problemas (vulnerabilidades). Binary Authorization *impone* políticas basadas en si esos problemas (u otras verificaciones) han sido resueltos o aceptados (mediante atestaciones). Son dos caras de la misma moneda: visibilidad y control.
*   **Problema: Falsos Positivos o Vulnerabilidades No Arreglables:** A veces, el escáner reporta vulnerabilidades que no tienen una solución disponible (`fix not available`) o que no son explotables en el contexto de la aplicación. Esto requiere un proceso de triaje para decidir si aceptar el riesgo y crear una atestación de exención.

---

## 🎯 Tips de Examen

*   **Conoce los dos tipos de escaneo:** Al subir (`on-push`) y continuo. El escaneo continuo es clave para detectar nuevas vulnerabilidades en artefactos antiguos.
*   **Modelo de Metadatos:** Recuerda la diferencia entre `Note` (plantilla/tipo de metadato) y `Occurrence` (instancia de metadato para un artefacto específico).
*   **Integración:** Artifact Analysis es el backend de metadatos para servicios como **Binary Authorization** y **Security Command Center**. Los hallazgos de vulnerabilidades aparecen en SCC.
*   **Registros Soportados:** Funciona con Artifact Registry y Container Registry.

---

## 🧾 Resumen

Artifact Analysis es el servicio de observabilidad de la cadena de suministro de software en GCP. Proporciona escaneo automático de vulnerabilidades para imágenes de contenedor y un sistema flexible para almacenar y consultar metadatos críticos. Esta visibilidad es fundamental para tomar decisiones informadas y automatizar políticas de seguridad en el pipeline de CI/CD.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-artifact-analysis-escaneo-de-vulnerabilidades-y-metadatos)