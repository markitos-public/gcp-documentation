
# 📜 001: Escalamiento de Máquinas Virtuales (MIGs y Autoscaling)

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Conceptos Clave](#conceptos-clave)
3.  [Políticas de Escalado Automático](#políticas-de-escalado-automático)
4.  [Actualizaciones de Instancias en un MIG](#actualizaciones-de-instancias-en-un-mig)
5.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
6.  [🧠 Lecciones Aprendidas](#lecciones-aprendidas)
7.  [🤔 Errores y Confusiones Comunes](#errores-y-confusiones-comunes)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

El **escalamiento de máquinas virtuales** es la capacidad de un sistema para ajustar la cantidad de recursos de cómputo (VMs) en respuesta a la demanda de la carga de trabajo. En Google Cloud, esta funcionalidad se logra principalmente a través de los **Grupos de Instancias Administradas (Managed Instance Groups - MIGs)** y su componente de **Autoscaling**.

Un MIG es un conjunto de instancias de VM idénticas que puedes administrar como una sola entidad. El Autoscaler es el "cerebro" que añade o elimina automáticamente instancias del MIG basándose en reglas predefinidas, garantizando el rendimiento durante los picos de demanda y optimizando los costos durante los períodos de baja actividad.

### Conceptos Clave

*   **Escalado Vertical vs. Horizontal:**
    *   **Vertical:** Aumentar los recursos de una VM existente (más vCPU, más RAM). Es simple pero tiene límites físicos y requiere un reinicio.
    *   **Horizontal:** Añadir más VMs al grupo. Es la estrategia utilizada por los MIGs, ofreciendo alta disponibilidad y flexibilidad casi ilimitada.

*   **Plantilla de Instancia (Instance Template):**
    *   Es un recurso inmutable que define la configuración de cada VM en un MIG: tipo de máquina, imagen de disco, etiquetas, scripts de inicio, etc.
    *   Si necesitas cambiar la configuración de las VMs, debes crear una nueva plantilla y aplicarla al grupo (generalmente a través de una actualización progresiva).

*   **Grupo de Instancias Administradas (MIG):**
    *   Utiliza una plantilla de instancia para crear y mantener un grupo de VMs homogéneas.
    *   **Auto-reparación (Auto-healing):** Si una VM falla una verificación de estado, el MIG la recrea automáticamente, garantizando la disponibilidad.
    *   **Escalabilidad:** Gestiona el escalado automático del grupo de VMs.

*   **Verificaciones de Estado (Health Checks):**
    *   Son sondeos periódicos (ej. una petición HTTP a un puerto específico) que el MIG realiza para determinar si una instancia está funcionando correctamente.
    *   Si una instancia no responde satisfactoriamente después de un número configurable de intentos, se declara "unhealthy" y el MIG la reemplaza.

### Políticas de Escalado Automático

El Autoscaler puede tomar decisiones basándose en diferentes tipos de señales. Puedes combinar varias políticas, y el Autoscaler elegirá la que recomiende el mayor número de instancias.

1.  **Utilización de CPU (Promedio):**
    *   **Concepto:** La política más común. Se define un nivel de uso de CPU objetivo (ej. 60%).
    *   **Comportamiento:** Si la CPU promedio del grupo supera el 60%, el Autoscaler añade instancias. Si cae por debajo, las elimina.

2.  **Capacidad de Balanceo de Carga HTTP(S):**
    *   **Concepto:** Escala en función de la cantidad de tráfico que recibe un balanceador de carga asociado al MIG.
    *   **Comportamiento:** Puedes establecer un objetivo de utilización de backend (ej. 80% de la capacidad) o un número de peticiones por segundo (RPS) por instancia.

3.  **Métricas de Cloud Monitoring:**
    *   **Concepto:** La opción más flexible. Puedes escalar basándote en cualquier métrica estándar de GCP (ej. tamaño de una cola de Pub/Sub) o incluso en métricas personalizadas que tu aplicación exporte.
    *   **Comportamiento:** Define un valor objetivo para la métrica y el Autoscaler trabajará para mantenerlo, añadiendo o quitando VMs.

4.  **Programaciones (Schedules):**
    *   **Concepto:** Escala basándose en el tiempo. Es útil para cargas de trabajo predecibles (ej. más tráfico durante el horario laboral).
    *   **Comportamiento:** Defines una programación (usando la sintaxis de cron) y el número mínimo de instancias requeridas para ese período.

### Actualizaciones de Instancias en un MIG

Cuando necesitas actualizar las VMs a una nueva plantilla de instancia (ej. para cambiar la versión de tu software), los MIGs ofrecen estrategias seguras:

*   **Actualización Progresiva (Rolling Update):** Reemplaza gradualmente las instancias antiguas por las nuevas. Puedes controlar cuántas instancias se actualizan a la vez (`max-unavailable`) y cuántas instancias nuevas se crean por encima del tamaño normal del grupo (`max-surge`).
*   **Actualización Canary:** Reemplaza solo un pequeño porcentaje de instancias con la nueva plantilla. Esto te permite probar la nueva versión con tráfico real antes de decidir si continuar con el despliegue completo o revertir.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear un grupo de instancias que escale automáticamente basado en la CPU.

1.  **Act (Crear Plantilla):** Primero, creamos una plantilla de instancia con una máquina pequeña.
    ```bash
    gcloud compute instance-templates create my-scaling-template \
        --machine-type=e2-small \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata startup-script='#!/bin/bash
            apt-get update
            apt-get install -y nginx
            service nginx start'
    ```

2.  **Act (Crear MIG):** Ahora, creamos el MIG regional usando la plantilla.
    ```bash
    gcloud compute instance-groups managed create my-regional-mig \
        --template=my-scaling-template \
        --size=1 \
        --region=us-central1
    ```

3.  **Act (Aplicar Autoscaling):** Finalmente, adjuntamos una política de autoscaling.
    ```bash
    gcloud compute instance-groups managed set-autoscaling my-regional-mig \
        --region=us-central1 \
        --max-num-replicas=5 \
        --min-num-replicas=1 \
        --target-cpu-utilization=0.6
    ```

4.  **Test (Verificación):** Describe el autoscaler para confirmar que la política está activa.
    ```bash
    gcloud compute instance-groups managed describe my-regional-mig --region=us-central1
    # Esperado: En la salida, deberías ver la configuración del autoscaler
    # con minNumReplicas: 1, maxNumReplicas: 5 y un cpuUtilization target de 0.6.
    ```

5.  **Cleanup:** Elimina los recursos.
    ```bash
    gcloud compute instance-groups managed delete my-regional-mig --region=us-central1 --quiet
    gcloud compute instance-templates delete my-scaling-template --quiet
    ```

### 🧠 Lecciones Aprendidas

*   **Diseña para la Inmutabilidad:** Las VMs en un MIG deben ser **sin estado (stateless)**. No deben almacenar datos importantes en sus discos locales, ya que pueden ser eliminadas en cualquier momento. Usa servicios externos como Cloud Storage o Cloud SQL para la persistencia.
*   **La Auto-reparación es clave para la Alta Disponibilidad:** Configura siempre una verificación de estado. Es tu red de seguridad para fallos de software o hardware en las instancias.
*   **El Período de Enfriamiento (Cooldown Period):** El autoscaler espera un "período de enfriamiento" (generalmente unos minutos) después de un cambio para permitir que el grupo se estabilice y las métricas se normalicen antes de tomar otra decisión. Tenlo en cuenta para evitar escalados demasiado agresivos.

### 🤔 Errores y Confusiones Comunes

*   **MIG vs. Grupo de Instancias no Administrado:** Los grupos no administrados son solo una colección de VMs heterogéneas. No ofrecen auto-reparación, ni escalado automático, ni actualizaciones progresivas.
*   **Configurar `min-num-replicas` en 0:** Es posible, y es una excelente manera de ahorrar costos para cargas de trabajo de desarrollo o no críticas. El grupo escalará a 0 cuando no haya demanda.
*   **Métricas de Escalado Inadecuadas:** Escalar por CPU no sirve de nada si tu aplicación está limitada por la memoria o por I/O. Elige una métrica que represente realmente el cuello de botella de tu aplicación.

### 💡 Tips de Examen

*   Cualquier escenario que mencione **alta disponibilidad, tolerancia a fallos y escalabilidad** para aplicaciones en Compute Engine apunta directamente a **MIGs con Autoscaling y Health Checks**.
*   Si la pregunta trata sobre **optimización de costos** para una carga de trabajo variable, la respuesta es **Autoscaling**.
*   Recuerda que para actualizar un MIG, necesitas una **nueva plantilla de instancia**. Las plantillas son inmutables.

### ✍️ Resumen

El escalado automático en GCP, impulsado por los Grupos de Instancias Administradas (MIGs), es la solución fundamental para crear aplicaciones robustas, resilientes y costo-eficientes en Compute Engine. Mediante el uso de plantillas de instancia, políticas de escalado flexibles y verificaciones de estado, los MIGs automatizan la gestión del ciclo de vida de las VMs, permitiendo que las aplicaciones se adapten dinámicamente a la demanda del usuario sin intervención manual.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-001-escalamiento-de-máquinas-virtuales-migs-y-autoscaling)
