# 🚀 Compute Engine (IaaS)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-compute-engine-iaas)

---

## 🧭 Descripción

Compute Engine (GCE) es el servicio de Infraestructura como Servicio (IaaS) de Google Cloud. Te permite crear y ejecutar máquinas virtuales (VMs) en la infraestructura global de Google. GCE es tu "lienzo en blanco": te da el máximo control sobre el sistema operativo, la configuración de red y el hardware subyacente, permitiéndote levantar prácticamente cualquier carga de trabajo, desde un simple servidor web hasta un complejo sistema de computación de alto rendimiento.

---

## 📘 Detalles

### Componentes Clave de una VM en GCE

1.  **Familias de Máquinas (Machine Families):** GCE ofrece una amplia gama de tipos de máquinas optimizadas para diferentes cargas de trabajo:
    *   **E2:** Propósito general, coste optimizado.
    *   **N2, N2D:** Propósito general, rendimiento equilibrado.
    *   **C3, C2D:** Optimizadas para cómputo, altas frecuencias de CPU.
    *   **M2, M3:** Optimizadas para memoria, para bases de datos en memoria como SAP HANA.
    *   **A2, G2:** Optimizadas para aceleradores, con GPUs para machine learning y cargas de trabajo gráficas.

2.  **Imágenes (Images):** Una imagen es un disco de arranque que contiene un sistema operativo. Puedes usar:
    *   **Imágenes Públicas:** Proporcionadas y mantenidas por Google (Debian, Ubuntu, Windows Server, etc.).
    *   **Imágenes Personalizadas:** Imágenes que creas tú mismo a partir de tus propios discos o VMs.

3.  **Discos Persistentes (Persistent Disks):** Son el almacenamiento en bloque para tus VMs. Son recursos de red, lo que significa que se pueden desacoplar de una VM y acoplar a otra. Vienen en diferentes sabores (Estándar, Balanceado, SSD) para distintas necesidades de rendimiento (IOPS).

4.  **Ciclo de Vida de la Instancia:** Las VMs pueden estar en varios estados: `PROVISIONING`, `STAGING`, `RUNNING`, `STOPPING`, `TERMINATED`. Es importante entender que una VM `TERMINATED` (detenida) no incurre en costes de CPU o memoria, pero **sí se te sigue cobrando por el almacenamiento de sus discos persistentes**.

5.  **VMs Interrumpibles (Spot VMs):** Son VMs que puedes obtener con un descuento de hasta el 91%, pero Google puede detenerlas (interrumpirlas) en cualquier momento si necesita los recursos. Son ideales para cargas de trabajo tolerantes a fallos y sin estado, como jobs de procesamiento por lotes.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear una VM, añadirle un disco y redimensionarla
**Contexto:** Crearemos una VM, pero nos daremos cuenta de que necesitamos más espacio de almacenamiento y más potencia de cómputo. Adjuntaremos un nuevo disco persistente y redimensionaremos la VM sin tener que recrearla.

#### ARRANGE (Preparación del laboratorio)
```bash
# Variables
export PROJECT_ID=$(gcloud config get-value project)
export ZONE="europe-west1-b"
export VM_NAME="core-application-server"
export DISK_NAME="extra-data-disk"

# Crear la VM inicial
gcloud compute instances create $VM_NAME --zone=$ZONE --machine-type=e2-small

# Crear un disco persistente adicional
gcloud compute disks create $DISK_NAME --zone=$ZONE --size=20GB
```

#### ACT (Implementación del escenario)
*Primero, adjuntamos el disco extra a nuestra VM. Luego, detenemos la VM para poder cambiar su tipo de máquina y la volvemos a iniciar.*
```bash
# 1. Adjuntar el disco a la VM
echo "\n=== Adjuntando disco adicional... ==="
gcloud compute instances attach-disk $VM_NAME --zone=$ZONE --disk=$DISK_NAME

# 2. Detener la VM para poder redimensionarla
echo "\n=== Deteniendo la VM... ==="
gcloud compute instances stop $VM_NAME --zone=$ZONE

# 3. Redimensionar la VM (cambiar el tipo de máquina)
echo "\n=== Redimensionando la VM a e2-medium... ==="
gcloud compute instances set-machine-type $VM_NAME --zone=$ZONE --machine-type=e2-medium

# 4. Iniciar la VM de nuevo
echo "\n=== Iniciando la VM redimensionada... ==="
gcloud compute instances start $VM_NAME --zone=$ZONE
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la VM está corriendo, que tiene el nuevo tipo de máquina y que tiene el disco adicional adjunto.*
```bash
# Describir la VM y verificar sus propiedades
echo "\n=== Verificando la configuración final de la VM... ==="
gcloud compute instances describe $VM_NAME --zone=$ZONE --format="yaml(machineType, disks)"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la VM (esto no elimina el disco que creamos por separado)
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud compute instances delete $VM_NAME --zone=$ZONE --quiet

# Eliminar el disco persistente
gcloud compute disks delete $DISK_NAME --zone=$ZONE --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Desacopla el cómputo del almacenamiento:** El uso de Discos Persistentes te permite gestionar el ciclo de vida de tus datos de forma independiente al de tus VMs.
*   **Elige la máquina correcta:** No pagues de más. Analiza tu carga de trabajo y elige la familia de máquinas que mejor se adapte. Empieza pequeño y redimensiona si es necesario.
*   **Usa Spot VMs para ahorrar:** Para cargas de trabajo no críticas y por lotes, las Spot VMs pueden reducir tus costes drásticamente.

---

## ⚠️ Errores y Confusiones Comunes

*   **Olvidar borrar los discos:** Eliminar una VM no elimina automáticamente los discos persistentes que creaste y adjuntaste por separado. Siguen generando costos.
*   **Usar la Cuenta de Servicio por defecto:** La SA por defecto de Compute Engine tiene el rol de Editor, que es demasiado permisivo. Siempre crea y asigna una SA específica con los mínimos permisos necesarios.
*   **No usar grupos de instancias para la escalabilidad:** Crear VMs individuales no es una práctica escalable. Para ello, se deben usar Grupos de Instancias (Instance Groups), que permiten el autoescalado y la autoreparación.

---

## 🎯 Tips de Examen

*   **Discos Persistentes son recursos de red:** El examen puede preguntar cómo mover datos entre VMs. La respuesta suele ser desacoplar un disco de una VM y acoplarlo a otra.
*   **VMs Interrumpibles (Spot VMs):** Si un escenario describe una carga de trabajo tolerante a fallos y sensible al coste (como análisis de datos por lotes), Spot VM es la respuesta correcta.
*   **Redimensionar una VM:** Recuerda que para cambiar el tipo de máquina, la VM debe estar en estado `TERMINATED` (detenida).

---

## 🧾 Resumen

Compute Engine es la base del IaaS en Google Cloud, ofreciendo un control granular sin precedentes sobre tus máquinas virtuales. A través de una rica selección de familias de máquinas, un sistema de almacenamiento en disco flexible y potentes opciones de configuración, GCE te permite construir la infraestructura exacta que tu aplicación necesita, desde la VM más pequeña hasta el superordenador más potente.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-compute-engine-iaas)
