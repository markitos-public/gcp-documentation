
# 📜 003: Cloud CDN

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Cómo Funciona Cloud CDN](#cómo-funciona-cloud-cdn)
3.  [Conceptos Clave](#conceptos-clave)
4.  [Contenido Privado con URLs Firmadas](#contenido-privado-con-urls-firmadas)
5.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
6.  [🧠 Lecciones Aprendidas](#lecciones-aprendidas)
7.  [🤔 Errores y Confusiones Comunes](#errores-y-confusiones-comunes)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

**Cloud CDN (Content Delivery Network)** es el servicio de red de distribución de contenido de Google. Utiliza la red global de puntos de presencia (PoPs) de Google para almacenar en caché el contenido de tu aplicación (imágenes, videos, CSS, JavaScript) cerca de tus usuarios. Al servir el contenido desde la ubicación más cercana, Cloud CDN reduce drásticamente la latencia, mejora el rendimiento de la carga de la página y disminuye la carga en tus servidores de origen.

Es importante destacar que Cloud CDN **no es un producto independiente**. Funciona como una funcionalidad que se habilita en un **Balanceador de Carga de Aplicaciones Externo Global**.

### Cómo Funciona Cloud CDN

1.  Un usuario solicita contenido (ej. una imagen) a tu sitio web.
2.  La petición llega al Balanceador de Carga de Aplicaciones Externo Global.
3.  El balanceador busca la imagen en la caché de Cloud CDN más cercana al usuario.
4.  **Cache Hit (Acierto de Caché):** Si la imagen está en la caché y no ha expirado, Cloud CDN la sirve directamente al usuario. Esto es extremadamente rápido y no genera carga en tu backend.
5.  **Cache Miss (Fallo de Caché):** Si la imagen no está en la caché o ha expirado, la petición se reenvía a tu servidor de origen (ej. un MIG o un bucket de Cloud Storage). El origen sirve la imagen, y Cloud CDN la almacena en caché para futuras peticiones antes de entregarla al usuario.

### Conceptos Clave

*   **Origen (Origin):** Es tu servicio de backend que contiene el contenido original. Puede ser un grupo de instancias (MIG), un bucket de Cloud Storage, etc.

*   **Modos de Caché (Cache Modes):** Definen qué contenido se almacena en caché.
    1.  **`CACHE_ALL_STATIC` (Predeterminado):** Almacena automáticamente en caché contenido estático común (CSS, JS, imágenes, etc.) basándose en las cabeceras de respuesta del origen.
    2.  **`USE_BACKEND_SETTING`:** Respeta estrictamente las cabeceras de control de caché (`Cache-Control`) que envía tu backend. Te da control total sobre qué se cachea y por cuánto tiempo.
    3.  **`FORCE_CACHE_ALL`:** Ignora cualquier cabecera `Cache-Control: private` o `no-store` y cachea todo el contenido. Útil si el backend no está configurado correctamente, pero puede ser peligroso si cacheas contenido privado.

*   **TTL (Time-to-Live):** Especifica por cuánto tiempo se debe mantener el contenido en caché. Se puede configurar en Cloud CDN o mediante las cabeceras `Cache-Control` del origen.

*   **Invalidación de Caché (Cache Invalidation):**
    *   **¿Qué es?** Es el proceso de forzar la eliminación de un objeto de todas las cachés de Cloud CDN antes de que expire naturalmente.
    *   **Caso de Uso:** Cuando actualizas un archivo (ej. `logo.png`) y necesitas que todos los usuarios vean la nueva versión inmediatamente, no la versión antigua que está en caché.
    *   **Proceso:** Solicitas una invalidación para una ruta de URL específica (ej. `/images/logo.png`).

### Contenido Privado con URLs Firmadas

*   **¿Qué es?** Por defecto, Cloud CDN solo cachea contenido público. Las **URLs firmadas (Signed URLs)** te permiten dar acceso temporal y limitado a un recurso privado a través de la CDN.
*   **¿Cómo funciona?**
    1.  Generas una URL especial que contiene una firma criptográfica. Esta firma incluye la ruta del recurso, una fecha de expiración y una clave secreta que solo tú conoces.
    2.  Le das esta URL a un usuario autorizado.
    3.  El usuario puede usar la URL para acceder al contenido a través de Cloud CDN hasta que la firma expire. Cloud CDN verifica la firma antes de servir el contenido (ya sea desde la caché o desde el origen).
*   **Caso de Uso:** Servir contenido premium a usuarios de pago, descargas de software personalizadas, etc.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Habilitar Cloud CDN en un servicio de backend existente.

```bash
# Prerrequisito: Tener un balanceador de carga con un servicio de backend
# llamado 'my-web-backend-service' (como en el lab anterior).

# 1. Habilitar CDN en el servicio de backend
gcloud compute backend-services update my-web-backend-service \
    --enable-cdn \
    --global

# 2. Test (Verificación): Describe el servicio de backend
gcloud compute backend-services describe my-web-backend-service --global
# Esperado: En la salida, deberías ver la línea 'enableCdn: true'.

# 3. Solicitar una invalidación de caché (ejemplo)
gcloud compute url-maps invalidate-cdn-cache my-lb-url-map \
    --path "/images/*" \
    --host "your-domain.com"
# Esto invalidaría todas las imágenes bajo la ruta /images.
```

### 🧠 Lecciones Aprendidas

*   **CDN no es un producto aislado:** Siempre va de la mano con el Balanceador de Carga de Aplicaciones Externo Global.
*   **Controla tu caché:** Entender las cabeceras `Cache-Control` (`public`, `private`, `no-store`, `max-age`) es fundamental para gestionar eficazmente la CDN.
*   **La invalidación no es instantánea:** Puede tardar varios minutos en propagarse por toda la red global de Google.

### 🤔 Errores y Confusiones Comunes

*   **Contenido dinámico cacheado:** El error más peligroso. Si cacheas por error una página HTML que contiene información personal del usuario, podrías servir esa información a otros usuarios. Usa `Cache-Control: private` para el contenido dinámico.
*   **Olvidar el TTL:** Si no configuras un TTL, Cloud CDN usará valores predeterminados que pueden no ser óptimos, llevando a contenido obsoleto (si el TTL es muy largo) o a pocos aciertos de caché (si es muy corto).
*   **Probar la caché:** Es difícil probar el rendimiento de la caché. Puedes mirar las cabeceras de respuesta (ej. `Age`) o los logs de Cloud CDN en Cloud Logging para ver si una petición fue un `HIT`, `MISS` o `REVALIDATED`.

### 💡 Tips de Examen

*   Si una pregunta trata sobre **acelerar la entrega de contenido estático (imágenes, videos, JS, CSS) a nivel mundial**, la respuesta es **Cloud CDN**.
*   Recuerda que Cloud CDN solo funciona con el **Balanceador de Carga de Aplicaciones Externo Global**.
*   Si se necesita servir **contenido privado** a través de una CDN, la solución es usar **URLs Firmadas**.

### ✍️ Resumen

Cloud CDN es una herramienta esencial para mejorar el rendimiento y la experiencia del usuario en aplicaciones web con una audiencia global. Al integrarse directamente con el balanceador de carga de aplicaciones de Google, proporciona una forma sencilla de distribuir y cachear contenido en el borde de la red de Google, reduciendo la latencia y la carga del servidor. La gestión cuidadosa de los modos de caché, los TTL y el uso de URLs firmadas para contenido privado son clave para su implementación exitosa.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-003-cloud-cdn)
