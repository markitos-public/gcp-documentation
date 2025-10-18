
# 📜 007: Cloud Bigtable

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Modelo de Datos: Columna Ancha](#modelo-de-datos-columna-ancha)
3.  [Arquitectura y Rendimiento](#arquitectura-y-rendimiento)
4.  [Cuándo Usar Bigtable](#cuándo-usar-bigtable)
5.  [Bigtable vs. Otras Bases de Datos](#bigtable-vs-otras-bases-de-datos)
6.  [🧪 Laboratorio Práctico (Conceptual)](#-laboratorio-práctico-conceptual)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

**Cloud Bigtable** es la base de datos NoSQL de columna ancha, dispersa y de alto rendimiento de Google. Es el mismo servicio de base de datos que impulsa muchas de las aplicaciones más grandes de Google, como la Búsqueda, Analytics, Maps y Gmail. Está diseñada para manejar petabytes de datos y mantener una latencia de lectura y escritura muy baja (milisegundos de un solo dígito) a una escala masiva.

Bigtable no es una base de datos de propósito general; es una herramienta especializada para cargas de trabajo analíticas y operativas muy grandes.

### Modelo de Datos: Columna Ancha

El modelo de datos de Bigtable es diferente al de las bases de datos relacionales o de documentos.

*   **Tabla:** Al igual que en una base de datos relacional, los datos se organizan en tablas.
*   **Fila (Row):** Cada fila en una tabla tiene una única **clave de fila (row key)**. La clave de fila es el único índice de la tabla y es fundamental para el diseño del esquema. Las filas se ordenan lexicográficamente por su clave.
*   **Columna (Column):** Las columnas se agrupan en **familias de columnas (column families)**. Una familia de columnas agrupa un conjunto de columnas relacionadas.
*   **Celda (Cell):** La intersección de una fila y una columna forma una celda. Cada celda puede contener múltiples versiones del mismo dato, con una **marca de tiempo (timestamp)**. Bigtable guarda automáticamente las versiones de los datos.
*   **Dispersa (Sparse):** Las tablas son dispersas. Si una fila no tiene un valor para una columna en particular, no ocupa espacio. Esto es ideal para datos con muchos atributos opcionales.

**Analogía:** Piensa en una tabla de Bigtable como un `Map<RowKey, Map<ColumnFamily, Map<Column, List<Value_with_Timestamp>>>>` gigante y persistente.

### Arquitectura y Rendimiento

*   **Separación de Cómputo y Almacenamiento:** Al igual que Spanner, Bigtable separa sus nodos de cómputo (que manejan las peticiones de lectura/escritura) de su capa de almacenamiento (Colossus). Esto permite un escalado independiente y elástico.
*   **Escalado Lineal:** El rendimiento de Bigtable escala linealmente. Si duplicas el número de nodos en tu clúster, duplicas el número de consultas por segundo (QPS) que puede manejar.
*   **Diseño de la Clave de Fila (Row Key Design):** Es el aspecto más importante para lograr un buen rendimiento. Una clave de fila bien diseñada distribuye las lecturas y escrituras de manera uniforme entre los nodos del clúster, evitando "puntos calientes" (hotspots). Las claves de fila mal diseñadas (ej. usar un timestamp al principio) pueden hacer que todo el tráfico se dirija a un solo nodo, anulando los beneficios del escalado.

### Cuándo Usar Bigtable

Bigtable sobresale en cargas de trabajo que implican grandes volúmenes de datos (generalmente más de 1 TB) y requieren una alta tasa de transferencia de lectura y escritura.

*   **Casos de Uso Típicos:**
    *   **Datos de Series Temporales (Time-series):** Datos de sensores de IoT, métricas de monitorización de sistemas, datos de mercado financiero.
    *   **Análisis a Gran Escala:** Como backend para trabajos de machine learning o como fuente de datos para paneles de control analíticos.
    *   **Ingesta de Datos Masiva:** Procesamiento de flujos de datos de alta velocidad.
    *   **Personalización y Recomendaciones:** Almacenar perfiles de usuario o catálogos de productos para una rápida recuperación.

**NO uses Bigtable si:**

*   Necesitas transacciones ACID o consultas SQL complejas (usa Cloud SQL o Spanner).
*   Tu conjunto de datos es pequeño (menos de 1 TB).
*   Buscas una base de datos de propósito general para una aplicación web simple (usa Firestore o Cloud SQL).

### Bigtable vs. Otras Bases de Datos

*   **Bigtable vs. Spanner:** Ambos escalan masivamente, pero Bigtable es NoSQL (columna ancha) para cargas analíticas/operativas, mientras que Spanner es relacional (SQL) para cargas transaccionales (OLTP).
*   **Bigtable vs. BigQuery:** Bigtable es una base de datos, optimizada para lecturas y escrituras rápidas de claves individuales (búsquedas de tipo `lookup`). BigQuery es un data warehouse, optimizado para consultas analíticas a gran escala que escanean tablas enteras (consultas de tipo `scan`). A menudo se usan juntos: los datos se ingieren en Bigtable y luego se cargan en BigQuery para su análisis.
*   **Bigtable vs. Firestore:** Bigtable está diseñado para un rendimiento masivo en el backend. Firestore está diseñado para el desarrollo de aplicaciones, con SDKs de cliente y sincronización en tiempo real.

### 🧪 Laboratorio Práctico (Conceptual)

La interacción con Bigtable se realiza principalmente a través de sus SDKs (Java, Go, Python) o la herramienta de línea de comandos `cbt`. `gcloud` tiene un soporte mínimo.

**Objetivo:** Crear una instancia, una tabla e insertar una fila.

```bash
# 1. Crear una instancia de Bigtable (un clúster de nodos)
gcloud bigtable instances create my-bigtable-instance \
    --display-name="Mi Instancia de Bigtable" \
    --cluster-config=id=my-cluster,zone=us-central1-b,nodes=1

# 2. Crear una tabla con una familia de columnas
# Usamos la herramienta 'cbt' que viene con el SDK de gcloud
cbt -instance my-bigtable-instance createtable my-table families=stats

# 3. Insertar datos en una fila
# Clave de fila: 'user123'. Familia: 'stats'. Columna: 'clicks'. Valor: 10
cbt -instance my-bigtable-instance set my-table user123 stats:clicks=10

# 4. Test (Verificación): Leer los datos de la fila
cbt -instance my-bigtable-instance read my-table user123
# Esperado: Debería mostrar la fila 'user123' con la columna 'stats:clicks' y su valor.
```

### 💡 Tips de Examen

*   Las palabras clave para Bigtable son: **NoSQL de columna ancha, alto rendimiento (high-throughput), baja latencia, petabytes, IoT, series temporales, analítica.**
*   **Diseño de la Clave de Fila:** Si una pregunta menciona problemas de rendimiento en Bigtable, la causa más probable es un mal diseño de la clave de fila que está creando un "hotspot".
*   **Bigtable no es SQL:** No admite uniones (joins) ni transacciones complejas.
*   Recuerda la relación con BigQuery: Bigtable para ingesta y búsquedas rápidas, BigQuery para análisis complejos.

### ✍️ Resumen

Cloud Bigtable es una base de datos especializada y extremadamente potente para cargas de trabajo masivas. Su modelo de datos de columna ancha y su arquitectura de escalado lineal la convierten en la elección perfecta para aplicaciones de IoT, análisis de series temporales y cualquier escenario que requiera una ingesta y recuperación de datos a una escala que las bases de datos tradicionales no pueden manejar. El éxito con Bigtable depende en gran medida de un diseño cuidadoso del esquema, especialmente de la clave de fila.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-007-cloud-bigtable)
