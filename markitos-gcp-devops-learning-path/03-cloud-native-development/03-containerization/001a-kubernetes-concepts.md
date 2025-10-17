
# 📜 001a: Conceptos de Kubernetes

## 📝 Índice

1.  [Descripción](#descripción)
2.  [El Problema: ¿Por Qué Orquestar Contenedores?](#el-problema-por-qué-orquestar-contenedores)
3.  [La Arquitectura de Kubernetes](#la-arquitectura-de-kubernetes)
4.  [Objetos Fundamentales de Kubernetes](#objetos-fundamentales-de-kubernetes)
5.  [El Modelo Declarativo](#el-modelo-declarativo)
6.  [✍️ Resumen](#resumen)
7.  [🔖 Firma](#firma)

---

### Descripción

**Kubernetes** (comúnmente abreviado como **K8s**) es un sistema de orquestación de contenedores de código abierto que automatiza el despliegue, el escalado y la gestión de aplicaciones en contenedores. Fue desarrollado originalmente por Google y ahora es mantenido por la Cloud Native Computing Foundation (CNCF).

Este documento se centra en los conceptos universales de Kubernetes, independientemente de dónde se ejecute (GKE, en on-premise, o en otro proveedor de nube).

### El Problema: ¿Por Qué Orquestar Contenedores?

Los contenedores (como Docker) son excelentes para empaquetar y ejecutar una sola aplicación. Pero en un sistema de producción, necesitas gestionar cientos o miles de contenedores. Esto plantea preguntas complejas:

*   **Despliegue:** ¿Cómo despliego una nueva versión de mi aplicación sin tiempo de inactividad?
*   **Escalado:** ¿Cómo añado más contenedores si aumenta la carga y los elimino si disminuye?
*   **Resiliencia:** ¿Qué pasa si un contenedor o la máquina que lo aloja falla? ¿Cómo se reinicia automáticamente?
*   **Redes:** ¿Cómo se comunican los contenedores entre sí? ¿Cómo expongo mi aplicación al mundo exterior?
*   **Almacenamiento:** ¿Cómo proporciono almacenamiento persistente a mis contenedores?

Kubernetes es el sistema que resuelve todos estos problemas.

### La Arquitectura de Kubernetes

Un clúster de Kubernetes consta de dos tipos de máquinas (nodos):

1.  **Plano de Control (Control Plane):** Es el "cerebro" del clúster. Toma decisiones globales sobre el clúster (ej. programación de aplicaciones) y detecta y responde a los eventos del clúster. Los componentes clave del plano de control son:
    *   **API Server:** Expone la API de Kubernetes. Es el frontend del plano de control.
    *   **etcd:** Una base de datos clave-valor consistente y de alta disponibilidad que se utiliza como el almacén de respaldo de Kubernetes para todos los datos del clúster.
    *   **Scheduler:** Observa los nuevos Pods sin asignar y les asigna un nodo para que se ejecuten.
    *   **Controller Manager:** Ejecuta los controladores, que son bucles que observan el estado del clúster y trabajan para mover el estado actual hacia el estado deseado.

2.  **Nodos de Trabajo (Worker Nodes):** Son las máquinas (VMs o físicas) donde se ejecutan tus aplicaciones. Los componentes clave de un nodo de trabajo son:
    *   **Kubelet:** Un agente que se ejecuta en cada nodo. Se asegura de que los contenedores descritos en los PodSpecs estén funcionando y saludables.
    *   **Kube-proxy:** Un proxy de red que mantiene las reglas de red en los nodos, permitiendo la comunicación de red a tus Pods.
    *   **Container Runtime:** El software que se encarga de ejecutar los contenedores (ej. Docker, containerd).

### Objetos Fundamentales de Kubernetes

Trabajas con Kubernetes manipulando objetos a través de su API. Estos son los más importantes:

*   **Pod:**
    *   Es la **unidad de despliegue más pequeña** en Kubernetes. Un Pod representa uno o más contenedores que se ejecutan juntos en un nodo. Los contenedores dentro de un Pod comparten el mismo entorno de red (IP) y pueden compartir volúmenes de almacenamiento.

*   **Deployment:**
    *   Es un objeto de nivel superior que gestiona el despliegue de Pods. Le dices a un Deployment cuántas réplicas de un Pod quieres ejecutar, y él se encarga de mantener ese número. Si un Pod falla, el Deployment lo reemplaza.
    *   Gestiona las **actualizaciones progresivas (rolling updates)** para desplegar nuevas versiones de tu aplicación sin tiempo de inactividad.

*   **Service:**
    *   Define una forma abstracta de exponer un conjunto de Pods como un único servicio de red. Un Service obtiene una dirección IP estable y un nombre DNS. El tráfico dirigido a esa IP se balancea automáticamente entre los Pods que coinciden con el selector del Service.
    *   Resuelve el problema de que los Pods son efímeros y sus IPs cambian.

*   **ReplicaSet:**
    *   Su propósito es mantener un conjunto estable de réplicas de Pods en ejecución en un momento dado. Generalmente no se usa directamente, sino que es gestionado por un Deployment.

*   **Namespace:**
    *   Proporciona una forma de dividir los recursos del clúster en espacios virtuales. Es un mecanismo de alcance para los objetos. Por ejemplo, puedes tener un Namespace para `desarrollo` y otro para `produccion` dentro del mismo clúster.

### El Modelo Declarativo

Kubernetes opera en un modelo **declarativo**. En lugar de dar comandos imperativos ("ejecuta este contenedor"), tú **declaras el estado deseado** de tu sistema en archivos de manifiesto (generalmente YAML).

*   **Ejemplo:** En un archivo YAML, declaras: "Quiero que haya 3 réplicas de mi aplicación web ejecutándose con la imagen `nginx:1.21`".
*   Aplicas este manifiesto al clúster.
*   Los controladores de Kubernetes observan esta declaración y trabajan para hacer que el **estado actual** del clúster coincida con el **estado deseado**. Si solo hay 2 réplicas, creará una más. Si hay 4, eliminará una.

Este modelo es extremadamente potente y es la base de la resiliencia y la automatización de Kubernetes.

### ✍️ Resumen

Kubernetes es el orquestador de contenedores estándar de facto que resuelve los desafíos de ejecutar aplicaciones en contenedores a escala. Su arquitectura de plano de control y nodos de trabajo, junto con sus objetos fundamentales (Pod, Deployment, Service), proporciona los bloques de construcción para crear sistemas distribuidos robustos. Al adoptar un modelo declarativo, Kubernetes permite a los desarrolladores definir el estado deseado de sus aplicaciones, dejando que el sistema se encargue del trabajo pesado de mantener ese estado, garantizando la escalabilidad, la resiliencia y la portabilidad.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-001a-conceptos-de-kubernetes)
