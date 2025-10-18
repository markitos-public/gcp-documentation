# culture Gestión de Incidentes y Postmortems

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#culture-gestión-de-incidentes-y-postmortems)

---

## 🧭 Descripción

Los fallos en sistemas complejos son inevitables. La diferencia entre un equipo SRE y uno de operaciones tradicional no es la ausencia de fallos, sino cómo se responde a ellos y, sobre todo, cómo se aprende de ellos. La gestión de incidentes es el proceso para responder y resolver un incidente, mientras que los postmortems son el mecanismo para aprender de él y prevenir su recurrencia, todo ello bajo una filosofía fundamental: la ausencia de culpa (blamelessness).

---

## 📘 Detalles

### Gestión de Incidentes

El objetivo principal durante un incidente es **restaurar el servicio** lo más rápido posible. No es el momento de depurar la causa raíz en profundidad. El proceso sigue una estructura clara:

1.  **Detección:** Una alerta (idealmente basada en el SLO) notifica al equipo de guardia (on-call).
2.  **Respuesta y Coordinación:** Se establece un **Comandante del Incidente (Incident Commander)** que coordina los esfuerzos, un **Líder de Comunicaciones** que mantiene informados a los stakeholders, y **Líderes de Operaciones** que ejecutan las acciones técnicas.
3.  **Mitigación:** Se aplican acciones para restaurar el servicio. Esto puede ser un rollback, desviar tráfico, o añadir más capacidad. La prioridad es la rapidez, no la elegancia.
4.  **Resolución:** Una vez que el servicio vuelve a operar dentro de su SLO, el incidente se considera resuelto.

### Postmortems sin Culpa (Blameless Postmortems)

Una vez resuelto el incidente, comienza el verdadero aprendizaje. Un postmortem es un documento que analiza el incidente en detalle.

**La Regla de Oro: Sin Culpa.**
La premisa es que los ingenieros actúan siempre con las mejores intenciones, basándose en la información que tenían en ese momento. El postmortem no busca un culpable ("¿Quién rompió el sistema?"), sino que se centra en entender las **causas sistémicas** ("¿Qué falló en el sistema —proceso, tecnología, monitorización— que permitió que el error ocurriera y que no se detectara antes?").

Un buen postmortem incluye:
*   **Resumen:** Impacto, duración, causa raíz.
*   **Cronología Detallada:** Una línea de tiempo de los eventos, decisiones y acciones.
*   **Análisis de la Causa Raíz:** ¿Por qué ocurrió el fallo técnico? ¿Por qué no se detectó antes? ¿Por qué la mitigación tardó tanto?
*   **Acciones a Tomar (Action Items):** Una lista de tareas concretas, con un propietario y una fecha de entrega, para prevenir que el incidente vuelva a ocurrir. Estas acciones deben ser mejoras de ingeniería, no "tener más cuidado la próxima vez".

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Documentar un Incidente Simulado
**Contexto:** No podemos causar un incidente real, pero podemos simular el proceso de documentación. Imaginemos que un despliegue defectuoso causó que nuestro servicio de App Engine devolviera errores 500, violando nuestro SLO. El incidente ya ha sido mitigado haciendo un rollback a la versión anterior. Ahora, crearemos la estructura de un postmortem en un fichero Markdown.

#### ARRANGE (Preparación del laboratorio)
*No se necesita ninguna acción técnica, ya que es un ejercicio de documentación.*
```bash
# Variables para el postmortem
export INCIDENT_ID="20251010-frontend-errors"
export START_TIME="2025-10-10 14:30 UTC"
export END_TIME="2025-10-10 14:55 UTC"
export DURATION="25 minutos"
export SLO_IMPACT="Quema del 15% del presupuesto de error mensual en 25 minutos."

# Crear el fichero del postmortem
export POSTMORTEM_FILE="postmortem-$INCIDENT_ID.md"
touch $POSTMORTEM_FILE
```

#### ACT (Implementación del escenario)
*Poblamos el fichero del postmortem con la estructura y la información clave del incidente simulado.*
```bash
# cat <<EOT > $POSTMORTEM_FILE: Es un comando de bash.
# 'cat' concatena y redirige texto. '<<EOT' (Here Document) permite escribir
# un bloque de texto multilínea directamente en la terminal, que se redirige ('>')
# al fichero especificado en $POSTMORTEM_FILE. 'EOT' es el delimitador que marca el fin del bloque.
# Escribir la plantilla del postmortem en el fichero
cat <<EOT > $POSTMORTEM_FILE
# Postmortem: $INCIDENT_ID - Errores 500 en Frontend

**Fecha:** 2025-10-10

## 1. Resumen

*   **Impacto:** Durante $DURATION, aproximadamente el 30% de los usuarios experimentaron errores 500. El SLO de disponibilidad fue impactado, consumiendo un $SLO_IMPACT.
*   **Causa Raíz:** Un cambio en la configuración de la base de datos (`max_connections`) no fue probado en el entorno de staging y causó que la aplicación agotara las conexiones bajo carga.
*   **Detección:** Alerta de Cloud Monitoring sobre "Tasa de Errores 5xx elevada" a las 14:32 UTC.
*   **Resolución:** Rollback a la versión anterior del código a las 14:50 UTC.

## 2. Cronología

*   `14:28` - Se despliega la versión `v1.2.3` con el cambio de configuración.
*   `14:32` - Se dispara la alerta de errores 5xx.
*   `14:35` - Comandante del Incidente declara un incidente y reúne al equipo.
*   `14:45` - Se identifica el despliegue reciente como la causa probable.
*   `14:50` - Se ejecuta el rollback a la versión `v1.2.2`.
*   `14:55` - La tasa de errores vuelve a la normalidad. Incidente resuelto.

## 3. Acciones a Tomar

| Acción | Tipo | Propietario | Fecha Límite |
|---|---|---|---|
| Añadir test de carga al pipeline de CI para validar cambios de config de BD | Prevención | @equipo-backend | 2025-11-01 |
| Crear alerta sobre el número de conexiones a la BD | Detección | @equipo-sre | 2025-10-20 |
| Automatizar el proceso de rollback con un solo comando | Mitigación | @equipo-sre | 2025-10-25 |

EOT
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que el fichero del postmortem ha sido creado y contiene la estructura correcta.*
```bash
# Mostrar el contenido del fichero postmortem
echo "\n=== Contenido del Postmortem Generado ==="
cat $POSTMORTEM_FILE
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar el fichero de ejemplo
rm $POSTMORTEM_FILE

echo "\n✅ Laboratorio de documentación completado."
```

---

## 💡 Lecciones Aprendidas

*   **La culpa es el enemigo del aprendizaje:** Si la gente tiene miedo a ser castigada, ocultará información y nunca se llegará a la verdadera causa raíz sistémica.
*   **Prioriza la restauración del servicio:** Durante un incidente, el objetivo no es encontrar la causa, es arreglar el problema. El análisis profundo viene después.
*   **Un postmortem sin acciones es inútil:** El resultado de un postmortem debe ser una lista de cambios concretos de ingeniería para hacer el sistema más robusto.

---

## ⚠️ Errores y Confusiones Comunes

*   **Buscar un culpable:** Centrarse en el error humano en lugar de en los fallos del sistema que permitieron que ese error humano tuviera un impacto.
*   **Escribir postmortems y no hacer nada:** Si las acciones a tomar no tienen un propietario y una fecha, nunca se implementarán.
*   **Hacer el postmortem demasiado tarde:** El análisis debe hacerse mientras los detalles están frescos en la memoria de todos.

---

## 🎯 Tips de Examen

*   **Cultura sin culpa (Blameless Culture):** Es un concepto clave de SRE y DevOps. Si una pregunta de escenario describe un fallo, la "mejor" respuesta SRE siempre se centrará en mejorar el sistema, no en culpar al individuo.
*   **Objetivo de la Gestión de Incidentes:** Restaurar el servicio lo más rápido posible.
*   **Resultado de un Postmortem:** Acciones a tomar (Action Items) para prevenir la recurrencia.

---

## 🧾 Resumen

La gestión de incidentes y los postmortems sin culpa son el corazón de la mejora continua en SRE. Permiten a los equipos no solo recuperarse rápidamente de los fallos, sino también aprender de ellos de una manera estructurada y colaborativa. Al centrarse en los fallos del sistema en lugar de en los errores humanos, las organizaciones construyen sistemas progresivamente más fiables y una cultura de confianza y seguridad psicológica.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#culture-gestión-de-incidentes-y-postmortems)
