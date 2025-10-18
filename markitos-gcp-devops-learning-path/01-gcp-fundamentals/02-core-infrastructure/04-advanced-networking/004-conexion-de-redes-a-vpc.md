
# 📜 004: Conexión de Redes a VPC (Conectividad Híbrida)

## 📝 Índice

1.  [Descripción](#descripción)
2.  [El Desafío de la Conectividad Híbrida](#el-desafío-de-la-conectividad-híbrida)
3.  [Cloud VPN](#cloud-vpn)
4.  [Cloud Interconnect](#cloud-interconnect)
5.  [Network Connectivity Center](#network-connectivity-center)
6.  [Tabla Comparativa](#tabla-comparativa)
7.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

La **conectividad híbrida** se refiere a la conexión de tu red on-premise (tu centro de datos corporativo) con tu red de nube privada virtual (VPC) en Google Cloud. Esta conexión es fundamental para la mayoría de las empresas, ya que les permite migrar cargas de trabajo gradualmente, crear arquitecturas que abarcan ambos entornos y permitir que los recursos en la nube accedan a datos o servicios on-premise de forma segura.

GCP ofrece un conjunto de servicios para establecer esta conectividad, principalmente **Cloud VPN** y **Cloud Interconnect**.

### El Desafío de la Conectividad Híbrida

El objetivo es extender tu red corporativa a GCP de forma segura y fiable. Las principales consideraciones al elegir una solución son:

*   **Ancho de banda:** ¿Cuántos datos necesitas transferir?
*   **Latencia:** ¿Qué tan sensible es tu aplicación a los retrasos de la red?
*   **Fiabilidad y SLA:** ¿Qué nivel de disponibilidad necesitas?
*   **Costo:** ¿Cuál es tu presupuesto?

### Cloud VPN

*   **¿Qué es?** Establece una conexión segura entre tu red on-premise y tu VPC a través de un **túnel IPsec** que viaja por la Internet pública. Es la forma más rápida y sencilla de empezar con la conectividad híbrida.
*   **Tipos:**
    1.  **HA VPN (High Availability VPN):** La solución recomendada para producción. Crea un par de túneles redundantes con un SLA del 99.99%. Requiere configurar dos túneles en tu dispositivo VPN on-premise. Utiliza enrutamiento dinámico con BGP (Border Gateway Protocol).
    2.  **Classic VPN:** La versión anterior. Generalmente crea un solo túnel con un SLA del 99.9%. Admite enrutamiento estático y dinámico. Se considera heredada y se debe preferir HA VPN para nuevas implementaciones.
*   **Caso de Uso:** Cargas de trabajo con requisitos de ancho de banda de bajos a moderados (hasta varios Gbps). Ideal para empezar, para entornos de desarrollo/pruebas, o como respaldo de una conexión de Interconnect.

#### Arquitectura de HA VPN para Alta Disponibilidad

La garantía del SLA del 99.99% de HA VPN no es magia, sino el resultado de una arquitectura redundante y dinámica.

*   **Componentes:** Una puerta de enlace de HA VPN en GCP tiene **dos interfaces**, cada una con su propia dirección IP externa. Debes configurar **dos túneles VPN** desde tu puerta de enlace on-premise, uno hacia cada una de las interfaces de la puerta de enlace de GCP.

*   **Topología Activo-Activo:** Ambos túneles están siempre activos. No es una configuración activo-pasivo. El tráfico puede fluir por ambos túneles simultáneamente.

*   **Enrutamiento Dinámico con BGP:** Aquí está la clave del failover automático. Se establece una sesión BGP sobre cada túnel. A través de BGP, los routers de ambos lados (GCP y on-premise) intercambian y aprenden las rutas de red. Si un túnel falla (por un problema de red o en el hardware), la sesión BGP de ese túnel se cae. El router BGP se da cuenta inmediatamente de que las rutas a través de ese túnel ya no son válidas y **automáticamente desvía todo el tráfico al segundo túnel**, que permanece activo. Este proceso es automático y tarda solo unos segundos, garantizando una interrupción mínima o nula.

*   **Redundancia Completa:** Para una verdadera resiliencia de extremo a extremo, la topología recomendada implica tener dos puertas de enlace VPN también en el lado on-premise, con cada una conectándose a la puerta de enlace de HA VPN de GCP. Esto protege contra fallos tanto en la red de GCP como en tu propio hardware.

### Cloud Interconnect

*   **¿Qué es?** Proporciona una conexión física y privada de baja latencia y alta disponibilidad entre tu red on-premise y la red de Google. El tráfico **no viaja por la Internet pública**, lo que ofrece mayor rendimiento y seguridad.
*   **Tipos:**
    1.  **Dedicated Interconnect:**
        *   **Concepto:** Obtienes una conexión física directa (un puerto) a la red de Google en una ubicación de coubicación (colocation facility).
        *   **Ancho de banda:** Circuitos de 10 Gbps o 100 Gbps.
        *   **SLA:** Hasta 99.99% con configuración redundante.
        *   **Caso de Uso:** Cargas de trabajo a gran escala que necesitan transferir terabytes de datos con un rendimiento constante y baja latencia.

    2.  **Partner Interconnect:**
        *   **Concepto:** Te conectas a la red de Google a través de un proveedor de servicios asociado. Es más flexible si no te encuentras en una de las ubicaciones de Dedicated Interconnect.
        *   **Ancho de banda:** Conexiones desde 50 Mbps hasta 50 Gbps.
        *   **SLA:** Depende del proveedor, pero puede llegar al 99.99%.
        *   **Caso de Uso:** Empresas que necesitan una conexión privada pero no requieren un circuito dedicado de 10 Gbps, o que prefieren la flexibilidad de un proveedor.

### Network Connectivity Center

*   **¿Qué es?** Es un servicio de gestión centralizada que utiliza la red troncal de Google para conectar tus diferentes redes empresariales (VPCs, VPNs, Interconnects, redes de terceros) en un modelo de **hub-and-spoke**.
*   **Caso de Uso:** Simplificar la gestión de redes complejas a gran escala, permitiendo que diferentes sitios on-premise se comuniquen entre sí a través de la red de Google, en lugar de tener que enrutar el tráfico a través de tu centro de datos principal.

### Tabla Comparativa

| Característica      | HA VPN                                  | Dedicated Interconnect                  | Partner Interconnect                    |
| ------------------- | --------------------------------------- | --------------------------------------- | --------------------------------------- |
| **Medio**           | Internet Pública (cifrado)              | Fibra privada directa a Google          | Fibra privada a través de un partner    |
| **Ancho de Banda**  | Moderado (Gbps por túnel)               | Muy Alto (10/100 Gbps)                  | Flexible (50 Mbps - 50 Gbps)            |
| **Latencia**        | Variable                                | Muy baja y predecible                   | Baja y predecible                       |
| **SLA**             | 99.99%                                  | 99.99%                                  | Hasta 99.99% (depende del partner)      |
| **Caso de Uso**     | Entornos de dev/test, backup, bajo tráfico | Cargas masivas de datos, alta demanda   | Conectividad privada flexible           |

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear una puerta de enlace y un túnel de Classic VPN (por simplicidad en el lab).

```bash
# (La configuración de HA VPN es más compleja y requiere BGP)
# Este es un ejemplo simplificado de Classic VPN con enrutamiento estático.

# 1. Crear la puerta de enlace de Cloud VPN en GCP
gcloud compute target-vpn-gateways create my-vpn-gateway --network=vpc-a --region=us-central1

# 2. Crear la regla de reenvío para la puerta de enlace
gcloud compute forwarding-rules create my-vpn-rule --region=us-central1 \
    --ip-protocol=ESP --address=[VPN_GATEWAY_IP] --target-vpn-gateway=my-vpn-gateway

# 3. Crear el túnel VPN
# [PEER_IP] es la IP pública de tu router VPN on-premise
gcloud compute vpn-tunnels create my-vpn-tunnel --region=us-central1 \
    --peer-ip-address=[PEER_IP] \
    --target-vpn-gateway=my-vpn-gateway \
    --ike-version=2 \
    --shared-secret="YOUR_SECRET_KEY"

# 4. Crear una ruta estática para dirigir el tráfico on-premise a través del túnel
# [ON_PREM_RANGE] es el rango de IP de tu red local (ej. 192.168.0.0/24)
gcloud compute routes create route-to-on-prem --network=vpc-a \
    --destination-range=[ON_PREM_RANGE] \
    --next-hop-vpn-tunnel=my-vpn-tunnel \
    --next-hop-vpn-tunnel-region=us-central1
```

### 💡 Tips de Examen

*   **VPN vs. Interconnect:** Es la decisión más común en las preguntas. Si se menciona **Internet pública**, la respuesta es **VPN**. Si se habla de **conexión dedicada, privada o de baja latencia/alto ancho de banda**, la respuesta es **Interconnect**.
*   **Dedicated vs. Partner Interconnect:** Si la pregunta implica la necesidad de un circuito masivo de **10 Gbps o 100 Gbps** y estar en una ubicación de coubicación, es **Dedicated**. Si se necesita más **flexibilidad** en el ancho de banda o la ubicación, es **Partner**.
*   **HA VPN:** Si se requiere un SLA del **99.99%** sobre VPN, la respuesta es **HA VPN**.

### ✍️ Resumen

La conectividad híbrida es un pilar de la adopción de la nube en la empresa. Cloud VPN ofrece una solución rápida y segura sobre la Internet pública, ideal para empezar o para cargas de trabajo no intensivas. Cloud Interconnect (Dedicated y Partner) proporciona una conexión privada de nivel empresarial para las cargas de trabajo más exigentes en términos de rendimiento y fiabilidad. La elección entre estas opciones depende de un análisis cuidadoso de los requisitos de ancho de banda, latencia, seguridad y costo.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-004-conexión-de-redes-a-vpc-conectividad-híbrida)
