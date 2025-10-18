# ☁️ Virtual Private Cloud (VPC) Networking

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-virtual-private-cloud-vpc-networking)

---

## 🧭 Descripción

Una Virtual Private Cloud (VPC) es tu propia porción privada y aislada de la red de Google. Es una red virtual global que proporciona conectividad a tus recursos de Compute Engine, Google Kubernetes Engine (GKE) y otros servicios. La VPC es el pilar fundamental sobre el que se construye la seguridad y la comunicación de red de toda tu infraestructura en GCP.

---

## 📘 Detalles

Las VPC de Google Cloud tienen características únicas:

1.  **Son Globales:** A diferencia de otros proveedores, una VPC en GCP es un recurso global. No está atada a una región específica. Dentro de esta VPC global, puedes crear subredes (`subnets`) en diferentes regiones.

2.  **Subredes (Subnets):** Cada subred es un recurso regional y tiene un rango de direcciones IP definido. Los recursos de GCP, como las VMs, se lanzan *dentro* de una subred y obtienen una dirección IP de su rango.

3.  **Modos de VPC:**
    *   **Modo Automático (Auto Mode):** Al crear un proyecto, se te proporciona una VPC `default` en modo automático. Esta VPC crea automáticamente una subred en cada región de GCP. Es conveniente para empezar, pero no se recomienda para producción.
    *   **Modo Personalizado (Custom Mode):** Te da control total. Creas una VPC sin subredes y luego añades manualmente las subredes que necesites en las regiones que elijas, con los rangos IP que tú definas. Es la práctica recomendada para producción.

4.  **Reglas de Firewall:** Las VPCs vienen con un firewall distribuido que puedes configurar para permitir o denegar tráfico hacia y desde tus VMs. Las reglas se aplican a nivel de VPC y pueden ser tan granulares como necesites.

```bash
# Ejemplo ilustrativo: Listar las redes VPC en tu proyecto.
# Por defecto, verás la red 'default' creada en modo automático.
gcloud compute networks list

# Ejemplo ilustrativo: Listar las subredes de la red 'default'.
# Verás una subred por cada región de GCP.
gcloud compute networks subnets list --network=default
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear una VPC Personalizada y una VM dentro
**Contexto:** Crearemos una red VPC en modo personalizado, añadiremos una subred en una región específica y lanzaremos una VM dentro de ella. Esto simula la configuración recomendada para un entorno de producción.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar API de Compute Engine
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-southwest1"
export VPC_NAME="custom-vpc-prod"
export SUBNET_NAME="subnet-prod-madrid"
export VM_NAME="vm-in-custom-vpc"
```

#### ACT (Implementación del escenario)
*Creamos la VPC, luego la subred y finalmente la VM, especificando la red y subred que debe usar.*
```bash
# 1. Crear la VPC en modo personalizado
gcloud compute networks create $VPC_NAME --subnet-mode=custom

# 2. Crear una subred dentro de la nueva VPC
gcloud compute networks subnets create $SUBNET_NAME \
    --network=$VPC_NAME \
    --range=10.1.2.0/24 \
    --region=$REGION

# 3. Crear una VM dentro de la nueva subred
gcloud compute instances create $VM_NAME \
    --zone=$REGION-a \
    --machine-type=e2-micro \
    --network=$VPC_NAME \
    --subnet=$SUBNET_NAME
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la VM se ha creado y que su dirección IP interna pertenece al rango de la subred que definimos (10.1.2.0/24).*
```bash
# Verificar que la VM existe y obtener su IP interna
echo "=== Verificando la IP interna de la VM... ==="
gcloud compute instances describe $VM_NAME --zone=$REGION-a --format='get(networkInterfaces[0].networkIP)'
# La IP debería ser algo como 10.1.2.x
```

#### CLEANUP (Limpieza de recursos)
*Eliminamos los recursos en orden inverso a su creación.*
```bash
# Eliminar la VM, la subred y la VPC
echo "=== Eliminando recursos de laboratorio... ==="
gcloud compute instances delete $VM_NAME --zone=$REGION-a --quiet
gcloud compute networks subnets delete $SUBNET_NAME --region=$REGION --quiet
gcloud compute networks delete $VPC_NAME --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Personalizado es para Producción:** Siempre usa redes en modo personalizado para entornos de producción para tener control total sobre los rangos IP y las regiones.
*   **Las VPCs son Globales, las Subredes Regionales:** Esta es una característica clave de GCP. Te permite gestionar una única red lógica que abarca todo el mundo.
*   **El Firewall es tu primera línea de defensa:** Las reglas de firewall de la VPC son esenciales para la seguridad. Por defecto, todo el tráfico de entrada (ingress) está denegado.

---

## ⚠️ Errores y Confusiones Comunes

*   **Superposición de rangos IP:** Al crear VPCs personalizadas, es tu responsabilidad asegurarte de que los rangos IP de las subredes no se solapen si planeas conectarlas (ej. con VPC Peering).
*   **Usar la red `default` en producción:** Es un riesgo de seguridad y gestión, ya que crea subredes y reglas de firewall permisivas en todas las regiones, lo necesites o no.
*   **Pensar que las VPCs están aisladas por defecto:** Dos VMs en la misma VPC pueden comunicarse entre sí, sin importar en qué zona o región estén. El aislamiento se logra con reglas de firewall.

---

## 🎯 Tips de Examen

*   **VPC es un recurso Global:** El examen hará hincapié en esto. Las subredes son regionales.
*   **Modo Automático vs. Personalizado:** Conoce las diferencias. Automático es para pruebas, Personalizado para producción.
*   **Reglas de Firewall Implícitas:** Recuerda que cada VPC tiene dos reglas implícitas: una que permite todo el tráfico de salida (egress) y una que deniega todo el tráfico de entrada (ingress). Ambas tienen la prioridad más baja (65535).

---

## 🧾 Resumen

La VPC es el componente central de networking en GCP, proporcionando una red global, privada y configurable para tus recursos. A través de subredes regionales y reglas de firewall distribuidas, las VPCs te dan el control necesario para diseñar una topología de red segura, escalable y que se ajuste a tus necesidades, desde un simple proyecto de pruebas hasta una compleja aplicación empresarial multi-región.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-virtual-private-cloud-vpc-networking)
