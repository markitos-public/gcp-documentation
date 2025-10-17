# 🕵️‍♂️ Caso Práctico: Troubleshooting de Fallos de Comunicación en un MIG

## 🎯 Objetivo

Este documento describe un flujo de trabajo sistemático para diagnosticar un problema común y complejo en una arquitectura de microservicios: un fallo intermitente de comunicación. Aprenderemos a usar el stack de observabilidad de Google Cloud (Monitoring, Trace, Logging y Debugger) de forma integrada para ir desde la detección del síntoma hasta la identificación de la causa raíz, aplicando una metodología de "embudo" (de lo general a lo específico).

---

## 🏗️ Escenario

### Arquitectura

*   **Servicio A:** Un microservicio frontend (ej. en App Engine) que actúa como cliente.
*   **Balanceador de Carga Externo:** Un balanceador de carga global (HTTP/S) que recibe las peticiones y las distribuye a los backends.
*   **Servicio B (MIG):** Un microservicio backend desplegado en un Grupo de Instancias Administrado (MIG) de Compute Engine. Este servicio se autoescala según la carga y es el responsable de procesar la lógica de negocio.

![Arquitectura del Escenario](https://storage.googleapis.com/gcp-prod-images/diagrams/troubleshooting-scenario.png)  
*(Diagrama conceptual de la arquitectura)*

### El Problema

El equipo de soporte informa que los usuarios del **Servicio A** están experimentando errores intermitentes. Las quejas incluyen mensajes de error genéricos y tiempos de espera agotados. El equipo de desarrollo del **Servicio A** confirma que su servicio parece estar bien, pero las llamadas que realiza al **Servicio B** a menudo fallan con errores **HTTP 502 (Bad Gateway)**.

**Nuestra misión:** Encontrar la causa raíz del problema.

---

## 🛠️ Metodología: El Embudo de Observabilidad

Abordaremos el problema como un SRE, haciendo preguntas cada vez más específicas y usando la herramienta adecuada para responder a cada una.

### Paso 1: ¿Está Roto? - La Visión General con Cloud Monitoring

**Pregunta clave:** ¿Es un problema real y cuantificable o son quejas aisladas? ¿Cuál es el impacto?

**Acciones:**

1.  **Revisar el Dashboard del Balanceador de Carga:** Es nuestro punto de entrada. En la consola de GCP, vamos a `Monitoring > Dashboards > GCP > Load Balancing`. Nos centramos en el panel "Backend Request Errors".
    *   **Hallazgo:** Observamos un aumento significativo en las respuestas con código `5xx`, específicamente `502`. Esto confirma que el problema es real y está ocurriendo entre el balanceador y nuestros backends (el MIG).

2.  **Revisar las Métricas del MIG:** En el mismo dashboard o en `Compute Engine > Instance groups`, miramos las métricas del MIG que aloja al **Servicio B**.
    *   **Hallazgo:** El uso de CPU y de red no parece estar en niveles de saturación. El número de instancias es estable. Esto sugiere que el problema podría no ser de sobrecarga, sino un error en la aplicación misma.

3.  **Verificar el Uptime Check:** Si tenemos un Uptime Check configurado contra la IP del balanceador, revisamos su estado.
    *   **Hallazgo:** El Uptime Check también muestra fallos intermitentes, confirmando que el servicio no está disponible de forma consistente desde la perspectiva de un cliente externo.

**Conclusión del Paso 1:** Cloud Monitoring nos ha confirmado que existe un problema real de errores `502` originado en la comunicación con los backends del MIG. El problema no parece ser de saturación de recursos. Necesitamos profundizar más.

---

### Paso 2: ¿Dónde está Roto? - El Viaje de la Solicitud con Cloud Trace

**Pregunta clave:** El balanceador no puede hablar con el backend, pero ¿en qué punto exacto de la comunicación se produce el fallo?

**Acciones:**

1.  **Filtrar Trazas Fallidas:** En la consola, vamos a `Trace > Trace list`. Aplicamos un filtro para encontrar las solicitudes que resultaron en un error 502. El filtro sería: `http.status_code:502`.

2.  **Analizar el Gráfico de Cascada (Waterfall Graph):** Seleccionamos una de las trazas fallidas para ver su detalle.
    *   **Hallazgo:** El gráfico de cascada nos muestra claramente el viaje: vemos un primer span largo que representa la llamada desde el **Servicio A** hasta el **Servicio B**. Vemos que este span principal tiene un error. Dentro de él, vemos un sub-span que representa la lógica interna del **Servicio B**, y es este el que está marcado en rojo y tiene el error.

**Conclusión del Paso 2:** Cloud Trace ha sido un bisturí. Nos ha permitido descartar problemas de red entre el cliente y el balanceador. El problema está definitivamente **dentro del código o el entorno de las instancias del Servicio B**.

---

### Paso 3: ¿Por qué está Roto? - La Evidencia en Cloud Logging

**Pregunta clave:** Sabemos que el código del **Servicio B** está fallando. ¿Qué error específico está ocurriendo?

**Acciones:**

1.  **Navegar desde Trace a Logging:** La forma más rápida es usar la integración. Desde el span fallido en Cloud Trace, hacemos clic en "Show Logs". Esto nos lleva directamente al Log Explorer, filtrando los logs exactos que se produjeron durante esa traza.

2.  **Buscar Logs de Error:** En el Log Explorer, buscamos logs con `severity=ERROR` o `CRITICAL`.
    *   **Hallazgo:** Encontramos varias entradas de error con un stack trace de la aplicación. Leyendo el stack trace, vemos un mensaje claro: `FATAL: password authentication failed for user "app_user"` o `Error: connect ECONNREFUSED 127.0.0.1:5432`.

**Conclusión del Paso 3:** Cloud Logging nos ha dado la "pistola humeante". El **Servicio B** no puede conectarse a su base de datos PostgreSQL. El error no es de red, sino de autenticación o conexión a la base de datos.

---

### Paso 4: ¿Cuál era el Estado del Código? - La Inspección con Cloud Debugger

**Pregunta clave:** El log dice que la conexión a la base de datos falla. Si el log no fuera tan claro, ¿cómo podríamos verificar qué credenciales o configuración de conexión se están usando en el momento del fallo?

**Acciones:**

1.  **Establecer una Snapshot:** En la consola, vamos a `Debugger`. Navegamos hasta el código fuente del **Servicio B**, específicamente a la función que crea la conexión con la base de datos.

2.  **Colocar la Snapshot:** Hacemos clic en el número de la línea justo antes de donde se intenta la conexión para establecer una snapshot.

3.  **Analizar la Captura:** Esperamos a que una nueva solicitud active la snapshot. Una vez capturada, el panel de Debugger nos muestra todas las variables locales en ese momento.
    *   **Hallazgo:** Al inspeccionar las variables, descubrimos que la variable `db_password` que se está pasando al conector de la base de datos es `null` o está vacía. También podríamos ver que la variable `db_host` apunta a `localhost` cuando debería apuntar a una IP de Cloud SQL.

**Conclusión del Paso 4:** Cloud Debugger nos permite confirmar la hipótesis de los logs de una manera irrefutable. Vemos el estado exacto de las variables en el momento del fallo, confirmando que se está intentando una conexión con credenciales incorrectas.

---

## 🏁 Conclusión Final y Causa Raíz

El viaje ha terminado. Hemos pasado de un vago "la web falla" a una causa raíz precisa:

*   **Síntoma:** Usuarios reciben errores `502` (detectado por **Monitoring**).
*   **Localización:** El error se origina en el **Servicio B** al ser llamado por el balanceador (identificado por **Trace**).
*   **Error Específico:** La aplicación en el **Servicio B** no puede conectarse a su base de datos (encontrado en **Logging**).
*   **Causa Raíz:** La variable que contiene la contraseña de la base de datos es nula en el momento de la conexión (verificado con **Debugger**). Probablemente, un cambio reciente en la configuración o en la forma de leer los secrets ha introducido este bug.

Con esta información, el equipo de desarrollo puede solucionar el problema de forma rápida y precisa.

### Resumen del Flujo de Trabajo

1.  **Monitoring:** ¿Hay un problema? (Dashboards, Alertas, Uptime Checks).
2.  **Trace:** ¿Dónde está el problema? (Análisis de latencia y errores en el grafo de la solicitud).
3.  **Logging:** ¿Por qué ocurre el problema? (Búsqueda de errores y stack traces).
4.  **Debugger/Profiler:** ¿Cuál es el estado exacto del código? (Inspección de variables o análisis de rendimiento a nivel de función).
