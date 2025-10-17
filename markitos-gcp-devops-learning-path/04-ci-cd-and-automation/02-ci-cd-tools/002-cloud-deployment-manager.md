# ☁️ Cloud Deployment Manager: IaC Nativa en GCP

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

**Cloud Deployment Manager (CDM)** es el servicio de Infraestructura como Código (IaC) nativo de Google Cloud. Permite a los desarrolladores y administradores especificar todos los recursos que componen una aplicación o entorno en un formato declarativo usando plantillas en **YAML**. CDM interpreta esta configuración y aprovisiona los recursos en GCP de manera ordenada y predecible. A diferencia de Terraform, que es una herramienta de terceros, CDM está completamente integrado en el ecosistema de GCP y utiliza directamente las APIs de Google para gestionar el ciclo de vida de la infraestructura.

---

## 📘 Detalles

Deployment Manager utiliza varios conceptos clave para definir y gestionar despliegues.

### 🔹 Configuraciones (Configurations)

Una configuración es un archivo escrito en formato YAML que describe todos los recursos de GCP que se desean crear. Este archivo, comúnmente llamado `deployment.yaml`, es la pieza central de CDM. Contiene una sección `resources` que lista los componentes a desplegar, como instancias de Compute Engine, redes VPC o buckets de Cloud Storage.

### 🔹 Plantillas (Templates)

Para fomentar la reutilización, las configuraciones pueden importar **plantillas**. Una plantilla es un archivo separado que define un conjunto de recursos y puede ser parametrizado. Las plantillas se pueden escribir en **Jinja 2** o **Python 3**. Esto permite crear módulos de infraestructura reutilizables (por ejemplo, una plantilla para un servidor web con un balanceador de carga) que se pueden importar en diferentes configuraciones, simplificando despliegues complejos.

### 🔹 Despliegues (Deployments)

Un **despliegue** es una colección de recursos que se instancian y gestionan juntos, basándose en una configuración. Cuando creas un despliegue, Deployment Manager crea todos los recursos definidos en la configuración. Puedes actualizar el despliegue modificando la configuración y volviéndola a aplicar, y puedes eliminarlo, lo que destruirá todos los recursos asociados.

### 🔹 Flujo de Trabajo

El flujo de trabajo de CDM es similar al de otras herramientas de IaC:
1.  **Crear la Configuración:** Se escribe el archivo `deployment.yaml`, opcionalmente importando plantillas.
2.  **Previsualizar (Preview):** Antes de aplicar los cambios, se puede obtener una vista previa. CDM muestra qué recursos se crearán, modificarán o eliminarán. Esto es análogo al `terraform plan`.
3.  **Crear/Actualizar el Despliegue:** Se aplica la configuración para crear o actualizar el despliegue. CDM se encarga de realizar las llamadas a las APIs de GCP en el orden correcto.
4.  **Eliminar el Despliegue:** Cuando ya no se necesita, se elimina el despliegue, y CDM se encarga de borrar todos los recursos que gestionaba.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio utiliza `gcloud` para crear un despliegue simple con Deployment Manager que aprovisiona una red VPC personalizada.

### ARRANGE (Preparación)

```bash
# Los comandos se ejecutan en Cloud Shell.

# Habilitar la API de Deployment Manager
gcloud services enable deploymentmanager.googleapis.com

# Crear un directorio para el laboratorio
mkdir cdm-vpc-demo
cd cdm-vpc-demo

# Crear el archivo de configuración YAML
cat > vpc-deployment.yaml << EOM
resources:
- name: my-custom-vpc
  type: compute.v1.network
  properties:
    autoCreateSubnetworks: false
    description: "VPC creada con Deployment Manager"

- name: my-custom-subnet
  type: compute.v1.subnetwork
  properties:
    network: $(ref.my-custom-vpc.selfLink)
    ipCidrRange: 10.10.10.0/24
    region: europe-west1
    description: "Subnet creada con Deployment Manager"
EOM
```

### ACT (Implementación)

```bash
# 1. Previsualizar el despliegue
# El comando muestra los recursos que se crearán sin aplicar ningún cambio.
gcloud deployment-manager deployments create my-vpc-deployment \
    --config=vpc-deployment.yaml \
    --preview

# 2. Crear el despliegue
# Ahora, ejecuta el comando para crear realmente los recursos.
gcloud deployment-manager deployments create my-vpc-deployment \
    --config=vpc-deployment.yaml
```

### ASSERT (Verificación)

```bash
# 1. Describir el despliegue para ver su estado
# Debería mostrar que el estado es COMPLETED.
gcloud deployment-manager deployments describe my-vpc-deployment

# 2. Listar los manifiestos y recursos del despliegue
gcloud deployment-manager manifests describe --deployment=my-vpc-deployment

# 3. Verificar los recursos directamente en GCP con gcloud
gcloud compute networks list --filter="name=my-custom-vpc"
gcloud compute networks subnets list --filter="name=my-custom-subnet"
```

### CLEANUP (Limpieza)

```bash
# Eliminar el despliegue
# Esto eliminará todos los recursos creados por la configuración (la VPC y la subred).
gcloud deployment-manager deployments delete my-vpc-deployment --quiet

# Volver al directorio padre y eliminar la carpeta del laboratorio
cd ..
rm -rf cdm-vpc-demo
```

---

## 💡 Lecciones Aprendidas

*   **Nativo y sin Agentes:** Al ser un servicio gestionado de GCP, no necesitas instalar ningún software ni gestionar la autenticación por separado. Simplemente escribes YAML y usas `gcloud`.
*   **El Poder de las Plantillas:** La verdadera escalabilidad con CDM proviene del uso de plantillas en Jinja o Python. Permiten abstraer la complejidad y crear módulos de infraestructura reutilizables y componibles.
*   **Dependencias Implícitas:** CDM es lo suficientemente inteligente como para inferir dependencias entre recursos. En el laboratorio, entiende que la subred depende de la VPC (usando `$(ref.my-custom-vpc.selfLink)`) y crea la VPC primero.

---

## ⚠️ Errores y Confusiones Comunes

*   **Sintaxis de YAML:** El error más frecuente son los problemas de formato en el archivo YAML (indentación, guiones, etc.). Es un formato estricto y sensible a los espacios.
*   **No Usar la Vista Previa (`--preview`):** Al igual que con Terraform, ir directamente a la creación o actualización sin una vista previa puede llevar a cambios inesperados. La vista previa es una red de seguridad fundamental.
*   **Complejidad de las Plantillas:** Aunque potentes, las plantillas en Jinja o Python pueden volverse muy complejas de escribir y depurar en comparación con la simplicidad de HCL en Terraform para casos de uso comunes.

---

## 🎯 Tips de Examen

*   **Identificar CDM:** Si una pregunta menciona la gestión de infraestructura como código utilizando **YAML** y una herramienta **nativa de GCP**, la respuesta es **Cloud Deployment Manager**.
*   **Plantillas (Templates):** Recuerda los dos lenguajes de plantillas soportados: **Jinja2** y **Python**. Esto es un diferenciador clave.
*   **CDM vs. Terraform:** Conoce las diferencias de alto nivel. **CDM** es nativo de GCP, usa YAML/Jinja/Python y no tiene estado local. **Terraform** es de código abierto, multi-nube, usa HCL y gestiona un archivo de estado.

---

## 🧾 Resumen

Cloud Deployment Manager es la solución de Infraestructura como Código nativa de Google Cloud, que permite definir y gestionar recursos de GCP de forma declarativa a través de archivos de configuración YAML. Aprovechando plantillas reutilizables en Jinja o Python, CDM ofrece una manera integrada y sin agentes para automatizar el aprovisionamiento y el ciclo de vida de la infraestructura en GCP, aunque a menudo se ve como una alternativa más simple y menos extensible que Terraform.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-deployment-manager-iac-nativa-en-gcp)
