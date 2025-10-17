# 🌎 Regiones y Zonas

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

La infraestructura global de Google Cloud es la base física sobre la que se ejecutan todos sus servicios. Comprender su estructura es fundamental para diseñar aplicaciones resilientes, de baja latencia y que cumplan con la normativa. Los dos conceptos más importantes de esta jerarquía son las **Regiones** y las **Zonas**.

Este capítulo desglosa qué son, cómo se relacionan y por qué la elección de dónde despliegas tus recursos tiene un impacto directo en la disponibilidad, el rendimiento y el costo.

---

## 📘 Detalles

La infraestructura de Google está organizada en una jerarquía que va de lo global a lo local.

### 🔹 Regiones

Una **Región** es un área geográfica independiente donde Google mantiene centros de datos. Piensa en una región como un área metropolitana específica (ej. `europe-west1` en Bélgica, `us-central1` en Iowa, `asia-northeast1` en Tokio).

*   **Independencia:** Cada región está diseñada para ser completamente independiente de las demás en términos de energía, refrigeración y red.
*   **Baja Latencia:** El objetivo principal de tener múltiples regiones es permitirte desplegar tus aplicaciones cerca de tus usuarios para minimizar la latencia de red.
*   **Soberanía de Datos:** Algunas regulaciones exigen que los datos de los usuarios residan físicamente en un país o área geográfica específica. Las regiones ayudan a cumplir estos requisitos.

### 🔹 Zonas

Una **Zona** es un área de despliegue para recursos de Google Cloud *dentro* de una región. Cada zona representa un dominio de fallo aislado.

*   **Dominio de Fallo:** Una zona es un centro de datos (o un grupo de ellos) con su propia infraestructura de energía, refrigeración y red, físicamente separada de las otras zonas en la misma región. Un incendio, una inundación o un fallo de red en una zona no debería afectar a las demás.
*   **Alta Disponibilidad (HA):** Para construir una aplicación tolerante a fallos, la práctica estándar es desplegar los recursos en *múltiples zonas* dentro de una misma región.
*   **Conectividad:** Las zonas dentro de una misma región están conectadas por una red de muy alta velocidad y baja latencia (menos de 1ms), lo que permite una comunicación casi instantánea entre ellas.

### 🔹 Tipos de Recursos: Zonales, Regionales y Multiregionales

No todos los recursos de GCP son iguales. Su alcance determina su dominio de fallo:

*   **Recursos Zonales:** Viven en una única zona. Si esa zona falla, el recurso deja de estar disponible. 
    *   *Ejemplos:* Máquinas virtuales de Compute Engine, Discos Persistentes (Persistent Disks), Nodos de GKE.
*   **Recursos Regionales:** Se replican automáticamente a través de múltiples zonas dentro de una región. Son resilientes a un fallo zonal.
    *   *Ejemplos:* Instancias de Cloud SQL (en modo HA), Subredes de VPC, Grupos de Instancias Administrados (MIGs) regionales.
*   **Recursos Multiregionales y Globales:** Proporcionan redundancia a través de múltiples regiones o están disponibles globalmente.
    *   *Ejemplos:* Buckets multiregionales de Cloud Storage, Cloud Spanner, Balanceadores de Carga Externos, Proyectos de GCP, Redes VPC.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Exploraremos las regiones y zonas disponibles usando `gcloud` y desplegaremos un recurso zonal para verificar su ubicación.

### ARRANGE (Preparación)

```bash
# Variables del proyecto y configuración
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1" # Bélgica
export ZONE="europe-west1-b"

gcloud config set project $PROJECT_ID

# Habilitar API de Compute Engine
gcloud services enable compute.googleapis.com
```

### ACT (Implementación)

```bash
# 1. Listar todas las regiones disponibles
echo "=== REGIONES DISPONIBLES ==="
gcloud compute regions list --format="table(name,description)"

# 2. Listar todas las zonas dentro de nuestra región seleccionada
echo "
=== ZONAS EN $REGION ==="
gcloud compute zones list --filter="region=$REGION" --format="table(name)"

# 3. Crear un recurso zonal (una VM) en una zona específica
echo "
Creando instancia 'demo-zonal' en la zona $ZONE..."
gcloud compute instances create demo-zonal \
    --machine-type=e2-micro \
    --zone=$ZONE
```

### ASSERT (Verificación)

```bash
# Verificar que la instancia se ha creado en la zona correcta
echo "
=== VERIFICANDO UBICACIÓN DE LA INSTANCIA ==="
INSTANCE_LOCATION=$(gcloud compute instances describe demo-zonal --zone=$ZONE --format='value(zone)')

# El path completo de la zona es https://www.googleapis.com/compute/v1/projects/PROJECT/zones/ZONE
# Extraemos solo el nombre de la zona para la comparación
if [[ "$INSTANCE_LOCATION" == *"/"$ZONE ]]; then
    echo "✅ Verificación exitosa: La instancia está en la zona $ZONE."
else
    echo "❌ Verificación fallida: La instancia NO está en la zona esperada. Ubicación: $INSTANCE_LOCATION"
fi
```

### CLEANUP (Limpieza)

```bash
echo "
⚠️  Eliminando recursos de laboratorio..."
gcloud compute instances delete demo-zonal --zone=$ZONE --quiet

echo "✅ Laboratorio completado - Recursos eliminados"
```

---

## 💡 Lecciones Aprendidas

*   **La Alta Disponibilidad empieza con múltiples zonas:** Para que tu aplicación sobreviva a un fallo de un centro de datos, debes distribuir tus VMs o servicios en al menos dos zonas dentro de una región.
*   **La Recuperación ante Desastres implica múltiples regiones:** Para sobrevivir a un desastre a gran escala (ej. un terremoto que afecte a toda una región), necesitas una estrategia de despliegue multirregional.
*   **El tipo de recurso define su resiliencia:** No todos los servicios son iguales. Debes entender si un servicio es zonal, regional o multirregional para diseñar correctamente tu arquitectura.

---

## ⚠️ Errores y Confusiones Comunes

*   **Desplegar todo en una sola zona:** Es el error más común de los principiantes. Crea un único punto de fallo que anula las ventajas de la nube.
*   **Intentar adjuntar un disco de una zona a una VM de otra:** Los Discos Persistentes son recursos zonales. Solo pueden ser adjuntados a VMs que se encuentren en la misma zona.
*   **Confundir Región con País:** Una región es un área metropolitana específica dentro de un país, no el país entero. Por ejemplo, España tiene la región `europe-southwest1` (Madrid), pero no todo el país es una región.

---

## 🎯 Tips de Examen

*   Memoriza la jerarquía: **Global ➡️ Multi-Región ➡️ Región ➡️ Zona**.
*   Conoce ejemplos clave de recursos y su alcance: **Zonal** (VMs, Discos), **Regional** (Cloud SQL, Subredes VPC), **Global** (Proyectos, Redes VPC, Balanceadores Externos).
*   Asocia **Alta Disponibilidad (HA)** con el uso de múltiples **zonas**. Asocia **Recuperación ante Desastres (DR)** con el uso de múltiples **regiones**.
*   Recuerda que una región siempre tiene **3 o más** zonas.

---

## 🧾 Resumen

La infraestructura global de Google, organizada en regiones y zonas, es el pilar para construir aplicaciones fiables y de alto rendimiento. Las regiones te acercan a tus usuarios y te ayudan a cumplir con la soberanía de datos, mientras que las zonas te protegen contra fallos de infraestructura. Entender y utilizar correctamente esta jerarquía es el primer paso para diseñar arquitecturas robustas en GCP.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-regiones-y-zonas)