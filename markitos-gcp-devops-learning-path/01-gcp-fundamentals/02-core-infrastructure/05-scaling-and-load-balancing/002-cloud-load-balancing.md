
# 📜 002: Cloud Load Balancing

## 📝 Índice

1.  [Descripción](#descripción)
2.  [La Decisión Clave: El Árbol de Selección](#la-decisión-clave-el-árbol-de-selección)
3.  [Componentes de un Balanceador de Carga](#componentes-de-un-balanceador-de-carga)
4.  [Tipos de Balanceadores de Carga](#tipos-de-balanceadores-de-carga)
    *   [Balanceadores Externos](#balanceadores-externos)
    *   [Balanceadores Internos](#balanceadores-internos)
5.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
6.  [🧠 Lecciones Aprendidas](#lecciones-aprendidas)
7.  [🤔 Errores y Confusiones Comunes](#errores-y-confusiones-comunes)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

**Cloud Load Balancing** es un servicio de Google Cloud totalmente distribuido y definido por software que reparte el tráfico de usuarios entre múltiples instancias de tus aplicaciones. Al distribuir la carga, el balanceo de carga reduce el riesgo de que el rendimiento de la aplicación se vea afectado, aumenta la escalabilidad y garantiza la alta disponibilidad.

Google ofrece una suite completa de balanceadores de carga que se adaptan a diferentes tipos de tráfico, protocolos y requisitos de alcance geográfico (global vs. regional).

### La Decisión Clave: El Árbol de Selección

Elegir el balanceador correcto es la tarea más importante. Google proporciona un "árbol de decisión" oficial que simplifica este proceso. Las preguntas clave son:

1.  **¿El tráfico es Externo o Interno?** (¿Viene de Internet o de dentro de tu VPC?)
2.  **¿El alcance debe ser Global o Regional?** (¿Necesitas una única IP para usuarios de todo el mundo o solo para una región específica?)
3.  **¿Qué protocolo de red se utiliza?** (HTTPS, SSL, TCP, UDP)

Basado en estas respuestas, se elige el balanceador adecuado.

### Componentes de un Balanceador de Carga

Un balanceador de carga en GCP se compone de varias piezas que trabajan juntas:

*   **Regla de Reenvío (Forwarding Rule):** Es la "puerta de entrada". Define la dirección IP pública o privada y el puerto al que los clientes envían el tráfico.
*   **Proxy de Destino o Servidor de Destino (Target Proxy/Pool):** Recibe la petición de la regla de reenvío y la dirige al servicio de backend. Para balanceadores HTTPS/SSL, aquí se configuran los certificados SSL.
*   **Servicio de Backend o Grupo de Backend (Backend Service/Pool):** Es la configuración lógica que define cómo se distribuye el tráfico a los backends y contiene la configuración de la verificación de estado.
*   **Backend:** Es el grupo de puntos finales que reciben el tráfico (ej. un MIG, un grupo de instancias de Cloud Functions, etc.).
*   **Verificación de Estado (Health Check):** Sondea los backends para asegurarse de que pueden recibir tráfico. Si una VM falla la verificación, el balanceador deja de enviarle tráfico hasta que se recupere.

### Tipos de Balanceadores de Carga

#### Balanceadores Externos (Para tráfico desde Internet)

1.  **Balanceador de Carga de Aplicaciones Externo Global (Global External Application Load Balancer):**
    *   **Capa:** 7 (HTTP/HTTPS).
    *   **Alcance:** Global. Una única dirección IP Anycast para todo el mundo.
    *   **Caso de uso:** Aplicaciones web, APIs REST. Es el único que se integra con **Cloud CDN** e **Identity-Aware Proxy (IAP)**.

2.  **Balanceador de Carga de Red de Proxy Externo (External Proxy Network Load Balancer):**
    *   **Capa:** 4 (TCP, con descarga SSL opcional).
    *   **Alcance:** Global.
    *   **Caso de uso:** Tráfico TCP para aplicaciones no web que necesitan terminación SSL, como bases de datos o protocolos de mensajería.

3.  **Balanceador de Carga de Red de Paso Externo (External Passthrough Network Load Balancer):**
    *   **Capa:** 4 (TCP/UDP).
    *   **Alcance:** Regional.
    *   **Caso de uso:** Tráfico de alto rendimiento y baja latencia donde se necesita preservar la IP de origen del cliente. El tráfico pasa directamente a las VMs. Ideal para gaming, streaming.

#### Balanceadores Internos (Para tráfico dentro de tu VPC)

1.  **Balanceador de Carga de Aplicaciones Interno Regional (Regional Internal Application Load Balancer):**
    *   **Capa:** 7 (HTTP/HTTPS).
    *   **Alcance:** Regional.
    *   **Caso de uso:** Balanceo de carga para arquitecturas de microservicios dentro de una VPC. Permite funcionalidades avanzadas de capa 7 como la gestión de rutas.

2.  **Balanceador de Carga de Red de Paso Interno (Internal Passthrough Network Load Balancer):**
    *   **Capa:** 4 (TCP/UDP).
    *   **Alcance:** Regional.
    *   **Caso de uso:** Balanceo de carga de alta velocidad para servicios internos que usan TCP/UDP.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear un balanceador de carga de aplicaciones externo y global para un MIG.

```bash
# (Prerrequisito: Tener un MIG llamado 'my-regional-mig' como en el lab anterior)

# 1. Crear una verificación de estado
gcloud compute health-checks create http my-http-health-check --port 80

# 2. Crear un servicio de backend y añadir el MIG
gcloud compute backend-services create my-web-backend-service \
    --protocol=HTTP \
    --health-checks=my-http-health-check \
    --global
gcloud compute backend-services add-backend my-web-backend-service \
    --instance-group=my-regional-mig \
    --instance-group-region=us-central1 \
    --global

# 3. Crear un mapa de URL para dirigir todo el tráfico al backend
gcloud compute url-maps create my-lb-url-map \
    --default-service my-web-backend-service

# 4. Crear el proxy de destino
gcloud compute target-http-proxies create my-http-target-proxy \
    --url-map=my-lb-url-map

# 5. Crear la regla de reenvío global con una IP estática
gcloud compute addresses create lb-ipv4-1 --ip-version=IPV4 --global
gcloud compute forwarding-rules create my-http-forwarding-rule \
    --address=lb-ipv4-1 \
    --target-http-proxy=my-http-target-proxy \
    --ports=80 \
    --global

# 6. Test (Verificación final): Envía tráfico al balanceador
LB_IP=$(gcloud compute addresses describe lb-ipv4-1 --global --format="value(address)")
echo "La IP del balanceador es: $LB_IP"
echo "Esperando 60 segundos para que el balanceador se active..."
sleep 60
curl -s $LB_IP
# Esperado: Deberías ver el mensaje de bienvenida de Nginx.
```

### 🧠 Lecciones Aprendidas

*   **El tipo de balanceador lo define todo:** La elección inicial (Global vs. Regional, Externo vs. Interno) determina las funcionalidades disponibles.
*   **Los balanceadores de capa 7 son más inteligentes:** Pueden tomar decisiones basadas en el contenido de la petición (URL, cabeceras), mientras que los de capa 4 solo miran la IP y el puerto.
*   **La IP Anycast es magia:** Para los balanceadores globales, una única IP enruta a los usuarios al backend de Google más cercano, reduciendo la latencia.

### 🤔 Errores y Confusiones Comunes

*   **Intentar usar Cloud CDN con un balanceador regional:** Cloud CDN solo funciona con el Balanceador de Carga de Aplicaciones Externo Global.
*   **Confundir los balanceadores de red:** El de "proxy" termina la conexión TCP en el balanceador, mientras que el de "paso" (passthrough) la envía directamente a la VM, preservando la IP del cliente.
*   **Backends no saludables:** La causa más común de errores 502 es que los backends no pasan la verificación de estado. Asegúrate de que las reglas de firewall permitan el tráfico de los rangos de IP de los health checkers de Google.

### 💡 Tips de Examen

*   **Pregunta de examen:** "Una aplicación web necesita servir contenido a usuarios de todo el mundo con baja latencia y alta disponibilidad. ¿Qué balanceador usar?" **Respuesta:** Global External Application Load Balancer.
*   **Pregunta de examen:** "Varios microservicios dentro de una VPC necesitan comunicarse entre sí de forma balanceada." **Respuesta:** Internal Application Load Balancer o Internal Passthrough Network Load Balancer, dependiendo del protocolo.
*   Recuerda la jerarquía de componentes: Regla de Reenvío -> Proxy -> Mapa de URL -> Servicio de Backend -> Backend (MIG).

### ✍️ Resumen

Cloud Load Balancing es un componente esencial para cualquier aplicación escalable y resiliente en GCP. Ofrece una gama de opciones para cubrir prácticamente cualquier caso de uso, desde aplicaciones web globales hasta microservicios internos. Entender la diferencia entre los tipos de balanceadores (Externo/Interno, Global/Regional, Capa 7/Capa 4) y sus componentes es fundamental para diseñar arquitecturas de red eficientes y robustas en Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-002-cloud-load-balancing)
