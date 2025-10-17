# ☁️ Caso Práctico: RCA de Lentitud en App con el Stack de Observabilidad

## 📑 Índice

* [🧭 Escenario del Problema](#-escenario-del-problema)
* [🛠️ Herramientas Utilizadas](#️-herramientas-utilizadas)
* [🕵️‍♂️ Proceso de Análisis de Causa Raíz (RCA)](#️-proceso-de-análisis-de-causa-raíz-rca)
* [🔬 Laboratorio Práctico (Simulación y Análisis)](#-laboratorio-práctico-simulación-y-análisis)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Escenario del Problema

Los usuarios de una aplicación web de comercio electrónico, que se ejecuta en Cloud Run, reportan que la página para ver los detalles de un producto a veces tarda mucho en cargar (más de 5 segundos), mientras que otras páginas funcionan con normalidad. El equipo de SRE recibe una alerta de **Cloud Monitoring** que indica que la latencia del 95 percentil para el servicio de Cloud Run ha superado el umbral definido en el SLO.

**Objetivo:** Utilizar el stack de observabilidad de Google Cloud (Monitoring, Logging, Trace) para identificar la causa raíz de la latencia, desde el síntoma inicial hasta el problema de fondo, y proponer una solución.

---

## 🛠️ Herramientas Utilizadas

1.  **Cloud Monitoring (Metrics):** Para la visión general del rendimiento. Usaremos el **Metrics Explorer** y los **Dashboards** para visualizar la latencia, el número de peticiones y la utilización de recursos.
2.  **Cloud Trace:** Para descomponer una petición individual en sus componentes (spans) y ver dónde se está gastando el tiempo (ej. llamada a la base de datos, a una API externa, etc.).
3.  **Cloud Logging (Logs):** Para obtener contexto detallado sobre lo que estaba ocurriendo en la aplicación en el momento de una petición lenta. Usaremos el **Logs Explorer** y correlacionaremos los logs con las trazas.

---

## 🕵️‍♂️ Proceso de Análisis de Causa Raíz (RCA)

El proceso sigue un embudo, desde lo más general a lo más específico.

1.  **MACRO (Monitoring): ¿Qué está pasando?**
    *   Se empieza en el dashboard de Cloud Monitoring o en el Metrics Explorer.
    *   Se observa la métrica de latencia (`run.googleapis.com/request_latencies`) del servicio de Cloud Run.
    *   Se confirma el pico de latencia reportado por la alerta. Se correlaciona con otras métricas: ¿subió también el número de peticiones? ¿La utilización de CPU o memoria?
    *   En este escenario, vemos que la latencia sube, pero el tráfico y la CPU no han variado significativamente. Esto sugiere que el problema no es de sobrecarga, sino de eficiencia en el procesamiento de ciertas peticiones.

2.  **MESO (Trace): ¿Dónde está pasando?**
    *   Desde el dashboard de Monitoring, se puede saltar directamente a las trazas asociadas a un período de tiempo problemático.
    *   En Cloud Trace, se filtra por las peticiones con mayor latencia (ej. `latency > 5s`).
    *   Se selecciona una traza de una petición lenta. El diagrama de Gantt de la traza muestra varios "spans" o tramos. Se busca el span que consume la mayor parte del tiempo.
    *   En nuestro escenario, la traza muestra un span principal de 5 segundos, y dentro de él, un span de 4.8 segundos etiquetado como `CloudSQL: SELECT * FROM products WHERE id=...`. **Hemos aislado el problema a una consulta a la base de datos.**

3.  **MICRO (Logging): ¿Por qué está pasando?**
    *   Cada traza está correlacionada con los logs de la petición correspondiente. Desde Cloud Trace, se puede hacer clic en "Ver Logs".
    *   Esto abre el Logs Explorer con un filtro predefinido (`trace=...`) que muestra solo los logs de esa petición lenta.
    *   Se revisan los logs de la aplicación. Podríamos encontrar un log que diga: `Query for product ID 12345 took 4850ms. Query plan shows a full table scan.`
    *   **¡Bingo!** La consulta a la base de datos está realizando un escaneo completo de la tabla (`full table scan`) en lugar de usar un índice, lo que es extremadamente ineficiente para tablas grandes.

**Conclusión del RCA:** La causa raíz de la latencia es una consulta SQL ineficiente a la base de datos, probablemente debido a la falta de un índice en la columna `id` de la tabla `products`.

---

## 🔬 Laboratorio Práctico (Simulación y Análisis)

Este laboratorio se centra en el análisis, asumiendo que una aplicación instrumentada ya está generando datos.

### ARRANGE (Preparación)

*   Asumimos que existe un servicio de Cloud Run con instrumentación para Trace y Logging.
*   Asumimos que este servicio se conecta a una instancia de Cloud SQL (PostgreSQL).
*   En la tabla `products` de la base de datos, nos aseguramos de que **NO** haya un índice en la columna por la que buscamos.

### ACT (Análisis en la Consola)

1.  **Ir a Cloud Monitoring > Metrics Explorer:**
    *   **Recurso:** `Cloud Run Revision`
    *   **Métrica:** `Request Latencies` (`run.googleapis.com/request_latencies`)
    *   **Agregación:** `95th percentile`
    *   **Visualización:** Observar el gráfico y localizar un pico de latencia.

2.  **Saltar a Cloud Trace:**
    *   En el gráfico de Monitoring, selecciona un punto de datos en el pico de latencia y haz clic en "Ver Trazas".
    *   En la lista de trazas, busca una con una duración alta (ej. > 5000 ms).
    *   Haz clic en ella para ver el diagrama de cascada (waterfall).
    *   Identifica el span más largo. En nuestro caso, será una llamada a la base de datos.

3.  **Correlacionar con Cloud Logging:**
    *   Dentro de la vista de la traza, busca el panel de "Logs" o el botón "Mostrar Logs".
    *   Esto te llevará al Logs Explorer con el filtro de traza ya aplicado.
    *   Busca en los logs de la aplicación mensajes relacionados con la ejecución de consultas SQL. Un buen log de aplicación incluiría la consulta ejecutada y el tiempo que tardó.

### ASSERT (Confirmación y Solución)

1.  **Confirmación:** Los pasos anteriores nos confirman que el problema es una consulta lenta a la base de datos.
2.  **Solución Propuesta:** Añadir un índice a la columna `id` de la tabla `products`.
    ```sql
    CREATE INDEX idx_products_id ON products(id);
    ```
3.  **Verificación Post-Implementación:** Después de aplicar el índice, se vuelve a observar la métrica de latencia en Cloud Monitoring. El pico de latencia debería haber desaparecido, y las nuevas trazas para la misma petición deberían mostrar una duración de milisegundos en lugar de segundos.

---

## 💡 Lecciones Aprendidas

*   **El Flujo de Observabilidad es un Embudo:** Se empieza con una vista de 10,000 pies (Monitoring) para saber *qué* pasa, se baja a 1,000 pies (Trace) para saber *dónde*, y se aterriza a nivel del suelo (Logging) para entender el *porqué*.
*   **La Instrumentación es Requisito Previo:** Nada de esto funciona si la aplicación no está correctamente instrumentada. Las bibliotecas de cliente de Google Cloud para logging y tracing facilitan enormemente este trabajo.
*   **Los Logs Deben Tener Contexto:** Un buen log no solo dice "Error", sino que incluye el ID de la petición, el ID del usuario, la traza y cualquier variable relevante. Esto es lo que permite conectar un problema a una causa específica.

---

## 🧾 Resumen

El stack de observabilidad de GCP proporciona un flujo de trabajo potente y cohesionado para el análisis de causa raíz. Pasando sistemáticamente de las métricas agregadas en Cloud Monitoring, a las trazas distribuidas en Cloud Trace, y finalmente a los logs detallados en Cloud Logging, los ingenieros pueden diagnosticar eficientemente problemas de rendimiento complejos, aislando la causa desde un síntoma a nivel de sistema hasta una línea de código o una consulta de base de datos específica.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-caso-práctico-rca-de-lentitud-en-app-con-el-stack-de-observabilidad)
