
# 📜 006: Firestore

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Modelo de Datos: Documentos y Colecciones](#modelo-de-datos-documentos-y-colecciones)
3.  [Características Clave](#características-clave)
4.  [Modos de Operación: Nativo vs. Datastore](#modos-de-operación-nativo-vs-datastore)
5.  [Seguridad con Reglas de Seguridad](#seguridad-con-reglas-de-seguridad)
6.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

**Firestore** es la base de datos de documentos NoSQL de Google, diseñada para ser flexible, escalable y fácil de usar para el desarrollo de aplicaciones web, móviles y de servidor. Es la sucesora de Cloud Datastore y forma parte de la plataforma Firebase, aunque se puede usar de forma independiente en GCP.

Su principal atractivo es su capacidad para sincronizar datos en tiempo real con los clientes conectados y su potente motor de consultas, que simplifica enormemente el desarrollo de aplicaciones modernas.

### Modelo de Datos: Documentos y Colecciones

Firestore es una base de datos de documentos. Su modelo de datos es fácil de entender:

*   **Documento (Document):** Es la unidad básica de almacenamiento. Es un conjunto de campos de tipo clave-valor. Los valores pueden ser de muchos tipos: cadenas, números, booleanos, arrays, mapas (objetos anidados), etc. Piensa en un documento como un objeto JSON.

*   **Colección (Collection):** Es un contenedor de documentos. Por ejemplo, podrías tener una colección `users` donde cada documento representa un usuario, o una colección `products` donde cada documento es un producto.

*   **Jerarquía:** Las colecciones solo pueden contener documentos. Los documentos pueden contener campos simples y también sub-colecciones. Esto permite crear jerarquías de datos. Por ejemplo: `users/{userId}/cart/{cartItemId}`. Aquí, `users` y `cart` son colecciones, y `{userId}` y `{cartItemId}` son documentos.

### Características Clave

*   **Consultas Flexibles y Potentes:** A diferencia de muchas bases de datos NoSQL que solo permiten consultas por clave primaria, Firestore te permite realizar consultas complejas sobre múltiples campos, combinar filtros y ordenar los resultados. Firestore indexa automáticamente todos los campos de tus documentos.

*   **Actualizaciones en Tiempo Real (Realtime Updates):** Los clientes (web o móvil) pueden "suscribirse" a una consulta o a un documento. Cuando los datos subyacentes cambian, Firestore envía automáticamente la actualización a todos los clientes suscritos. Esta es la característica estrella para crear aplicaciones colaborativas y en tiempo real.

*   **SDKs para Móvil y Web:** Firestore proporciona SDKs nativos para Android, iOS y la Web, que gestionan automáticamente la conectividad de red y la autenticación. Incluyen un robusto **soporte offline**, lo que significa que tu aplicación sigue funcionando incluso sin conexión a Internet; los cambios se sincronizan automáticamente cuando se recupera la conexión.

*   **Escalabilidad Automática:** Como servicio gestionado, Firestore escala automáticamente para manejar la carga de tu aplicación, sin que tengas que preocuparte por el aprovisionamiento de servidores.

### Modos de Operación: Nativo vs. Datastore

Cuando creas una base de datos Firestore en un proyecto, debes elegir un modo, y esta elección es permanente:

1.  **Modo Nativo (Native Mode):**
    *   Es el modo recomendado para nuevas aplicaciones.
    *   Ofrece todas las características nuevas, incluyendo las actualizaciones en tiempo real y los SDKs de cliente de Firebase.

2.  **Modo Datastore (Datastore Mode):**
    *   Proporciona una API compatible con el antiguo servicio **Cloud Datastore**.
    *   **No soporta** las actualizaciones en tiempo real.
    *   Se utiliza principalmente para la retrocompatibilidad de aplicaciones que ya usaban Cloud Datastore.

### Seguridad con Reglas de Seguridad

Para las aplicaciones móviles y web, el acceso a Firestore se controla mediante las **Reglas de Seguridad de Firestore**. Son un lenguaje declarativo que escribes para definir quién puede leer, escribir o eliminar datos, y cómo deben estar estructurados esos datos.

*   **Ejemplo de Regla:**
    ```
    // Permite a un usuario leer y escribir en su propio documento de usuario, pero no en el de otros.
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    ```
*   Se ejecutan en el backend de Google, por lo que son seguras y no pueden ser eludidas por los clientes.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear un documento en una colección de Firestore.

```bash
# (Firestore se gestiona principalmente a través de los SDKs de cliente o servidor.
# gcloud tiene un soporte limitado, pero podemos usarlo para operaciones básicas).

# Prerrequisito: Haber habilitado la API de Firestore y creado una base de datos en la consola.

# 1. Crear un documento en la colección 'users'
# Nota: gcloud firestore no es la herramienta principal, pero sirve para este ejemplo.
# En una aplicación real, usarías un SDK de servidor (Node.js, Python, etc.).

gcloud firestore documents write users/ada 'name=Ada Lovelace, born=1815'

# 2. Leer el documento que acabamos de crear
gcloud firestore documents describe users/ada
# Esperado: Debería mostrar los campos 'name' y 'born' del documento de Ada Lovelace.

# 3. Actualizar el documento
gcloud firestore documents update users/ada 'born=1816'

# 4. Test (Verificación): Vuelve a leer el documento
gcloud firestore documents describe users/ada
# Esperado: El campo 'born' ahora debería ser 1816.
```

### 💡 Tips de Examen

*   **Firestore vs. Bigtable:** Firestore es para datos transaccionales y de aplicaciones (OLTP). Bigtable es para cargas de trabajo analíticas masivas (OLAP). Firestore tiene un modelo de documentos, Bigtable de columna ancha.
*   **Real-time y Offline:** Si una pregunta menciona **sincronización en tiempo real**, **notificaciones push de datos**, o **soporte offline** para aplicaciones móviles/web, la respuesta es casi seguro **Firestore**.
*   **Modelo de Datos:** Recuerda la estructura: **Colección -> Documento -> Colección -> ...**
*   **Modo Nativo vs. Datastore:** Para cualquier aplicación nueva, la elección es el **Modo Nativo**.

### ✍️ Resumen

Firestore es la base de datos NoSQL de propósito general de Google, optimizada para la experiencia del desarrollador y la creación de aplicaciones modernas. Su modelo de datos de documentos, sus potentes consultas, y especialmente sus capacidades de sincronización en tiempo real y soporte offline, la convierten en la opción preferida para aplicaciones web y móviles interactivas y colaborativas. La seguridad granular se logra a través de las Reglas de Seguridad, completando una plataforma de backend robusta y escalable.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-006-firestore)
