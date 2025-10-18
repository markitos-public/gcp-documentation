# 🚀 Google Kubernetes Engine (GKE)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-google-kubernetes-engine-gke)

---

## 🧭 Descripción

Google Kubernetes Engine (GKE) es el servicio gestionado de Kubernetes de Google. Kubernetes es un sistema de orquestación de contenedores de código abierto, originalmente diseñado por Google, que se ha convertido en el estándar de facto para desplegar, escalar y gestionar aplicaciones en contenedores. GKE te quita la carga de gestionar el plano de control de Kubernetes, permitiéndote centrarte en tus aplicaciones mientras te beneficias de la potencia y la flexibilidad de la orquestación de contenedores a escala.

---

## 📘 Detalles

### Arquitectura de un Cluster de GKE

Un cluster de GKE consta de dos partes principales:

1.  **Plano de Control (Control Plane):** Es el cerebro del cluster. Google lo gestiona por ti. Se encarga de programar los contenedores, gestionar el estado del cluster, escalar las aplicaciones y mucho más. Expone la API de Kubernetes para que interactúes con el cluster.

2.  **Nodos (Nodes):** Son las máquinas virtuales (VMs) de Compute Engine que ejecutan tus contenedores. Tú gestionas los nodos (o dejas que GKE lo haga por ti). Los nodos se agrupan en **Grupos de Nodos (Node Pools)**, lo que te permite tener diferentes tipos de máquinas para diferentes cargas de trabajo dentro del mismo cluster.

### Modos de Operación de GKE

GKE ofrece dos modos de operación que definen el nivel de gestión que asumes:

1.  **Standard:** Tienes control total sobre los nodos. Eres responsable de configurar los node pools, el escalado de nodos y su mantenimiento (actualizaciones). Pagas por las VMs de los nodos, independientemente de si tienen cargas de trabajo corriendo o no.
    *   **Ideal para:** Cargas de trabajo que requieren configuraciones de nodo muy específicas o si quieres un control granular sobre la gestión del cluster.

2.  **Autopilot:** Es un modo de operación "sin nodos" (serverless). Google gestiona el plano de control *y también* los nodos. Tú solo despliegas tus Pods y GKE se encarga de provisionar los recursos necesarios para ejecutarlos. Pagas por los recursos (CPU, memoria) que tus Pods solicitan, no por las VMs subyacentes.
    *   **Ideal para:** La mayoría de las nuevas aplicaciones. Simplifica enormemente la operación, optimiza los costos y mejora la seguridad al aplicar las mejores prácticas de Google por defecto.

### Conceptos Clave de Kubernetes

*   **Pod:** La unidad de despliegue más pequeña. Es un grupo de uno o más contenedores que comparten almacenamiento y red.
*   **Deployment:** Un objeto que declara el estado deseado para un conjunto de Pods. Se encarga de crear los Pods y de mantener el número de réplicas deseado.
*   **Service:** Expone un conjunto de Pods como un servicio de red con una única dirección IP y un nombre DNS. Permite que las aplicaciones se comuniquen entre sí.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Crear un Cluster de GKE Autopilot y Desplegar una Aplicación
**Contexto:** Experimentaremos la simplicidad del modo Autopilot. Crearemos un cluster, desplegaremos una aplicación web simple usando un Deployment y la expondremos al mundo exterior con un Service de tipo `LoadBalancer`.

#### ARRANGE (Preparación del laboratorio)
```bash
# Habilitar APIs
gcloud services enable container.googleapis.com --project=$PROJECT_ID

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export CLUSTER_NAME="autopilot-cluster-demo"
```

#### ACT (Implementación del escenario)
*Creamos el cluster, luego definimos nuestro Deployment y Service en un fichero YAML y lo aplicamos.*
```bash
# 1. Crear el cluster de GKE Autopilot (puede tardar unos minutos)
echo "\n=== Creando cluster de GKE Autopilot... ==="
gcloud container clusters create-auto $CLUSTER_NAME --region=$REGION

# 2. Obtener las credenciales para que kubectl pueda conectarse al cluster
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION

# 3. Crear un fichero de manifiesto para la aplicación
cat <<EOT > app-manifest.yaml
apiversion: apps/v1
kind: Deployment
metadata:
  name: hello-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello-app
        image: "gcr.io/google-samples/hello-app:1.0"
        ports:
        - containerPort: 8080
---
apiversion: v1
kind: Service
metadata:
  name: hello-web-service
spec:
  type: LoadBalancer
  selector:
    app: hello
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOT

# 4. Aplicar el manifiesto para desplegar la aplicación
kubectl apply -f app-manifest.yaml
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que los Pods están corriendo y que el Service ha obtenido una IP externa.*
```bash
# 1. Esperar a que los Pods estén en estado Running
echo "\n=== Esperando a que los Pods estén listos... ==="
kubectl wait --for=condition=ready pod -l app=hello --timeout=120s

# 2. Obtener la IP externa del balanceador de carga
export EXTERNAL_IP=$(kubectl get service hello-web-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "\n🚀 Aplicación desplegada. Accede en: http://$EXTERNAL_IP"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el cluster de GKE (esto elimina todos sus recursos internos)
echo "\n=== Eliminando cluster de GKE... ==="
gcloud container clusters delete $CLUSTER_NAME --region=$REGION --quiet
rm app-manifest.yaml
```

---

## 💡 Lecciones Aprendidas

*   **GKE Autopilot simplifica Kubernetes:** Elimina la necesidad de gestionar nodos, permitiéndote centrarte solo en tus aplicaciones.
*   **Declarativo vs. Imperativo:** Con Kubernetes, no le dices al sistema *cómo* hacer las cosas (imperativo), sino que declaras el *estado final deseado* (declarativo) y Kubernetes se encarga de hacerlo realidad.
*   **Los contenedores son el paquete:** GKE no ejecuta tu código directamente, ejecuta los contenedores que contienen tu código y sus dependencias. Esto garantiza la consistencia entre entornos.

---

## ⚠️ Errores y Confusiones Comunes

*   **Gestionar Pods directamente:** Nunca crees Pods directamente. Usa siempre un controlador de nivel superior como un Deployment para asegurarte de que tus Pods se vuelvan a crear si fallan.
*   **Confundir ClusterIP, NodePort y LoadBalancer:** Son tipos de Services. `ClusterIP` (el defecto) solo es accesible desde dentro del cluster. `NodePort` expone el servicio en un puerto en cada nodo. `LoadBalancer` provisiona un balanceador de carga en la nube para exponer el servicio a Internet.
*   **Ignorar la seguridad:** Por defecto, un cluster de GKE tiene una superficie de ataque. Es crucial configurar RBAC, políticas de red y usar el principio de privilegio mínimo para las cuentas de servicio de los Pods.

---

## 🎯 Tips de Examen

*   **Autopilot vs. Standard:** Si un escenario valora la simplicidad operativa, la optimización de costos y la seguridad por defecto, Autopilot es la respuesta. Si valora el control granular sobre los nodos, es Standard.
*   **`kubectl apply -f`:** Es el comando fundamental para aplicar manifiestos YAML a un cluster.
*   **Service de tipo `LoadBalancer`:** Es la forma estándar de exponer una aplicación en GKE a Internet.

---

## 🧾 Resumen

Google Kubernetes Engine es la plataforma de orquestación de contenedores de nivel empresarial de GCP. Al abstraer la complejidad de la gestión de Kubernetes, especialmente en su modo Autopilot, GKE permite a los desarrolladores y operadores desplegar, escalar y gestionar aplicaciones en contenedores de forma robusta y eficiente. Es el pilar del desarrollo de aplicaciones nativas de la nube en Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-google-kubernetes-engine-gke)
