# 🔗 Subredes y Rangos IP en VPC

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-subredes-y-rangos-ip-en-vpc)

---

## 🧭 Descripción

Este es un capítulo de profundización sobre las subredes (subnets) y el direccionamiento IP, los componentes fundamentales de una VPC. Si la VPC es tu red privada global, las subredes son las particiones lógicas dentro de esa red, ancladas a una región específica, donde viven tus recursos. Una correcta planificación de tus subredes y rangos IP es crucial para la escalabilidad, seguridad y conectividad de tu infraestructura.

---

## 📘 Detalles

### Propiedades de una Subred

*   **Recurso Regional:** Cada subred está asociada a una única región de GCP.
*   **Rango IP Primario:** Toda subred debe tener un rango de direcciones IP primario, definido en notación CIDR (ej. `10.0.1.0/24`). Las direcciones IP internas de las VMs y otros recursos se asignan desde este rango.
*   **IPs Reservadas:** En cada subred, Google reserva las primeras dos y las últimas dos direcciones IP del rango primario para tareas de red. Esto significa que un rango `/24` no tiene 256 direcciones utilizables, sino 252.
*   **Comunicación Interna:** Por defecto, todos los recursos dentro de la misma VPC pueden comunicarse entre sí, sin importar en qué subred o región se encuentren, utilizando sus IPs internas.

### Rangos IP Secundarios (Alias IP)

Además del rango primario, puedes asignar uno o más rangos de IP secundarios a una subred. Su principal caso de uso es para **Alias IP**, que permite asignar múltiples direcciones IP internas a la interfaz de red de una misma VM. Esto es extremadamente útil para alojar servicios basados en contenedores (como con GKE), donde cada Pod puede obtener su propia IP dentro del rango secundario.

### Direcciones IP de Recursos

*   **IP Interna:** Cada VM obtiene una IP interna de la subred en la que se encuentra. Puede ser efímera (cambia si la VM se detiene y se reinicia) o estática.
*   **IP Externa:** Opcionalmente, una VM puede tener una IP externa para comunicarse con Internet. También puede ser efímera o estática.

```bash
# Ejemplo ilustrativo: Describir una subred para ver sus rangos IP.
# Reemplaza 'default' y 'europe-west1' si es necesario.
gcloud compute networks subnets describe default --region=europe-west1
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Expandir un Rango IP y Añadir un Rango Secundario
**Contexto:** Imaginemos que nuestra subred de producción se está quedando sin direcciones IP. Vamos a expandir su rango primario. Además, nos preparamos para desplegar GKE, por lo que añadiremos un rango secundario para los Pods.

#### ARRANGE (Preparación del laboratorio)
```bash
# Variables
export PROJECT_ID=$(gcloud config get-value project)
export VPC_NAME="vpc-for-expansion"
export SUBNET_NAME="subnet-to-expand"
export REGION="us-central1"

# Crear una VPC y una subred con un rango pequeño inicial
gcloud compute networks create $VPC_NAME --subnet-mode=custom
gcloud compute networks subnets create $SUBNET_NAME --network=$VPC_NAME --range=192.168.0.0/28 --region=$REGION
echo "Subred inicial creada con rango /28"
```

#### ACT (Implementación del escenario)
*Usamos `gcloud compute networks subnets expand-ip-range` para el rango primario y `update` para añadir un rango secundario.*
```bash
# 1. Expandir el rango IP primario de /28 a /24
echo "\n=== Expandiendo rango primario... ==="
gcloud compute networks subnets expand-ip-range $SUBNET_NAME --region=$REGION --prefix-length=24

# 2. Añadir un rango IP secundario para Pods de GKE
echo "\n=== Añadiendo rango secundario... ==="
gcloud compute networks subnets update $SUBNET_NAME --region=$REGION --add-secondary-ranges=gke-pods-range=10.0.0.0/20
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que la subred ahora refleja el nuevo prefijo del rango primario y contiene el rango secundario que hemos añadido.*
```bash
# Describir la subred y verificar los rangos
echo "\n=== Verificando la nueva configuración de la subred... ==="
gcloud compute networks subnets describe $SUBNET_NAME --region=$REGION --format="yaml(ipCidrRange, secondaryIpRanges)"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la VPC (que elimina su subred automáticamente)
echo "\n=== Eliminando recursos de laboratorio... ==="
gcloud compute networks delete $VPC_NAME --quiet
# si molesta al borrar por la subnet expandida
#gcloud compute networks subnets delete subnet-to-expand   --network $VPC_NAME
echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Planifica tus rangos IP:** Antes de crear tu VPC, planifica el direccionamiento IP. Evitar la superposición de rangos con otras redes (on-premise, otras VPCs) es crucial para la conectividad futura.
*   **La expansión es unidireccional:** Puedes expandir un rango IP de una subred (disminuyendo el número de prefijo, ej. de /24 a /20), pero no puedes reducirlo.
*   **Los rangos secundarios son para contenedores:** El principal impulsor de los rangos secundarios es GKE, para permitir que cada Pod tenga una IP enrutable dentro de la VPC.

---

## ⚠️ Errores y Confusiones Comunes

*   **Crear subredes demasiado pequeñas:** Es un error común quedarse sin IPs. Siempre es mejor asignar un rango más grande de lo que crees que necesitarás (ej. un /24 o /22 en lugar de un /27).
*   **Superposición de rangos (Overlapping):** Si creas dos subredes con rangos que se solapan en la misma VPC, la creación fallará. Si lo haces en VPCs diferentes que luego quieres conectar con Peering, la conexión fallará.
*   **Olvidar las IPs reservadas:** Al calcular cuántas VMs caben en una subred, recuerda siempre restar las 4 direcciones reservadas por Google.

---

## 🎯 Tips de Examen

*   **4 IPs reservadas:** El examen puede preguntarte cuántos hosts utilizables hay en un rango CIDR dado. Calcula el total y resta 4.
*   **Expandir vs. Reducir:** Recuerda que solo puedes expandir un rango primario, nunca reducirlo.
*   **Alias IP = Rangos Secundarios:** Si una pregunta menciona la necesidad de que una VM tenga múltiples IPs o se prepara para GKE, la respuesta probablemente involucre rangos IP secundarios.

---

## 🧾 Resumen

Las subredes y sus rangos IP son los cimientos sobre los que se construyen tus despliegues en GCP. Una planificación cuidadosa del direccionamiento, el uso de rangos primarios y secundarios, y la comprensión de cómo se asignan las IPs a los recursos son habilidades fundamentales para cualquier arquitecto o ingeniero de la nube que trabaje con Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-subredes-y-rangos-ip-en-vpc)
