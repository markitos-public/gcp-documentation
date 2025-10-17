# ☁️ La Computación en la Nube

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-la-computación-en-la-nube)

---

## 🧭 Descripción

Antes de crear recursos en Google Cloud, es fundamental entender qué es realmente “la nube”. No se trata solo de "ordenadores de otra persona", sino de un modelo operativo completo. En este capítulo exploramos su definición oficial según el NIST, sus características clave y veremos —en la práctica— cómo esos conceptos se reflejan en GCP con `gcloud CLI`.

---

## 📘 Detalles

La definición oficial del **NIST (National Institute of Standards and Technology)** es un poco densa. Dice que la computación en la nube es un modelo para habilitar un acceso de red ubicuo, conveniente y bajo demanda a un conjunto compartido de recursos informáticos configurables... que se pueden aprovisionar y liberar rápidamente con un mínimo esfuerzo de gestión.

Traducción: Piensa en GCP no como un conjunto de servidores, sino como una **máquina expendedora gigante de servicios digitales**. Este modelo de "máquina expendedora" funciona porque sigue 5 reglas esenciales definidas por el NIST. Veamos cuáles son y cómo GCP las cumple.

### 1. Autoservicio Bajo Demanda (On-Demand Self-Service)
*   **Analogía:** Es como ir a un cajero automático. No necesitas hablar con un empleado del banco para sacar dinero. Tú mismo lo haces, cuando quieres.
*   **Explicación:** Puedes provisionar recursos (como máquinas virtuales o bases de datos) por tu cuenta, a través de una consola web o una línea de comandos, sin tener que llamar a un comercial de Google o levantar un ticket.
*   **En GCP:** Usas la Consola de Google Cloud, la CLI de `gcloud` o las APIs para crear, modificar y eliminar recursos al instante.
*   **Demostración Práctica:**
    ```bash
    # ¿Quieres una máquina virtual? La pides y la tienes en segundos.
    # Esto es autoservicio puro.
    gcloud compute instances create "mi-vm-automatica" --project=$PROJECT_ID --zone=europe-southwest1-a --machine-type=e2-micro --image-family=debian-12 --image-project=debian-cloud
    ```

### 2. Acceso Amplio a la Red (Broad Network Access)
*   **Analogía:** Es como poder acceder a tu email desde tu portátil, tu teléfono o una tablet. Mientras tengas internet, tienes acceso.
*   **Explicación:** Los servicios de la nube están disponibles a través de la red (generalmente internet) y se pueden acceder con cualquier dispositivo estándar (un navegador web, un smartphone, etc.).
*   **En GCP:** Puedes gestionar tus recursos de GCP desde tu portátil en casa, tu móvil en el autobús, o un servidor en otro país, usando HTTPS, SSH, o las APIs. La red global de Google lo hace posible.
*   **Demostración Práctica:**
    ```bash
    # Puedes conectarte a tu VM desde cualquier terminal con gcloud.
    # No importa dónde estés físicamente.
    gcloud compute ssh "mi-vm-automatica" --project=$PROJECT_ID --zone=europe-southwest1-a --command="echo 'Hola desde la nube'"
    ```

### 3. Agrupación de Recursos (Resource Pooling)
*   **Analogía:** Es como vivir en un edificio de apartamentos. El edificio tiene una única instalación de agua y electricidad que se comparte entre todos los inquilinos. No sabes (ni te importa) qué tubería exacta te trae el agua, solo que cuando abres el grifo, sale agua.
*   **Explicación:** El proveedor (Google) agrupa sus recursos físicos (servidores, discos, redes) y los sirve a múltiples clientes (modelo *multi-tenant*). Los recursos se asignan y reasignan dinámicamente según la demanda. Como cliente, no sabes en qué servidor físico exacto se está ejecutando tu máquina virtual.
*   **En GCP:** Cuando creas una VM, GCP la coloca en uno de sus servidores físicos en la zona que elegiste. Si otro cliente libera recursos, GCP puede usar ese espacio para tu VM. Servicios como Cloud Run o Cloud Functions llevan esto al extremo, donde ni siquiera gestionas un servidor.
*   **Demostración Práctica:**
    ```bash
    # Al listar las VMs, ves tu recurso lógico.
    # GCP gestiona el hardware físico por debajo, agrupando recursos para miles de clientes.
    gcloud compute instances list --project=$PROJECT_ID --filter="name=(mi-vm-automatica)"
    ```

### 4. Elasticidad Rápida (Rapid Elasticity)
*   **Analogía:** Es como un cinturón elástico. Se ajusta automáticamente si ganas o pierdes peso.
*   **Explicación:** Puedes obtener más recursos cuando los necesitas (escalar hacia afuera) y liberarlos cuando ya no los necesitas (escalar hacia adentro). A menudo, esto se puede hacer de forma automática. Desde tu perspectiva, los recursos parecen ilimitados.
*   **En GCP:** Un `Managed Instance Group` (MIG) puede añadir o quitar VMs automáticamente basándose en la carga de la CPU. Un bucket de Cloud Storage puede crecer de gigabytes a petabytes sin que tengas que hacer nada.
*   **Demostración Práctica:**
    ```bash
    # Este comando redimensiona una VM existente. ¡Elasticidad manual!
    # Podríamos pasar de una e2-micro a una e2-medium en minutos.
    gcloud compute instances set-machine-type "mi-vm-automatica" --project=$PROJECT_ID --zone=europe-southwest1-a --machine-type=e2-medium
    ```

### 5. Servicio Medido (Measured Service)
*   **Analogía:** Es como el contador de la luz de tu casa. La compañía eléctrica mide exactamente cuánta electricidad consumes y te cobra solo por esa cantidad.
*   **Explicación:** El uso de recursos se mide, controla y reporta de forma transparente. Pagas por lo que usas (*Pay-As-You-Go*). Esto se aplica a todo: tiempo de cómputo, almacenamiento, tráfico de red, etc.
*   **En GCP:** La sección de `Billing` (Facturación) en la consola de GCP te da un desglose detallado de tus costos, a menudo por recurso y por segundo de uso. Puedes establecer presupuestos y alertas para controlar el gasto.
*   **Demostración Práctica:**
    ```bash
    # Al eliminar un recurso, el "contador" se detiene y dejas de pagar por él instantáneamente.
    # Esto es la base del servicio medido.
    gcloud compute instances delete "mi-vm-automatica" --project=$PROJECT_ID --zone=europe-southwest1-a --quiet
    ```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Creación y eliminación de una máquina virtual
**Contexto:** Este laboratorio demuestra los principios de autoservicio bajo demanda, elasticidad y servicio medido. Crearemos una pequeña máquina virtual, verificaremos su estado y luego la eliminaremos.

#### ARRANGE (Preparación del laboratorio)
*Habilitamos la API de Compute Engine, que es necesaria para crear y gestionar VMs.*
```bash
# Habilitar API de Compute Engine
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export ZONE="europe-southwest1-a"
export VM_NAME="demo-vm-on-demand"
```

#### ACT (Implementación del escenario)
*Creamos la instancia de máquina virtual. Usamos `gcloud compute instances create` y especificamos el tipo de máquina y la imagen de disco.*
```bash
# gcloud compute instances create: Comando para crear una nueva máquina virtual.
# $VM_NAME: (Requerido) El nombre que le daremos a nuestra VM.
# --project: (Opcional si ya está configurado) Especifica el ID del proyecto.
# --zone: (Requerido) La zona de disponibilidad donde se creará la VM.
# --machine-type: (Opcional) El tipo de máquina (CPU/RAM). 'e2-micro' es de las más pequeñas.
# --image-family y --image-project: (Requerido) Especifican el sistema operativo a instalar.
gcloud compute instances create $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la instancia se ha creado y está en estado `RUNNING`.*
```bash
# Verificar que la instancia existe y está corriendo
echo "=== Verificando estado de la VM... ==="
gcloud compute instances list --project=$PROJECT_ID --filter="name=($VM_NAME)" --format="table(name,zone,status)"
```

#### CLEANUP (Limpieza de recursos)
*Eliminamos la instancia para dejar de incurrir en costos. Esto demuestra el principio de "servicio medido".*
```bash
# Eliminar la instancia de VM
echo "=== Eliminando la VM de laboratorio... ==="
gcloud compute instances delete $VM_NAME --project=$PROJECT_ID --zone=$ZONE --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **La nube es un modelo, no un lugar:** Se define por sus 5 características operativas, no por la ubicación física de los servidores.
*   **Automatización es la clave:** El autoservicio y la elasticidad son posibles gracias a la automatización. `gcloud CLI` es tu principal herramienta para ello.
*   **Pagas por lo que usas:** El modelo de servicio medido es fundamental. Si no lo necesitas, lo apagas. Si lo apagas, dejas de pagar.

---

## ⚠️ Errores y Confusiones Comunes

*   **Confundir Virtualización con Nube:** Tener máquinas virtuales no es "tener una nube". La nube requiere el componente de autoservicio, elasticidad y medición.
*   **Olvidar el `CLEANUP`:** Dejar recursos activos después de un laboratorio es el error más común y puede generar facturas inesperadas.
*   **Ignorar Regiones y Zonas:** Asumir que todos los servicios están en todas partes. La ubicación de los recursos es una decisión de diseño fundamental.

---

## 🎯 Tips de Examen

*   **Memoriza las 5 características del NIST:** "On-demand self-service", "Broad network access", "Resource pooling", "Rapid elasticity", "Measured service". Son preguntas frecuentes.
*   **Asocia IaaS con `gcloud compute instances create`:** La capacidad de crear una VM desde cero es el ejemplo perfecto de Infraestructura como Servicio (IaaS).
*   **Entiende la diferencia entre Región y Zona:** Una región es un área geográfica (ej. Madrid), una zona es un centro de datos aislado dentro de esa región. Las regiones contienen zonas.

---

## 🧾 Resumen

La computación en la nube es un modelo operativo que ofrece recursos de TI de forma flexible, escalable y bajo demanda. Comprender sus cinco características fundamentales (autoservicio, acceso por red, pool de recursos, elasticidad y servicio medido) es el primer paso para dominar cualquier plataforma cloud como GCP.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-la-computación-en-la-nube)