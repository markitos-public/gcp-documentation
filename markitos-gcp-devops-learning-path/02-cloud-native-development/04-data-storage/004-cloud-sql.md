
# 📜 004: Cloud SQL

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Características Clave](#características-clave)
3.  [Alta Disponibilidad (High Availability)](#alta-disponibilidad-high-availability)
4.  [Réplicas de Lectura (Read Replicas)](#réplicas-de-lectura-read-replicas)
5.  [Seguridad y Conectividad](#seguridad-y-conectividad)
6.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

**Cloud SQL** es el servicio de bases de datos relacionales totalmente gestionado de Google Cloud. Automatiza todas las tareas tediosas de administración de bases de datos, como el aprovisionamiento, la aplicación de parches, las copias de seguridad y la configuración de la replicación, permitiéndote centrarte en tu aplicación.

Cloud SQL es compatible con los motores de bases de datos más populares: **MySQL, PostgreSQL y SQL Server**.

### Características Clave

*   **Totalmente Gestionado:** Google se encarga del sistema operativo, la instalación de la base de datos, los parches de seguridad y las actualizaciones.
*   **Copias de Seguridad Automatizadas:** Realiza copias de seguridad diarias automáticas y también permite copias de seguridad bajo demanda. Permite la **recuperación a un punto en el tiempo (Point-in-Time Recovery - PITR)** gracias a los registros binarios.
*   **Escalabilidad Sencilla:** Puedes escalar verticalmente tu instancia (aumentar vCPU y RAM) con un solo clic y un breve tiempo de inactividad.
*   **Seguridad Integrada:** Los datos se cifran en reposo y en tránsito. El acceso se controla a través de redes autorizadas y el Cloud SQL Auth Proxy.

### Alta Disponibilidad (High Availability)

La configuración de alta disponibilidad (HA) de Cloud SQL proporciona tolerancia a fallos a nivel de zona.

*   **¿Cómo funciona?**
    1.  Creas una instancia principal (master) en una zona.
    2.  Cloud SQL aprovisiona automáticamente una instancia **en espera (standby)** idéntica en una zona diferente dentro de la misma región.
    3.  Los datos se replican de forma **síncrona** en el disco persistente de ambas instancias.
    4.  Si la instancia principal deja de responder, Cloud SQL realiza una **conmutación por error (failover)** automática a la instancia en espera. La aplicación se redirige a la instancia en espera, que se convierte en la nueva principal.
*   **SLA:** Ofrece un SLA del 99.95%.
*   **Costo:** Pagas por los recursos de ambas instancias, la principal y la de espera.

### Réplicas de Lectura (Read Replicas)

Las réplicas de lectura se utilizan para escalar las cargas de trabajo de lectura, liberando a la instancia principal para que se encargue de las escrituras.

*   **¿Cómo funciona?**
    1.  Creas una o más réplicas de lectura a partir de una instancia principal.
    2.  Los datos se copian de forma **asíncrona** desde la principal a las réplicas.
    3.  Puedes dirigir todo tu tráfico de lectura (consultas `SELECT`) a las réplicas, distribuyendo la carga.
*   **Diferencia con HA:** Una réplica de lectura no proporciona conmutación por error automática. Es para escalar, no para alta disponibilidad. La replicación asíncrona significa que puede haber un pequeño retraso (lag) entre la principal y la réplica.
*   **Caso de Uso:** Aplicaciones con mucho tráfico de lectura, como paneles de business intelligence o sitios de contenido.

### Seguridad y Conectividad

*   **IP Privada:** La mejor práctica es configurar las instancias de Cloud SQL para que solo tengan una IP privada dentro de tu VPC. Esto evita cualquier exposición a la Internet pública.
*   **Redes Autorizadas:** Puedes configurar una lista de rangos de IP (CIDR) que tienen permiso para conectarse a tu instancia de Cloud SQL (si usas IP pública).
*   **Cloud SQL Auth Proxy:** Es la herramienta recomendada para conectarse a Cloud SQL, especialmente desde fuera de GCP. Es un pequeño cliente que se ejecuta en tu máquina local o en una VM. Crea un túnel seguro y cifrado hacia tu instancia de Cloud SQL, gestionando la autenticación y autorización a través de credenciales de IAM, sin necesidad de gestionar certificados SSL o IPs estáticas.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear una instancia de Cloud SQL para PostgreSQL con IP privada.

```bash
# 1. Crear la instancia de Cloud SQL
gcloud sql instances create my-postgres-instance \
    --database-version=POSTGRES_13 \
    --region=us-central1 \
    --cpu=1 \
    --memory=4GB \
    --no-assign-ip --network=default

# 2. Test (Verificación): Describe la instancia para confirmar la IP privada
gcloud sql instances describe my-postgres-instance
# Esperado: En la salida, bajo 'ipAddresses', deberías ver una entrada de tipo 'PRIVATE'
# y ninguna de tipo 'PRIMARY' (pública).

# 3. Crear un usuario
gcloud sql users create myuser --instance=my-postgres-instance --password="super-secret"

# 4. Conectarse usando el Cloud SQL Auth Proxy (ejemplo conceptual)
# Primero, descarga e instala el proxy.
# ./cloud_sql_proxy -instances=<PROJECT_ID>:<REGION>:<INSTANCE_NAME>=tcp:5432
# Luego, conéctate con psql:
# psql -h 127.0.0.1 -U myuser -d postgres
```

### 💡 Tips de Examen

*   **Cloud SQL vs. Spanner:** Si la pregunta habla de una base de datos relacional para una aplicación **regional** (como un CRM o un blog de WordPress), la respuesta es **Cloud SQL**. Si menciona **escalabilidad horizontal global** y **consistencia estricta**, es **Spanner**.
*   **HA vs. Réplicas de Lectura:** Si el objetivo es la **tolerancia a fallos** y la **recuperación automática**, la solución es la **Alta Disponibilidad (HA)**. Si el objetivo es **escalar el rendimiento de las lecturas**, la solución son las **Réplicas de Lectura**.
*   **Conectividad Segura:** La forma recomendada y más segura de conectarse a Cloud SQL es usando **IP Privada** y el **Cloud SQL Auth Proxy**.

### ✍️ Resumen

Cloud SQL es la solución ideal para cargas de trabajo relacionales en GCP que no requieren la escala masiva de Spanner. Al ser un servicio totalmente gestionado, elimina la carga operativa de la administración de bases de datos. Sus funcionalidades integradas de alta disponibilidad, réplicas de lectura, copias de seguridad automáticas y conectividad segura a través del Auth Proxy lo convierten en una opción robusta y fácil de usar para la mayoría de las aplicaciones tradicionales.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-004-cloud-sql)
