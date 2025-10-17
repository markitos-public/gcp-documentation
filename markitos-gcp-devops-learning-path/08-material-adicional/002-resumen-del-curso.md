
# 📜 002: Resumen del Curso

## 📝 Índice

1.  [Introducción](#introducción)
2.  [Módulo 1: Fundamentos de GCP](#módulo-1-fundamentos-de-gcp)
3.  [Módulo 2: Máquinas Virtuales y Redes](#módulo-2-máquinas-virtuales-y-redes)
4.  [Módulo 3: Almacenamiento y Bases de Datos](#módulo-3-almacenamiento-y-bases-de-datos)
5.  [Módulo 4: Contenerización y Aplicaciones](#módulo-4-contenedores-y-aplicaciones)
6.  [Conclusión](#conclusión)
7.  [🔖 Firma](#firma)

---

### Introducción

Este documento resume los conceptos clave y las tecnologías cubiertas en el curso "Google Cloud Fundamentals: Core Infrastructure". El objetivo es servir como una guía de repaso rápido para consolidar el conocimiento adquirido sobre los pilares de la infraestructura de Google Cloud.

### Módulo 1: Fundamentos de GCP

*   **Jerarquía de Recursos:** La estructura de Organización -> Carpetas -> Proyectos -> Recursos es la base para la gestión de políticas y facturación.
*   **IAM (Identity and Access Management):** Define **quién** (Principal) puede hacer **qué** (Rol) en **qué recurso**. Es el pilar de la seguridad de acceso.
*   **Políticas de Organización:** Complementan a IAM, definiendo **qué se puede hacer** en los recursos (restringiendo configuraciones), independientemente de quién tenga acceso.
*   **Facturación:** Se gestiona a través de Cuentas de Facturación vinculadas a proyectos. Los presupuestos y las alertas son herramientas clave para el control de costos.

### Módulo 2: Máquinas Virtuales y Redes

*   **VPC (Virtual Private Cloud):** Es tu red privada y aislada en la nube. Las VPCs son globales y contienen subredes regionales.
*   **Compute Engine:** El servicio de IaaS (Infraestructura como Servicio) de GCP para crear y gestionar máquinas virtuales.
*   **Escalado y Alta Disponibilidad:** Se logran con **Grupos de Instancias Administradas (MIGs)**, que proporcionan **autoescalado** (ajuste de tamaño basado en la carga), **auto-reparación** (recreación de VMs fallidas) y **actualizaciones progresivas**.
*   **Cloud Load Balancing:** Ofrece una suite de balanceadores para distribuir el tráfico. La elección clave es entre **Externo vs. Interno** y **Global vs. Regional**.
*   **Conectividad Híbrida:** **Cloud VPN** para conexiones seguras sobre Internet y **Cloud Interconnect** para conexiones físicas dedicadas a tu centro de datos.
*   **DNS y CDN:** **Cloud DNS** para la resolución de nombres de dominio (públicos y privados) y **Cloud CDN** para cachear contenido cerca de los usuarios, mejorando la latencia.

### Módulo 3: Almacenamiento y Bases de Datos

*   **Cloud Storage:** Almacenamiento de objetos unificado, escalable y duradero. Ideal para archivos, backups y multimedia. Las **clases de almacenamiento** (Standard, Nearline, etc.) y las **políticas de ciclo de vida** son clave para optimizar costos.
*   **Persistent Disk:** Almacenamiento de bloques para VMs.
*   **Cloud SQL:** Servicio gestionado para bases de datos relacionales (MySQL, PostgreSQL, SQL Server) de escala regional.
*   **Cloud Spanner:** Base de datos relacional única, que ofrece consistencia estricta con escalabilidad horizontal y alcance global.
*   **Firestore:** Base de datos de documentos NoSQL, ideal para aplicaciones web/móviles con sincronización en tiempo real y soporte offline.
*   **Bigtable:** Base de datos de columna ancha NoSQL para cargas de trabajo masivas de ingesta y análisis (IoT, series temporales) con muy baja latencia.

### Módulo 4: Contenerización y Aplicaciones

*   **Contenedores:** Un formato de empaquetado de software ligero y portable que aísla las aplicaciones.
*   **Kubernetes:** El orquestador de contenedores de código abierto estándar de la industria.
*   **Google Kubernetes Engine (GKE):** El servicio gestionado de Kubernetes de GCP, que automatiza el despliegue, la administración y el escalado de aplicaciones en contenedores.
*   **Cloud Run:** Una plataforma de computación sin servidor (serverless) para ejecutar contenedores sin gestionar la infraestructura subyacente. Escala a cero para ahorrar costos.

### Conclusión

La infraestructura principal de Google Cloud proporciona un conjunto completo de herramientas para construir aplicaciones seguras, escalables y de alta disponibilidad. Desde la gestión de la identidad y la red hasta una amplia gama de opciones de cómputo y almacenamiento, dominar estos servicios fundamentales es el primer paso para convertirse en un profesional eficaz en el ecosistema de GCP.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-002-resumen-del-curso)
