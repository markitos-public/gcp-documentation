# 📜 003: Reglas de Firewall de VPC

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Características Principales](#características-principales)
3.  [Componentes de una Regla de Firewall](#componentes-de-una-regla-de-firewall)
4.  [Las Reglas Implícitas: El Fundamento de la Seguridad](#las-reglas-implícitas-el-fundamento-de-la-seguridad)
5.  [Reglas Pre-pobladas en la Red `default`](#reglas-pre-pobladas-en-la-red-default)
6.  [Casos de Uso y Ejemplos](#casos-de-uso-y-ejemplos)
    *   [Ejemplo 1 (Básico): Permitir Tráfico Web](#ejemplo-1-básico-permitir-tráfico-web)
    *   [Ejemplo 2 (Intermedio): Comunicación Segura entre Tiers](#ejemplo-2-intermedio-comunicación-segura-entre-tiers)
    *   [Ejemplo 3 (Avanzado): Aislar Entornos con Cuentas de Servicio](#ejemplo-3-avanzado-aislar-entornos-con-cuentas-de-servicio)
7.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

Las **Reglas de Firewall de VPC** son el mecanismo de seguridad de red fundamental en Google Cloud. Permiten controlar el tráfico que entra (ingreso) y sale (egreso) de tus máquinas virtuales (VMs) de Compute Engine. Funcionan como un firewall distribuido y con estado, lo que significa que puedes crear reglas granulares para permitir o denegar tráfico basado en IPs, protocolos, puertos y más.

Comprender cómo funcionan es absolutamente esencial para proteger tus aplicaciones y tu infraestructura en GCP.

### Características Principales

*   **Distribuidas:** No son un dispositivo físico. Se implementan en la propia infraestructura de red virtualizada de Google, por lo que escalan con tu red sin crear cuellos de botella.
*   **Con Estado (Stateful):** Si permites una conexión de entrada, el tráfico de retorno correspondiente a esa conexión se permite automáticamente, sin necesidad de una regla de egreso correspondiente. Del mismo modo, una conexión de salida permite su tráfico de retorno.
*   **Aplicadas a Nivel de VM:** Las reglas se aplican a nivel de la interfaz de red de cada VM, no a nivel de subred.

### Componentes de una Regla de Firewall

Cada regla se compone de los siguientes elementos:

1.  **Prioridad (Priority):** Un número entero de `0` a `65535`. Las reglas con menor número tienen mayor prioridad. Si dos reglas se contradicen, se aplica la de mayor prioridad.
2.  **Dirección (Direction):**
    *   `INGRESS`: Para el tráfico que **entra** a las VMs.
    *   `EGRESS`: Para el tráfico que **sale** de las VMs.
3.  **Acción (Action):**
    *   `allow`: Permite el tráfico que coincide con la regla.
    *   `deny`: Bloquea el tráfico que coincide con la regla.
4.  **Objetivo (Target):** Define a qué VMs de la red se aplica la regla.
    *   **Todas las instancias de la red:** La opción por defecto.
    *   **Etiquetas de Red (Network Tags):** Aplica la regla solo a las VMs que tengan una etiqueta específica (ej. `web-server`).
    *   **Cuentas de Servicio (Service Accounts):** Aplica la regla solo a las VMs que se ejecutan con una cuenta de servicio específica. Este es el método más seguro y recomendado.
5.  **Filtro de Origen/Destino (Source/Destination Filter):**
    *   Para reglas de `INGRESS`, es el **origen (source)**. Define de dónde puede venir el tráfico (ej. un rango de IPs, otra etiqueta de red o cuenta de servicio).
    *   Para reglas de `EGRESS`, es el **destino (destination)**. Define a dónde puede ir el tráfico.
6.  **Protocolos y Puertos:** Especifica el protocolo (ej. `tcp`, `udp`, `icmp`) y los puertos de destino (ej. `80`, `443`, `5432`).

### Las Reglas Implícitas: El Fundamento de la Seguridad

Cada red VPC, sin excepción, tiene **dos reglas implícitas** con la prioridad más baja (`65535`). No las puedes eliminar, y forman la base de la seguridad de la red:

1.  **Regla de Egreso Implícita:**
    *   **Acción:** `allow`
    *   **Efecto:** Permite todo el tráfico saliente desde cualquier VM a cualquier destino. Esto permite que las VMs se conecten a Internet y a otros servicios de GCP por defecto.

2.  **Regla de Ingreso Implícita:**
    *   **Acción:** `deny`
    *   **Efecto:** Bloquea todo el tráfico entrante desde cualquier fuente a cualquier VM. Esta es la razón por la que, por defecto, no puedes acceder a tus VMs desde Internet. **Toda regla de `allow` de ingreso que creas es una excepción a esta regla.**

### Reglas Pre-pobladas en la Red `default`

La red `default` que se crea automáticamente en cada proyecto nuevo viene con algunas reglas de firewall pre-configuradas por conveniencia. Es crucial conocerlas:

*   `default-allow-internal` (prioridad 65534): Permite el tráfico de **ingreso** para todos los protocolos y puertos entre cualquier instancia **dentro de la misma red**.
*   `default-allow-ssh` (prioridad 65534): Permite el tráfico de **ingreso** en el puerto `tcp:22` (SSH) desde **cualquier origen** (`0.0.0.0/0`).
*   `default-allow-rdp` (prioridad 65534): Permite el tráfico de **ingreso** en el puerto `tcp:3389` (RDP) desde **cualquier origen** (`0.0.0.0/0`).
*   `default-allow-icmp` (prioridad 65534): Permite el tráfico **ICMP** (ej. `ping`) desde **cualquier origen**.

**Advertencia:** Estas reglas son convenientes para empezar, pero permitir SSH y RDP desde todo Internet es una mala práctica de seguridad para entornos de producción. Se recomienda eliminarlas o restringirlas.

### Casos de Uso y Ejemplos

#### Ejemplo 1 (Básico): Permitir Tráfico Web

*   **Objetivo:** Permitir que los usuarios de Internet accedan a tus servidores web.
*   **Configuración de la Regla:**
    *   **Nombre:** `allow-http-https`
    *   **Dirección:** `INGRESS`
    *   **Acción:** `allow`
    *   **Objetivo:** Etiqueta de Red `web-server`
    *   **Filtro de Origen:** `0.0.0.0/0` (cualquier IP)
    *   **Protocolos/Puertos:** `tcp:80`, `tcp:443`

#### Ejemplo 2 (Intermedio): Comunicación Segura entre Tiers

*   **Objetivo:** Permitir que los servidores de aplicación (`app-tier`) se conecten a la base de datos (`db-tier`), pero nadie más.
*   **Configuración de la Regla:**
    *   **Nombre:** `allow-app-to-db`
    *   **Dirección:** `INGRESS`
    *   **Acción:** `allow`
    *   **Objetivo:** Etiqueta de Red `db-tier`
    *   **Filtro de Origen:** Etiqueta de Red `app-tier`
    *   **Protocolos/Puertos:** `tcp:5432` (ej. para PostgreSQL)

#### Ejemplo 3 (Avanzado): Aislar Entornos con Cuentas de Servicio

*   **Objetivo:** Permitir que un balanceador de carga interno (que se ejecuta con una cuenta de servicio específica) acceda a un backend de microservicios, denegando el resto del tráfico.
*   **Configuración de la Regla:**
    *   **Nombre:** `allow-lb-to-backend`
    *   **Dirección:** `INGRESS`
    *   **Acción:** `allow`
    *   **Objetivo:** Cuenta de Servicio `backend-service-account`
    *   **Filtro de Origen:** Cuenta de Servicio `internal-lb-service-account`
    *   **Protocolos/Puertos:** `tcp:8080`

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear una VM y permitir el acceso HTTP usando una etiqueta de red.

```bash
# 1. Crear una VM con una etiqueta de red y un servidor web simple
gcloud compute instances create my-web-server \
    --zone=us-central1-a \
    --tags=web-server \
    --metadata startup-script="#! /bin/bash
        apt-get update
        apt-get install -y nginx
        sed -i 's/nginx/My Web Server/g' /var/www/html/index.nginx-debian.html"

# 2. Intentar acceder a la VM (fallará)
VM_IP=$(gcloud compute instances describe my-web-server --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
curl --connect-timeout 5 $VM_IP
# Esperado: Timeout. La conexión falla porque no hay regla de firewall.

# 3. Crear la regla de firewall
gcloud compute firewall-rules create allow-http-on-tag \
    --allow=tcp:80 \
    --target-tags=web-server \
    --source-ranges=0.0.0.0/0

# 4. Test (Verificación): Volver a intentar acceder
sleep 10 # Dar tiempo a que la regla se propague
curl $VM_IP
# Esperado: Deberías ver el HTML de la página de Nginx con el texto "My Web Server".
```

### 💡 Tips de Examen

*   Recuerda las dos reglas **implícitas**. Son la base de todo.
*   **Prioridad:** Número más bajo gana.
*   **Stateful:** Si permites una petición, la respuesta está permitida automáticamente.
*   **Tags vs. Service Accounts:** Usar cuentas de servicio como objetivo y fuente es más seguro que usar etiquetas, ya que se basa en una identidad criptográfica (la VM) en lugar de una simple etiqueta de texto que cualquiera con permisos puede asignar.

### ✍️ Resumen

Las reglas de firewall de VPC son la primera línea de defensa para la seguridad de la red en GCP. Su naturaleza distribuida y con estado las hace potentes y escalables. Una configuración de firewall efectiva se basa en el principio de **mínimo privilegio**: denegar todo por defecto (gracias a la regla de ingreso implícita) y solo permitir explícitamente el tráfico necesario. El uso de etiquetas de red y, preferiblemente, cuentas de servicio para definir los objetivos y las fuentes de las reglas permite crear políticas de seguridad granulares, flexibles y fáciles de gestionar.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-003-reglas-de-firewall-de-vpc)