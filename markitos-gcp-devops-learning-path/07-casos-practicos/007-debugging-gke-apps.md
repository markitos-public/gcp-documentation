# ☁️ Caso Práctico: Debugging de Aplicaciones en GKE

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🛠️ Kit de Herramientas de Debugging en GKE](#️-kit-de-herramientas-de-debugging-en-gke)
* [🕵️‍♂️ Proceso de Debugging por Capas](#️-proceso-de-debugging-por-capas)
* [🔬 Laboratorio Práctico (Simulación de Errores)](#-laboratorio-práctico-simulación-de-errores)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Un desarrollador despliega una nueva versión de su aplicación en un clúster de GKE. Después de aplicar el manifiesto `deployment.yaml`, el desarrollador ejecuta `kubectl get pods` y observa que los Pods de su aplicación no alcanzan el estado `Running`. En su lugar, se quedan atascados en estados como `ImagePullBackOff`, `CrashLoopBackOff` o `Pending`.

**Objetivo:** Proporcionar una guía sistemática y "pasito a pasito" para diagnosticar y resolver los problemas más comunes que impiden que un Pod se ejecute correctamente en GKE.

---

## 🛠️ Kit de Herramientas de Debugging en GKE

La herramienta principal es `kubectl`, el cuchillo suizo para interactuar con Kubernetes.

1.  **`kubectl get pods -o wide`**: Para obtener una lista de los Pods, su estado, en qué nodo se están ejecutando y sus IPs.
2.  **`kubectl describe pod <pod-name>`**: **La herramienta más importante.** Proporciona una descripción detallada del estado del Pod, su configuración y, lo más crucial, una sección de **Eventos** al final que narra por qué no se está ejecutando.
3.  **`kubectl logs <pod-name>`**: Para ver la salida estándar (stdout) de la aplicación dentro del contenedor. Si el Pod llegó a iniciarse y luego falló, aquí estarán los logs de la aplicación.
4.  **`kubectl logs <pod-name> --previous`**: Para ver los logs de la última vez que el contenedor falló (en caso de un `CrashLoopBackOff`).
5.  **`kubectl exec -it <pod-name> -- /bin/sh`**: Para obtener una shell interactiva dentro de un contenedor que sí está corriendo. Permite probar la conectividad de red, verificar archivos, etc.

---

## 🕵️‍♂️ Proceso de Debugging por Capas

Se debe abordar el debugging según el estado en el que se encuentra el Pod.

### Escenario 1: El Pod está en estado `Pending`

**Significado:** El Pod ha sido aceptado por Kubernetes, pero no puede ser asignado a un nodo para ejecutarse.

1.  **Diagnóstico:** Ejecuta `kubectl describe pod <pod-name>`. Mira la sección de **Eventos**.
2.  **Causas Comunes y Soluciones:**
    *   **Recursos Insuficientes:** El evento dirá algo como `0/3 nodes are available: 3 Insufficient cpu/memory`. El clúster no tiene suficientes recursos para satisfacer las `requests` de CPU o memoria del Pod.
        *   **Solución:** Añadir más nodos al clúster, usar nodos más grandes, o reducir las `requests` de recursos del Pod si son demasiado altas.
    *   **Taints y Tolerations:** El evento puede indicar que los nodos tienen `taints` (marcas) que el Pod no `tolera`. Por ejemplo, un nodo puede estar reservado solo para cargas de trabajo específicas.
        *   **Solución:** Añadir la `toleration` correspondiente al manifiesto del Pod o eliminar el `taint` del nodo si es incorrecto.
    *   **Afinidad de Nodos/Pods:** Las reglas de `nodeAffinity` o `podAntiAffinity` pueden estar impidiendo que el Pod se programe.
        *   **Solución:** Revisar y ajustar estas reglas en el manifiesto del Deployment.

### Escenario 2: El Pod está en estado `ImagePullBackOff` o `ErrImagePull`

**Significado:** El Kubelet en el nodo no puede descargar la imagen de contenedor especificada.

1.  **Diagnóstico:** `kubectl describe pod <pod-name>`. El evento mostrará un error como `Failed to pull image ... repository not found or may require 'docker login'`.
2.  **Causas Comunes y Soluciones:**
    *   **Nombre de Imagen Incorrecto:** Un simple error tipográfico en el nombre de la imagen en el manifiesto del Deployment.
        *   **Solución:** Corregir el nombre de la imagen y volver a aplicar el manifiesto.
    *   **Permisos de Acceso al Registro:** El clúster de GKE no tiene permisos para acceder al registro de contenedores (ej. Artifact Registry). Esto es común si el registro está en un proyecto diferente.
        *   **Solución:** Asegurarse de que los nodos del clúster (su cuenta de servicio) tengan el rol `roles/storage.objectViewer` para GCR o `roles/artifactregistry.reader` para Artifact Registry.
    *   **La Imagen no Existe:** El tag de la imagen especificado no existe en el repositorio.
        *   **Solución:** Verificar en Artifact Registry que la imagen y el tag existen.

### Escenario 3: El Pod está en estado `CrashLoopBackOff`

**Significado:** El contenedor se inicia, pero falla (crashea) inmediatamente. Kubernetes intenta reiniciarlo una y otra vez, y entra en un bucle de fallos.

1.  **Diagnóstico:** Este es un problema de la **aplicación**, no de Kubernetes.
    *   Primero, usa `kubectl logs <pod-name>` para ver el error que la aplicación está arrojando. Puede ser un error de conexión a la base de datos, una variable de entorno que falta, etc.
    *   Si los logs se mueven demasiado rápido, usa `kubectl logs <pod-name> --previous` para ver los logs de la terminación anterior.
2.  **Causas Comunes y Soluciones:**
    *   **Error en el Código de la Aplicación:** Un bug que causa una excepción no controlada al inicio.
        *   **Solución:** Arreglar el código de la aplicación.
    *   **Configuración Incorrecta:** La aplicación no puede encontrar un archivo de configuración, una variable de entorno o un secreto que necesita para arrancar.
        *   **Solución:** Verificar que los `ConfigMaps` y `Secrets` están montados correctamente y que las variables de entorno están bien definidas en el manifiesto.
    *   **Problemas de Conectividad:** La aplicación no puede conectarse a una base de datos u otro servicio en el arranque.
        *   **Solución:** Usar `kubectl exec` en un Pod que funcione para probar la conectividad (`ping`, `curl`) al servicio dependiente. Revisar las `NetworkPolicies`.
    *   **Health Checks Mal Configurados:** La `livenessProbe` (sonda de vida) está fallando porque la aplicación tarda demasiado en arrancar o el endpoint de la sonda es incorrecto. Kubernetes mata el Pod porque piensa que no está sano.
        *   **Solución:** Aumentar el `initialDelaySeconds` de la sonda o corregir el `path` o `port`.

---

## 🔬 Laboratorio Práctico (Simulación de Errores)

### 1. Simular `ImagePullBackOff`

```bash
# ARRANGE: Crear un manifiesto con un nombre de imagen incorrecto
cat > deployment-error1.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: nginx-error1}
spec:
  replicas: 1
  selector: {matchLabels: {app: nginx-error1}}
  template:
    metadata: {labels: {app: nginx-error1}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.999 # Tag que no existe
        ports: [{containerPort: 80}]
EOF

# ACT: Aplicar el manifiesto
kubectl apply -f deployment-error1.yaml

# ASSERT: Diagnosticar el problema
sleep 10 # Dar tiempo a que falle
export POD_NAME=$(kubectl get pods -l app=nginx-error1 -o jsonpath="{.items[0].metadata.name}")
kubectl get pod $POD_NAME # Verás ImagePullBackOff
kubectl describe pod $POD_NAME # Verás el evento de "Failed to pull image"

# CLEANUP
kubectl delete -f deployment-error1.yaml
```

### 2. Simular `CrashLoopBackOff`

```bash
# ARRANGE: Crear un manifiesto que ejecuta un comando que falla
cat > deployment-error2.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: alpine-error2}
spec:
  replicas: 1
  selector: {matchLabels: {app: alpine-error2}}
  template:
    metadata: {labels: {app: alpine-error2}}
    spec:
      containers:
      - name: alpine
        image: alpine
        command: ["/bin/sh", "-c", "echo 'Voy a fallar...'; exit 1"]
EOF

# ACT: Aplicar el manifiesto
kubectl apply -f deployment-error2.yaml

# ASSERT: Diagnosticar el problema
sleep 10
export POD_NAME=$(kubectl get pods -l app=alpine-error2 -o jsonpath="{.items[0].metadata.name}")
kubectl get pod $POD_NAME # Verás CrashLoopBackOff
kubectl logs $POD_NAME # Verás el mensaje "Voy a fallar..."

# CLEANUP
kubectl delete -f deployment-error2.yaml
```

---

## 💡 Lecciones Aprendidas

*   **`kubectl describe` es tu Mejor Amigo:** El 90% de los problemas de infraestructura de Pods (scheduling, pull de imágenes) se resuelven leyendo la sección de **Eventos** de `kubectl describe pod`.
*   **Distingue Problemas de Plataforma vs. Problemas de Aplicación:** `Pending` e `ImagePullBackOff` son problemas de la **plataforma** (Kubernetes no puede ejecutar el Pod). `CrashLoopBackOff` es casi siempre un problema de la **aplicación** (el código dentro del contenedor está fallando).
*   **Piensa en Capas:** El debugging en Kubernetes es un proceso de eliminación. ¿Puede el Pod ser programado? Si sí, ¿puede la imagen ser descargada? Si sí, ¿puede la aplicación arrancar y mantenerse saludable? Aborda cada capa por separado.

---

## 🧾 Resumen

El debugging en GKE es un proceso sistemático que se basa en el uso de `kubectl` para inspeccionar el estado y los eventos de los recursos. Al entender los diferentes estados de un Pod (`Pending`, `ImagePullBackOff`, `CrashLoopBackOff`), un desarrollador puede rápidamente acotar la causa del problema, ya sea un problema de recursos del clúster, de configuración del manifiesto o un bug en el propio código de la aplicación. La clave es seguir la pista que dejan los **eventos** y los **logs**.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-debugging-de-aplicaciones-en-gke)
