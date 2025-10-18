# 🛠️ Cloud Code (IDE Extension)

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#️-cloud-code-ide-extension)

---

## 🧭 Descripción

Cloud Code es un conjunto de extensiones para entornos de desarrollo integrado (IDEs) como Visual Studio Code e IntelliJ, diseñado para facilitar la creación, el despliegue y la depuración de aplicaciones nativas de la nube, especialmente aquellas que se ejecutan en Kubernetes (GKE) y Cloud Run. Actúa como un puente entre tu entorno de desarrollo local y Google Cloud, acelerando el ciclo de desarrollo al integrar herramientas de la nube directamente en tu editor de código.

---

## 📘 Detalles

### Funcionalidades Clave

1.  **Asistencia en la Creación de Aplicaciones:**
    *   Proporciona plantillas de inicio ("Hello World") para GKE y Cloud Run, permitiéndote empezar un nuevo servicio con la estructura de ficheros correcta (`skaffold.yaml`, `Dockerfile`, etc.) con solo unos clics.

2.  **Desarrollo y Depuración Iterativa:**
    *   **Soporte para Skaffold:** Cloud Code se integra con Skaffold, una herramienta de Google que automatiza el ciclo de desarrollo para aplicaciones en Kubernetes. En modo "watch", Skaffold detecta cambios en tu código local, reconstruye automáticamente la imagen del contenedor, la sube y redespliega la aplicación en tu cluster de GKE o en un emulador local (Minikube).
    *   **Depuración en Cluster:** Te permite adjuntar un depurador desde tu IDE directamente a un proceso que se está ejecutando dentro de un contenedor en un cluster de GKE real, como si lo estuvieras depurando localmente.

3.  **Gestión de Recursos de GCP:**
    *   **Explorador de Google Cloud:** Ofrece una vista de árbol dentro de tu IDE para explorar y gestionar recursos como VMs de Compute Engine, clusters de GKE, servicios de Cloud Run y más.
    *   **Soporte para YAML:** Proporciona autocompletado, validación y documentación contextual para ficheros de configuración de Kubernetes y Cloud Build, reduciendo errores.

4.  **Integración con Secret Manager:**
    *   Permite acceder a los secretos almacenados en Google Secret Manager directamente desde el IDE, evitando tener que guardar credenciales en tu máquina local.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Usar Cloud Code para Desplegar una App en GKE
**Contexto:** Este laboratorio es más conceptual, ya que Cloud Code es una herramienta de UI. Describiremos los pasos que seguirías en VS Code para desplegar una aplicación en GKE, y usaremos la CLI para verificar los resultados, simulando el trabajo que Cloud Code hace por debajo.

#### ARRANGE (Preparación del laboratorio)
*En VS Code, con la extensión de Cloud Code instalada, usarías la paleta de comandos (`Ctrl+Shift+P`) para seleccionar "Cloud Code: New Application" y elegirías una plantilla de "Kubernetes Application". Esto crearía un proyecto con un `Dockerfile`, un `skaffold.yaml` y un `kubernetes-manifests/deployment.yaml`.*

```bash
# Simulación de la creación de ficheros por Cloud Code
mkdir gke-app && cd gke-app
cat <<EOT > skaffold.yaml
apiVersion: skaffold/v2beta29
kind: Config
deploy:
  kubectl:
    manifests:
    - kubernetes-manifests/deployment.yaml
EOT

mkdir kubernetes-manifests
cat <<EOT > kubernetes-manifests/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-gke
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-gke
  template:
    metadata:
      labels:
        app: hello-gke
    spec:
      containers:
      - name: server
        image: hello-gke-image
EOT

# Crear un cluster de GKE para el despliegue
gcloud container clusters create-auto gke-demo-cluster --region=europe-west1
gcloud container clusters get-credentials gke-demo-cluster --region=europe-west1
```

#### ACT (Implementación del escenario)
*En VS Code, abrirías la paleta de comandos y seleccionarías "Cloud Code: Run on Kubernetes". Cloud Code usaría Skaffold para construir la imagen, subirla a un registro y aplicar el manifiesto al cluster de GKE activo.*

```bash
# Simulación del `skaffold run` que ejecuta Cloud Code
# (Esto es una simplificación, Skaffold haría más pasos como el build y push de la imagen)

echo "\n=== Simulación: `skaffold run` aplicando manifiestos... ==="
kubectl apply -f kubernetes-manifests/deployment.yaml
```

#### ASSERT (Verificación de funcionalidades)
*Usarías el explorador de Kubernetes de Cloud Code para ver el estado del Deployment y los Pods. Con la CLI, haríamos lo siguiente:*
```bash
# Verificar que el deployment se ha creado y está disponible

echo "\n=== Verificando el despliegue en GKE... ==="
kubectl wait --for=condition=available deployment/hello-gke --timeout=120s
kubectl get deployment hello-gke
```

#### CLEANUP (Limpieza de recursos)
*En VS Code, simplemente detendrías la sesión de "Run on Kubernetes". Con la CLI, eliminamos el deployment y el cluster.*
```bash
# Eliminar los recursos del cluster y el propio cluster

echo "\n=== Eliminando recursos de laboratorio... ==="
kubectl delete -f kubernetes-manifests/deployment.yaml
gcloud container clusters delete gke-demo-cluster --region=europe-west1 --quiet
cd .. && rm -rf gke-app
```

---

## 💡 Lecciones Aprendidas

*   **Acelera el "bucle interno":** La principal ventaja de Cloud Code es acelerar el ciclo de `codificar -> construir -> desplegar -> depurar`, especialmente para Kubernetes, que puede ser complejo.
*   **No es solo para GCP:** Aunque está optimizado para GCP, puedes usar Cloud Code para desarrollar aplicaciones para cualquier cluster de Kubernetes, incluso uno local como Minikube.
*   **Skaffold es el motor:** Cloud Code utiliza Skaffold por debajo para automatizar el flujo de trabajo. Entender cómo funciona `skaffold.yaml` te da un mayor control.

---

## ⚠️ Errores y Confusiones Comunes

*   **Pensar que es un IDE completo:** Cloud Code no es un IDE, es una *extensión* para IDEs existentes como VS Code e IntelliJ.
*   **Ignorar la configuración de Skaffold:** Si el build o el despliegue no funcionan como esperas, el problema suele estar en la configuración del fichero `skaffold.yaml`.
*   **No usar el depurador:** Una de las funcionalidades más potentes es la depuración remota en un cluster. No usarla es perderse una gran parte del valor de la herramienta.

---

## 🎯 Tips de Examen

*   **Cloud Code = Desarrollo para Kubernetes/Cloud Run:** Si una pregunta menciona la necesidad de simplificar o acelerar el desarrollo de aplicaciones para GKE o Cloud Run desde un IDE local, la respuesta es Cloud Code.
*   **Asociar con Skaffold:** Recuerda que Skaffold es la herramienta subyacente que Cloud Code usa para el ciclo de desarrollo iterativo.
*   **Funcionalidades clave:** Recuerda sus principales características: plantillas de inicio, despliegue/depuración continua en cluster, y explorador de recursos de GCP.

---

## 🧾 Resumen

Cloud Code es una herramienta indispensable para los desarrolladores que construyen aplicaciones nativas de la nube en Google Cloud. Al integrar la gestión de GKE, Cloud Run y otros servicios directamente en el IDE, y al automatizar el ciclo de desarrollo con Skaffold, Cloud Code reduce la complejidad y la fricción, permitiendo a los desarrolladores ser más productivos y centrarse en lo que realmente importa: escribir código.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#️-cloud-code-ide-extension)
