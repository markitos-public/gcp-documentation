# 🔗 VPC Peering y Shared VPC

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-vpc-peering-y-shared-vpc)

---

## 🧭 Descripción

A medida que una organización crece en la nube, a menudo necesita que las cargas de trabajo en diferentes redes VPC se comuniquen de forma privada y segura. VPC Peering y Shared VPC son dos mecanismos distintos que ofrece Google Cloud para lograr esta conectividad entre redes, cada uno con sus propios casos de uso y modelos de gestión. Este capítulo de profundización explora ambas tecnologías para que puedas decidir cuál es la adecuada para tu arquitectura.

---

## 📘 Detalles

### VPC Network Peering (Interconexión de redes de VPC)

VPC Peering te permite conectar dos redes VPC para que las cargas de trabajo en cada red puedan comunicarse entre sí de forma privada, utilizando direcciones IP internas. 

**Características Clave:**

*   **Conexión 1 a 1:** El peering se establece siempre entre dos redes.
*   **No Transitivo:** Si la VPC-A está conectada con la VPC-B, y la VPC-B con la VPC-C, esto **no** significa que la VPC-A pueda hablar con la VPC-C. No hay enrutamiento transitivo.
*   **Descentralizado:** Cada equipo gestiona su propia red y sus propias reglas de firewall. La conexión de peering debe ser establecida y aceptada por los administradores de ambas redes.
*   **Rangos IP no superpuestos:** Las subredes de las VPCs interconectadas no deben tener rangos IP que se solapen.
*   **Global:** Funciona con subredes en cualquier región, gracias a la naturaleza global de la red de Google.

### Shared VPC (VPC Compartida)

Shared VPC es un modelo de gestión centralizado. Permite a una organización designar una VPC en un proyecto, llamado **Host Project (Proyecto Anfitrión)**, y compartir algunas o todas sus subredes con otros proyectos, llamados **Service Projects (Proyectos de Servicio)**.

**Características Clave:**

*   **Centralizado:** Un equipo de red central gestiona la VPC, las subredes y las rutas en el Host Project.
*   **Separación de Responsabilidades:** Los equipos de aplicación pueden crear y gestionar sus propios recursos (como VMs) en los Service Projects, utilizando las subredes compartidas del Host Project.
*   **IAM para el Control:** El control sobre quién puede usar qué subred se gestiona con permisos de IAM específicos (`compute.networkUser`).
*   **Ideal para Empresas:** Es el modelo preferido para organizaciones grandes, ya que permite una gestión de red coherente y centralizada mientras da autonomía a los equipos de desarrollo.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Configurar una Conexión de VPC Peering
**Contexto:** Crearemos dos VPCs, `vpc-a` y `vpc-b`, y estableceremos una conexión de peering entre ellas para que una VM en `vpc-a` pueda hacer ping a una VM en `vpc-b` usando sus IPs internas.

#### ARRANGE (Preparación del laboratorio)
```bash
# Variables
export PROJECT_ID=$(gcloud config get-value project)

# Crear VPCs y subredes (con rangos que no se solapen)
gcloud compute networks create vpc-a --subnet-mode=custom
gcloud compute networks subnets create subnet-a --network=vpc-a --range=10.0.1.0/24 --region=us-central1

gcloud compute networks create vpc-b --subnet-mode=custom
gcloud compute networks subnets create subnet-b --network=vpc-b --range=10.0.2.0/24 --region=us-central1

# Crear VMs en cada VPC
gcloud compute instances create vm-a --zone=us-central1-a --network=vpc-a --subnet=subnet-a
gcloud compute instances create vm-b --zone=us-central1-a --network=vpc-b --subnet=subnet-b

# Regla de firewall para permitir ICMP (ping) en ambas VPCs
gcloud compute firewall-rules create allow-icmp-a --network=vpc-a --allow=icmp
gcloud compute firewall-rules create allow-icmp-b --network=vpc-b --allow=icmp
```

#### ACT (Implementación del escenario)
*Creamos la relación de peering en ambas direcciones.*
```bash
# 1. Crear el peering de vpc-a hacia vpc-b
gcloud compute networks peerings create peering-a-to-b --network=vpc-a --peer-network=vpc-b

# 2. Crear el peering de vpc-b hacia vpc-a
gcloud compute networks peerings create peering-b-to-a --network=vpc-b --peer-network=vpc-a
```

#### ASSERT (Verificación de funcionalidades)
*Desde `vm-a`, intentamos hacer ping a la IP interna de `vm-b`.*
```bash
# Obtener la IP interna de vm-b
export IP_VM_B=$(gcloud compute instances describe vm-b --zone=us-central1-a --format='get(networkInterfaces[0].networkIP)')

# Intentar el ping desde vm-a (debería funcionar)
echo "\n=== Intentando hacer ping de vm-a a vm-b... ==="
gcloud compute ssh vm-a --zone=us-central1-a --command="ping -c 3 $IP_VM_B"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar todo
gcloud compute instances delete vm-a --zone=us-central1-a --quiet
gcloud compute instances delete vm-b --zone=us-central1-a --quiet
gcloud compute firewall-rules delete allow-icmp-a --quiet
gcloud compute firewall-rules delete allow-icmp-b --quiet
gcloud compute networks peerings delete peering-a-to-b --network=vpc-a --quiet
gcloud compute networks peerings delete peering-b-to-a --network=vpc-b --quiet
gcloud compute networks delete vpc-a --quiet
gcloud compute networks delete vpc-b --quiet
```

---

## 💡 Lecciones Aprendidas

*   **Peering para simplicidad, Shared VPC para gobernanza:** Usa Peering para conectar redes de equipos con gestión descentralizada. Usa Shared VPC para una gestión de red centralizada en una organización grande.
*   **El enrutamiento no es transitivo:** Este es el límite más importante de VPC Peering. Para conectar muchas VPCs, necesitas una topología de malla (hub-and-spoke con Cloud VPN/Interconnect o Network Connectivity Center).
*   **IAM es clave en Shared VPC:** La potencia de Shared VPC reside en usar IAM para controlar qué equipos (en Service Projects) pueden usar qué subredes del Host Project.

---

## ⚠️ Errores y Confusiones Comunes

*   **Superposición de IPs en Peering:** Es el error número uno. Si los rangos IP de las subredes se solapan, no puedes establecer la conexión de peering.
*   **Asumir enrutamiento transitivo:** Intentar que una VM en VPC-A alcance una VM en VPC-C a través de VPC-B no funcionará con peering.
*   **Confundir Host y Service Project:** En Shared VPC, la red vive en el Host Project. Los recursos (VMs) viven en los Service Projects.

---

## 🎯 Tips de Examen

*   **Peering no es transitivo:** Es casi seguro que habrá una pregunta sobre esto.
*   **Shared VPC = Gestión Centralizada:** Si un escenario describe una empresa grande con un equipo de red central que quiere mantener el control, la respuesta es Shared VPC.
*   **Permiso para Shared VPC:** El rol `compute.networkUser` es el que permite a un principal en un Service Project usar una subred del Host Project.

---

## 🧾 Resumen

VPC Peering y Shared VPC son herramientas cruciales para la conectividad de red en GCP más allá de una sola VPC. Peering ofrece una solución descentralizada y simple para conectar dos redes, mientras que Shared VPC proporciona un modelo de gobernanza centralizado y escalable, ideal para grandes organizaciones que necesitan unificar su estrategia de red mientras otorgan autonomía a los equipos de desarrollo.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-vpc-peering-y-shared-vpc)
