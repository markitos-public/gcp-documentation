# ☁️ Modelos de Servicio en la Nube (IaaS, PaaS, SaaS)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-modelos-de-servicio-en-la-nube-iaas-paas-saas)

---

## 🧭 Descripción

No todos los servicios en la nube son iguales. Se clasifican en modelos según el nivel de gestión que el proveedor (Google) asume y el nivel de control que el cliente (tú) retiene. Entender la diferencia entre IaaS, PaaS y SaaS es fundamental para elegir la herramienta correcta para cada trabajo, optimizar costos y diseñar arquitecturas eficientes.

---

## 📘 Detalles

La forma más clásica de entender estos modelos es la "Pizza as a Service".

*   **On-Premises (La pizza casera):** Tú gestionas todo: la masa, los ingredientes, el horno, la electricidad, la mesa...
*   **IaaS (Infrastructure as a Service):** Compras los ingredientes y usas un horno de alquiler. El proveedor te da la infraestructura (horno, electricidad), pero tú pones la pizza, la cocinas y la sirves.
*   **PaaS (Platform as a Service):** Pides una pizza a domicilio. El proveedor se encarga de la infraestructura y de la plataforma de cocinado. Tú solo te preocupas de la mesa y los refrescos.
*   **SaaS (Software as a Service):** Sales a cenar a una pizzería. El proveedor lo gestiona absolutamente todo. Tú solo disfrutas del servicio.

### 1. IaaS (Infrastructure as a Service)
Es el modelo más flexible. Google gestiona el hardware físico (servidores, redes, almacenamiento), pero tú eres responsable de gestionar el sistema operativo, los middlewares, los datos y las aplicaciones.

*   **Ejemplos en GCP:** Compute Engine (VMs), Persistent Disk, Cloud Storage.
*   **Cuándo usarlo:** Cuando necesitas control total sobre el entorno, sistemas operativos específicos o configuraciones de red complejas.

```bash
# Ejemplo ilustrativo: Listar imágenes de SO disponibles para tus VMs.
# Tienes el control para elegir el sistema operativo (IaaS).
gcloud compute images list --project=$PROJECT_ID
```

### 2. PaaS (Platform as a Service)
Abstrae la infraestructura. Google gestiona el hardware y el sistema operativo. Tú solo te preocupas de tu código y tus datos. Es ideal para desarrolladores que quieren centrarse en construir aplicaciones sin gestionar servidores.

*   **Ejemplos en GCP:** App Engine, Cloud Run, Cloud Functions, BigQuery.
*   **Cuándo usarlo:** Para desarrollo rápido de aplicaciones web, APIs, microservicios y análisis de datos sin servidor.

### 3. SaaS (Software as a Service)
Es un software completo que consumes directamente. No gestionas nada de la infraestructura ni de la plataforma; simplemente usas la aplicación.

*   **Ejemplos en GCP:** Google Workspace (Gmail, Drive, Docs), Google Maps, Looker Studio.
*   **Cuándo usarlo:** Cuando necesitas una solución de software lista para usar sin ninguna carga de desarrollo o gestión.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Desplegar un contenedor en IaaS vs PaaS
**Contexto:** Desplegaremos el mismo contenedor web simple (`hello-app`) en Compute Engine (IaaS) y en Cloud Run (PaaS) para experimentar la diferencia en el nivel de gestión.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs necesarias
gcloud services enable compute.googleapis.com run.googleapis.com --project=$PROJECT_ID

# Variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-southwest1"
export VM_NAME="demo-iaas-vm"
export SERVICE_NAME="demo-paas-service"
```

#### ACT 1: Despliegue en IaaS (Compute Engine)
*Creamos una VM y le decimos que ejecute un contenedor. Nota cómo tenemos que definir el tipo de máquina, la zona, etc.*
```bash
# 1. Crear una VM que ejecuta un contenedor
gcloud compute instances create-with-container $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$REGION-a \
    --machine-type=e2-medium \
    --container-image=gcr.io/google-samples/hello-app:1.0 \
    --tags=http-server

# 2. Crear una regla de firewall para permitir el tráfico web
gcloud compute firewall-rules create allow-http --allow tcp:80 --source-ranges 0.0.0.0/0 --target-tags=http-server --project=$PROJECT_ID
```

#### ASSERT 1: Verificación del IaaS
*Verificamos que la VM está corriendo y obtenemos su IP para acceder a la app.*
```bash
# Verificar que la VM está en estado RUNNING
gcloud compute instances list --filter="name=($VM_NAME)" --format="value(status)"

# Obtener la IP externa de la VM
export VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$REGION-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Accede a la app IaaS en: http://$VM_IP"
```

#### ACT 2: Despliegue en PaaS (Cloud Run)
*Desplegamos el mismo contenedor en Cloud Run. Nota la simplicidad: no hay VMs, no hay firewalls, solo el servicio.*
```bash
# Desplegar el contenedor como un servicio de Cloud Run
gcloud run deploy $SERVICE_NAME \
    --project=$PROJECT_ID \
    --image=gcr.io/google-samples/hello-app:1.0 \
    --region=$REGION \
    --allow-unauthenticated
```

#### ASSERT 2: Verificación del PaaS
*Verificamos que el servicio está listo y obtenemos la URL gestionada por Google.*
```bash
# Obtener la URL del servicio PaaS
export SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
echo "Accede a la app PaaS en: $SERVICE_URL"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la VM y la regla de firewall (IaaS)
gcloud compute instances delete $VM_NAME --zone=$REGION-a --quiet
gcloud compute firewall-rules delete allow-http --quiet

# Eliminar el servicio de Cloud Run (PaaS)
gcloud run services delete $SERVICE_NAME --region=$REGION --quiet

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **IaaS te da control, PaaS te da velocidad:** La elección depende de si priorizas la flexibilidad para configurar el entorno (IaaS) o la rapidez para desplegar código (PaaS).
*   **La responsabilidad es compartida:** En todos los modelos, tú sigues siendo responsable de la seguridad de tus datos y de cómo configuras el acceso a ellos.
*   **Serverless es una forma de PaaS:** Servicios como Cloud Run o Cloud Functions son PaaS porque te abstraen completamente de la gestión de servidores.

---

## ⚠️ Errores y Confusiones Comunes

*   **Usar IaaS cuando PaaS es suficiente:** Crear una VM para alojar una simple API web es a menudo un sobrecoste de gestión. Cloud Run sería más eficiente.
*   **Confundir Cloud Storage con Google Drive:** Cloud Storage es un servicio IaaS para almacenar objetos para tus aplicaciones. Google Drive es un producto SaaS para el almacenamiento de archivos de usuario final.
*   **Pensar que PaaS no tiene límites:** Las plataformas PaaS tienen entornos de ejecución y configuraciones más restringidos que una VM de IaaS.

---

## 🎯 Tips de Examen

*   **Asocia productos con modelos:** Compute Engine -> IaaS. App Engine/Cloud Run -> PaaS. Google Workspace -> SaaS. Esta es una pregunta de examen garantizada.
*   **Elige el modelo según la necesidad:** Si el enunciado dice "el equipo no quiere gestionar sistemas operativos", la respuesta es PaaS. Si dice "necesitan acceso completo al kernel del SO", la respuesta es IaaS.
*   **Modelo de Responsabilidad Compartida:** Recuerda qué gestionas tú y qué gestiona Google en cada modelo. Dibuja el diagrama mentalmente.

---

## 🧾 Resumen

Los modelos de servicio IaaS, PaaS y SaaS definen el reparto de responsabilidades entre tú y Google. Elegir el modelo correcto es una decisión de arquitectura fundamental que impacta en la flexibilidad, la velocidad de desarrollo y el coste operacional. IaaS ofrece control, PaaS ofrece conveniencia para los desarrolladores, y SaaS ofrece soluciones listas para usar.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-modelos-de-servicio-en-la-nube-iaas-paas-saas)
