
# 📜 005: Cloud Spanner

## 📝 Índice

1.  [Descripción](#descripción)
2.  [¿Qué Problema Resuelve Spanner?](#qué-problema-resuelve-spanner)
3.  [Arquitectura y Conceptos Clave](#arquitectura-y-conceptos-clave)
4.  [Consistencia Externa (Strong Consistency)](#consistencia-externa-strong-consistency)
5.  [Cuándo Usar Spanner (y Cuándo No)](#cuándo-usar-spanner-y-cuándo-no)
6.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

**Cloud Spanner** es una base de datos única en su clase. Es la primera y única base de datos del mundo que es simultáneamente **relacional (SQL), globalmente consistente y escalable horizontalmente**. Fue desarrollada internamente en Google para soportar sus servicios más críticos (como Google Ads) y ahora está disponible como un servicio gestionado en GCP.

Spanner rompe el tradicional "teorema CAP" (Consistency, Availability, Partition tolerance), que postula que una base de datos distribuida solo puede elegir dos de tres. Spanner, gracias a la infraestructura de red global de Google y a los relojes atómicos, logra ofrecer las tres.

### ¿Qué Problema Resuelve Spanner?

Las bases de datos relacionales tradicionales (como MySQL, PostgreSQL) son excelentes en cuanto a consistencia (transacciones ACID), pero son muy difíciles de escalar horizontalmente. Generalmente se escalan verticalmente (máquinas más grandes), lo que tiene un límite.

Las bases de datos NoSQL (como Cassandra, DynamoDB) escalan horizontalmente de manera fantástica, pero a menudo sacrifican la consistencia estricta por una "consistencia eventual", lo que no es aceptable para muchos casos de uso (ej. transacciones financieras).

**Spanner ofrece lo mejor de ambos mundos:** la consistencia y el modelo relacional de una base de datos tradicional, con la escalabilidad horizontal de una base de datos NoSQL.

### Arquitectura y Conceptos Clave

*   **Separación de Cómputo y Almacenamiento:** A diferencia de las bases de datos tradicionales, en Spanner los nodos de cómputo (que procesan las consultas) están separados de la capa de almacenamiento (Colossus, el sistema de archivos distribuido de Google). Esto permite escalar ambos de forma independiente.

*   **Nodos (Nodes):** Son las unidades de cómputo. Añadir más nodos a una instancia de Spanner aumenta su capacidad de procesamiento de lecturas y escrituras. El escalado es tan simple como mover un control deslizante.

*   **Divisiones (Splits):** Spanner divide automáticamente tus tablas en bloques de filas contiguas llamados "splits". A medida que una tabla crece, Spanner reparte estos splits entre múltiples servidores de almacenamiento, distribuyendo así la carga de forma automática. Este es el secreto de su escalabilidad horizontal.

*   **Esquema Relacional:** A pesar de su arquitectura interna, para el desarrollador, Spanner se presenta como una base de datos relacional. Usas SQL para las consultas, defines un esquema con tablas, columnas y claves primarias, y puedes usar transacciones.

### Consistencia Externa (Strong Consistency)

Esta es la característica más importante de Spanner. Garantiza que las transacciones se comportan como si se ejecutaran en un orden secuencial, en todo el mundo. Si realizas una escritura en una instancia multi-regional, cualquier lectura posterior, desde cualquier parte del mundo, verá esa escritura. Esto se logra gracias a una tecnología llamada **TrueTime**, una API que utiliza relojes atómicos y GPS para sincronizar los relojes de todos los servidores de Google con una precisión increíble.

### Cuándo Usar Spanner (y Cuándo No)

**Usar Spanner cuando:**

*   Necesitas **consistencia transaccional estricta** a escala global.
*   Tu aplicación tiene una audiencia mundial y requiere baja latencia de lectura en diferentes continentes (usando una instancia multi-regional).
*   Tu base de datos relacional actual está alcanzando sus límites de escalabilidad vertical.
*   **Casos de Uso Típicos:** Sistemas financieros, cadenas de suministro y logística, juegos multijugador a gran escala, sistemas de reservas.

**NO usar Spanner cuando:**

*   Tu aplicación es una simple aplicación web o un blog que funciona perfectamente con Cloud SQL.
*   Tu presupuesto es muy ajustado. Spanner es más caro que Cloud SQL (el costo mínimo es de ~65$/mes por 1 nodo).
*   Tu carga de trabajo es puramente analítica (para eso, BigQuery es mejor).
*   No necesitas consistencia estricta y una base de datos NoSQL como Firestore o Bigtable sería más simple o barata.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear una instancia de Spanner, una base de datos y una tabla.

```bash
# 1. Crear una instancia de Spanner (la unidad de cómputo)
gcloud spanner instances create my-spanner-instance \
    --config=regional-us-central1 \
    --description="Mi instancia de Spanner" \
    --nodes=1

# 2. Crear una base de datos dentro de la instancia
gcloud spanner databases create my-spanner-db \
    --instance=my-spanner-instance

# 3. Crear una tabla usando DDL (Data Definition Language)
gcloud spanner databases ddl update my-spanner-db \
    --instance=my-spanner-instance \
    --ddl='CREATE TABLE Singers (
        SingerId   INT64 NOT NULL,
        FirstName  STRING(1024),
        LastName   STRING(1024)
    ) PRIMARY KEY (SingerId)'

# 4. Test (Verificación): Describe la base de datos para ver su esquema
gcloud spanner databases ddl describe my-spanner-db --instance=my-spanner-instance
# Esperado: Debería mostrar la sentencia 'CREATE TABLE Singers ...' que acabamos de aplicar.
```

### 💡 Tips de Examen

*   La frase clave para identificar a Spanner en una pregunta de examen es **"base de datos relacional, globalmente consistente y escalable horizontalmente"**. Son las tres cosas a la vez.
*   Si se menciona la necesidad de **consistencia estricta** para una aplicación **global** (ej. un banco), la respuesta es **Spanner**.
*   **Spanner vs. Cloud SQL:** Cloud SQL es para escala regional. Spanner es para escala regional Y global.
*   **Spanner vs. Bigtable/Firestore:** Spanner es relacional y fuertemente consistente. Bigtable y Firestore son NoSQL y ofrecen modelos de consistencia más relajados (aunque Firestore es fuertemente consistente dentro de un documento).

### ✍️ Resumen

Cloud Spanner es una proeza de la ingeniería de bases de datos que resuelve el dilema histórico entre la consistencia relacional y la escalabilidad NoSQL. Ofrece una solución única para empresas que necesitan construir aplicaciones globales, transaccionales y de alta fiabilidad sin tener que gestionar la complejidad de la fragmentación (sharding) manual. Aunque no es para todos los casos de uso debido a su costo y especificidad, para las cargas de trabajo correctas, es una tecnología transformadora.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-005-cloud-spanner)
