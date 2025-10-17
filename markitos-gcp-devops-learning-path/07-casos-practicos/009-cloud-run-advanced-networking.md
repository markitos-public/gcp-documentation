# ☁️ Caso Práctico: Red Avanzada en Cloud Run (Dominio e IP Estática)

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🏛️ Arquitectura de la Solución](#️-arquitectura-de-la-solución)
* [🔬 Laboratorio Práctico (Paso a Paso)](#-laboratorio-práctico-paso-a-paso)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Un equipo está desplegando una aplicación en Cloud Run que tiene dos requisitos de red específicos para un entorno de producción:

1.  **Acceso Público con Marca:** La aplicación debe ser accesible a través de un dominio personalizado (ej. `api.miempresa.com`) en lugar de la URL `run.app` genérica, y debe servirse a través de HTTPS.
2.  **Integración con Sistemas Heredados:** La aplicación necesita conectarse a una API de un proveedor externo que restringe el acceso por IP. Por lo tanto, todas las peticiones de salida (egress) desde Cloud Run deben originarse desde una dirección IP estática y conocida que se pueda añadir a la lista de permitidos (allow-list) del proveedor.

**Objetivo:** Configurar un servicio de Cloud Run para que utilice un dominio personalizado con un certificado SSL gestionado por Google, y para que todo su tráfico de salida hacia internet pase a través de una IP estática.

---

## 🏛️ Arquitectura de la Solución

Se abordan los dos requisitos con diferentes componentes de Google Cloud.

### Parte 1: Dominio Personalizado con HTTPS

Esto se logra utilizando un **Balanceador de Carga de Aplicaciones Externo Global (Global External Application Load Balancer)**.

1.  **Cloud Run como Backend:** Se crea un grupo de red sin servidores (Serverless NEG) que apunta al servicio de Cloud Run. Este NEG actúa como el backend para el balanceador de carga.
2.  **Balanceador de Carga:** Se configura un balanceador de carga HTTP(S) externo.
    *   **Frontend:** Se crea una regla de reenvío con una dirección IP estática (para el balanceador, no para el servicio de Cloud Run) y se asocia un **Certificado SSL gestionado por Google**. Google se encarga de aprovisionar y renovar este certificado automáticamente, siempre que el DNS del dominio apunte a la IP del balanceador.
    *   **Backend:** La regla de enrutamiento del balanceador de carga dirige el tráfico que llega al frontend hacia el Serverless NEG del servicio de Cloud Run.
3.  **DNS:** Se crea un registro `A` en el proveedor de DNS del dominio personalizado que apunta a la dirección IP del frontend del balanceador de carga.

### Parte 2: IP de Salida Estática

Cloud Run por sí solo no tiene una IP de salida estática. Para lograrlo, se debe enrutar el tráfico de salida a través de una VPC.

1.  **Conector de Acceso a VPC sin Servidores (Serverless VPC Access Connector):** Se crea un conector en la misma región que el servicio de Cloud Run. Este conector actúa como un puente, permitiendo que el tráfico de Cloud Run entre en una red VPC.
2.  **Red VPC:** Se utiliza una red VPC existente o se crea una nueva.
3.  **Cloud NAT (Network Address Translation):** Se configura una puerta de enlace de Cloud NAT en la VPC. Se reserva una dirección IP estática y se configura Cloud NAT para que todo el tráfico que salga de la subred del VPC Connector hacia internet utilice esa IP estática reservada.
4.  **Configuración de Cloud Run:** Se despliega el servicio de Cloud Run asociándolo con el VPC Connector y configurando el tráfico de salida (`egress`) para que **todo** el tráfico se enrute a través de la VPC.

![Arquitectura de Red Avanzada en Cloud Run](https://storage.googleapis.com/gcp-devops-kulture-images/cloud-run-advanced-networking.png) *(Nota: Esta es una URL de imagen conceptual)*

---

## 🔬 Laboratorio Práctico (Paso a Paso)

*(Nota: Este laboratorio requiere un dominio registrado que puedas gestionar.)*

### Parte 1: Configurar el Dominio Personalizado

```bash
# ARRANGE
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export SERVICE_NAME="my-custom-domain-app"
export NEG_NAME="${SERVICE_NAME}-neg"
export LB_NAME="${SERVICE_NAME}-lb"
export DOMAIN_NAME="YOUR_DOMAIN.COM" # ej. api.miempresa.com

# 1. Desplegar un servicio de Cloud Run de ejemplo
gcloud run deploy $SERVICE_NAME --image="gcr.io/cloudrun/hello" --region=$REGION --allow-unauthenticated

# 2. Crear un Serverless NEG para el servicio
gcloud compute network-endpoint-groups create $NEG_NAME \
    --region=$REGION \
    --network-endpoint-type=serverless \
    --cloud-run-service=$SERVICE_NAME

# ACT
# 3. Reservar una IP estática para el balanceador de carga
gcloud compute addresses create ${LB_NAME}-ip --global
export LB_IP=$(gcloud compute addresses describe ${LB_NAME}-ip --global --format="value(address)")

# 4. Crear un certificado SSL gestionado por Google
gcloud compute ssl-certificates create ${LB_NAME}-cert \
    --domains=$DOMAIN_NAME --global

# 5. Crear el balanceador de carga
gcloud compute backend-services create ${LB_NAME}-bs --global
gcloud compute backend-services add-backend ${LB_NAME}-bs --global --network-endpoint-group=$NEG_NAME --network-endpoint-group-region=$REGION
gcloud compute url-maps create ${LB_NAME}-map --default-service=${LB_NAME}-bs
gcloud compute target-https-proxies create ${LB_NAME}-proxy --url-map=${LB_NAME}-map --ssl-certificates=${LB_NAME}-cert
gcloud compute forwarding-rules create ${LB_NAME}-fw --address=${LB_NAME}-ip --target-https-proxy=${LB_NAME}-proxy --global --ports=443

# ASSERT
# 6. Configurar el DNS
# Ve a tu proveedor de DNS y crea un registro A para $DOMAIN_NAME que apunte a la IP $LB_IP.
# Puede tardar varios minutos/horas en propagarse y en que el certificado se aprovisione.
# Una vez listo, al acceder a https://$DOMAIN_NAME deberías ver la app de Cloud Run.
```

### Parte 2: Configurar la IP de Salida Estática

```bash
# ARRANGE
export VPC_CONNECTOR_NAME="my-vpc-connector"
export NAT_ROUTER_NAME="my-nat-router"
export NAT_GW_NAME="my-nat-gateway"

# 1. Crear un conector de VPC sin servidores
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access
gcloud compute instances create-with-container vpc-connector-vm ... # (Pasos detallados omitidos por brevedad, se crea el conector)
# En la práctica, se usa:
gcloud compute networks vpc-access connectors create $VPC_CONNECTOR_NAME \
    --region=$REGION --range="10.8.0.0/28"

# ACT
# 2. Crear un Cloud Router y una puerta de enlace de Cloud NAT
gcloud compute routers create $NAT_ROUTER_NAME --network=default --region=$REGION
gcloud compute nat create $NAT_GW_NAME \
    --router=$NAT_ROUTER_NAME \
    --region=$REGION \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips

# 3. Desplegar un nuevo servicio de Cloud Run que use el conector
# Usaremos una imagen que muestra la IP de salida.
gcloud run deploy static-ip-app \
    --image="gcr.io/cloud-run/ip" \
    --region=$REGION \
    --allow-unauthenticated \
    --vpc-connector=$VPC_CONNECTOR_NAME \
    --vpc-egress=all

# ASSERT
# 4. Verificar la IP de salida
export APP_URL=$(gcloud run services describe static-ip-app --region=$REGION --format="value(status.url)")
export NAT_IP=$(gcloud compute nat get-ip-info $NAT_GW_NAME --router=$NAT_ROUTER_NAME --region=$REGION --format="value(ipInfo[0].externalIp)")

# Accede a la URL de la app. La IP que muestra debe coincidir con la IP del NAT.
curl $APP_URL
# Compara la salida con el valor de $NAT_IP
```

---

## 💡 Lecciones Aprendidas

*   **Cloud Run es un Backend, no un Frontend:** Para funcionalidades de red avanzadas como dominios personalizados, WAF (Cloud Armor) o CDN, el patrón es siempre usar un Balanceador de Carga Externo como frontend y tratar a Cloud Run como un backend a través de un Serverless NEG.
*   **La Salida Estática Requiere una VPC:** La única forma de que Cloud Run tenga una IP de salida predecible es forzando su tráfico a través de una VPC con un Cloud NAT. Esto tiene un costo adicional (VPC Connector, NAT, tráfico) que debe ser considerado.
*   **El Tráfico Egress es Clave:** La opción `--vpc-egress=all` es fundamental. Sin ella, solo el tráfico a IPs privadas se enrutaría por la VPC, y el tráfico a internet seguiría saliendo por el rango de IPs dinámicas de Google.

---

## 🧾 Resumen

Aunque Cloud Run abstrae la infraestructura, ofrece potentes integraciones de red para escenarios de producción. Los dominios personalizados se logran elegantemente mediante un Balanceador de Carga Externo con Serverless NEGs, que también habilita SSL gestionado, CDN y WAF. Por otro lado, las IPs de salida estáticas se consiguen enrutando el tráfico a través de un VPC Connector hacia una puerta de enlace de Cloud NAT, proporcionando una identidad de red fija para la integración con sistemas externos.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-red-avanzada-en-cloud-run-dominio-e-ip-estática)
