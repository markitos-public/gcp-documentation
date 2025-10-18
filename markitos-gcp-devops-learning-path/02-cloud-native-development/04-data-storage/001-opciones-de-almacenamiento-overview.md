
# 📜 001: Opciones de Almacenamiento - Overview

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Las Tres Categorías de Almacenamiento](#las-tres-categorías-de-almacenamiento)
3.  [Bases de Datos en GCP](#bases-de-datos-en-gcp)
4.  [El Árbol de Decisión del Almacenamiento](#el-árbol-de-decisión-del-almacenamiento)
5.  [✍️ Resumen](#resumen)
6.  [🔖 Firma](#firma)

---

### Descripción

Elegir la solución de almacenamiento correcta es una de las decisiones de arquitectura más críticas en la nube. Una elección incorrecta puede llevar a un rendimiento deficiente, costos elevados o una escalabilidad limitada. Google Cloud ofrece un portfolio completo de servicios de almacenamiento y bases de datos, cada uno diseñado para un caso de uso específico.

Este documento proporciona una visión general de alto nivel de las opciones disponibles para ayudarte a navegar por este ecosistema.

### Las Tres Categorías de Almacenamiento

Primero, es fundamental entender las primitivas de almacenamiento fundamentales:

1.  **Almacenamiento de Bloques (Block Storage):**
    *   **Analogía:** Un disco duro virtual (SSD o HDD).
    *   **Concepto:** El almacenamiento se presenta al sistema operativo como un volumen en bruto (un "bloque"). El sistema operativo lo formatea con un sistema de archivos (ext4, NTFS) y lo monta.
    *   **Producto en GCP:** **Persistent Disk**. Se adjunta a las VMs de Compute Engine.
    *   **Caso de Uso:** Discos de arranque de VMs, bases de datos de alto rendimiento que gestionan su propia replicación (ej. MySQL auto-gestionado).

2.  **Almacenamiento de Archivos (File Storage):**
    *   **Analogía:** Una unidad de red compartida (NAS).
    *   **Concepto:** Proporciona un sistema de archivos de red que puede ser montado y compartido por múltiples clientes simultáneamente (lectura/escritura concurrente).
    *   **Producto en GCP:** **Filestore**.
    *   **Caso de Uso:** Servidores de archivos compartidos, gestión de contenido web, migraciones de aplicaciones que dependen de un NAS on-premise.

3.  **Almacenamiento de Objetos (Object Storage):**
    *   **Analogía:** Un sistema de almacenamiento de archivos masivo con una API web.
    *   **Concepto:** Almacena datos como "objetos" inmutables en contenedores planos llamados "buckets". No hay jerarquía de directorios; la estructura es una ilusión creada por los nombres de los objetos (ej. `images/cats/fluffy.jpg`). Se accede a través de una API RESTful (HTTP).
    *   **Producto en GCP:** **Cloud Storage**.
    *   **Caso de Uso:** Almacenamiento de archivos multimedia, backups y archivos, data lakes para Big Data, hosting de sitios web estáticos.

### Bases de Datos en GCP

Google Cloud ofrece una amplia gama de bases de datos gestionadas, que se pueden clasificar en dos grandes grupos:

1.  **Bases de Datos Relacionales (SQL):**
    *   **Concepto:** Estructuran los datos en tablas con filas y columnas, y utilizan SQL (Structured Query Language) para las consultas. Garantizan la consistencia transaccional (ACID).
    *   **Productos en GCP:**
        *   **Cloud SQL:** Un servicio totalmente gestionado para MySQL, PostgreSQL y SQL Server. Ideal para aplicaciones web tradicionales, CRM, ERP.
        *   **Cloud Spanner:** La única base de datos relacional del mundo que es globalmente consistente y escalable horizontalmente. Combina los beneficios de las bases de datos relacionales (consistencia, SQL) con la escalabilidad de las NoSQL. Ideal para finanzas, logística global, juegos a gran escala.

2.  **Bases de Datos No Relacionales (NoSQL):**
    *   **Concepto:** No utilizan el modelo de tablas tradicional. Ofrecen modelos de datos flexibles (documentos, clave-valor, columna ancha) y suelen priorizar la escalabilidad y la velocidad sobre la consistencia estricta.
    *   **Productos en GCP:**
        *   **Firestore:** Una base de datos de documentos flexible y escalable, con potentes capacidades de consulta y sincronización en tiempo real. Ideal para aplicaciones móviles, catálogos de productos, perfiles de usuario.
        *   **Bigtable:** Una base de datos de columna ancha de altísimo rendimiento, diseñada para cargas de trabajo analíticas y operativas a gran escala (terabytes a petabytes). No es para transacciones. Ideal para IoT, series temporales, análisis de datos masivos.

### El Árbol de Decisión del Almacenamiento

Para elegir el servicio correcto, hazte estas preguntas:

1.  **¿Necesito almacenamiento a nivel de bloque para una VM?** -> **Persistent Disk**.
2.  **¿Necesito un sistema de archivos compartido (NAS)?** -> **Filestore**.
3.  **¿Necesito almacenar archivos, backups o multimedia a gran escala?** -> **Cloud Storage**.
4.  **¿Necesito una base de datos relacional (SQL) para una aplicación web estándar?** -> **Cloud SQL**.
5.  **¿Necesito una base de datos relacional con escalabilidad horizontal y consistencia global?** -> **Cloud Spanner**.
6.  **¿Necesito una base de datos de documentos flexible para una aplicación web/móvil con sincronización en tiempo real?** -> **Firestore**.
7.  **¿Necesito ingerir y analizar cantidades masivas de datos (IoT, analítica)?** -> **Bigtable**.

### ✍️ Resumen

Google Cloud proporciona una solución de almacenamiento para cada necesidad. **Persistent Disk** ofrece almacenamiento de bloques para VMs, **Filestore** proporciona almacenamiento de archivos en red, y **Cloud Storage** es la solución de facto para el almacenamiento de objetos a escala de petabytes. En el mundo de las bases de datos, **Cloud SQL** cubre las necesidades relacionales tradicionales, mientras que **Spanner** ofrece una escala global sin precedentes. Para cargas de trabajo NoSQL, **Firestore** proporciona flexibilidad para aplicaciones, y **Bigtable** ofrece un rendimiento extremo para datos a gran escala.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-001-opciones-de-almacenamiento---overview)
