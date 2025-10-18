
# 📜 007: Desarrollo en la Nube

## 📝 Índice

1.  [Descripción](#descripción)
2.  [El Ciclo de Desarrollo Nativo de la Nube](#el-ciclo-de-desarrollo-nativo-de-la-nube)
3.  [Herramientas Clave para Desarrolladores en GCP](#herramientas-clave-para-desarrolladores-en-gcp)
    *   [Cloud Shell](#cloud-shell)
    *   [Cloud Code](#cloud-code)
    *   [Cloud Source Repositories](#cloud-source-repositories)
    *   [Artifact Registry](#artifact-registry)
4.  [✍️ Resumen](#resumen)
5.  [🔖 Firma](#firma)

---

### Descripción

El **desarrollo en la nube** va más allá de simplemente escribir código. Implica un conjunto de herramientas y prácticas que integran el ciclo de vida del desarrollo de software directamente con los servicios en la nube. El objetivo es acelerar el ciclo de "código -> despliegue -> depuración" en un entorno nativo de la nube.

Google Cloud proporciona un conjunto de herramientas para desarrolladores diseñadas para agilizar este proceso, ya sea que estés trabajando con máquinas virtuales, contenedores o aplicaciones sin servidor.

### El Ciclo de Desarrollo Nativo de la Nube

Un ciclo de desarrollo moderno en la nube generalmente sigue estos pasos:

1.  **Codificar:** Escribir el código de la aplicación en un entorno de desarrollo local (IDE).
2.  **Construir:** Empaquetar el código en una unidad desplegable (ej. una imagen de contenedor de Docker).
3.  **Desplegar:** Enviar la unidad a un servicio de GCP (ej. GKE, Cloud Run).
4.  **Depurar:** Probar y depurar la aplicación mientras se ejecuta en la nube.
5.  **Iterar:** Volver al paso 1 con los cambios y mejoras.

Las herramientas de GCP están diseñadas para hacer que este bucle sea lo más rápido y fluido posible.

### Herramientas Clave para Desarrolladores en GCP

#### Cloud Shell

*   **¿Qué es?** Es una máquina virtual de Debian, pequeña y gratuita, a la que se accede a través del navegador. Viene preinstalada con las herramientas más importantes, incluyendo la **CLI de `gcloud`**, `gsutil`, `kubectl`, `docker`, `terraform` y más.
*   **Características:**
    *   **Editor de Código Integrado:** Incluye un editor basado en Theia (similar a VS Code) para realizar cambios rápidos.
    *   **Directorio `home` Persistente:** Tienes 5 GB de almacenamiento persistente en tu directorio `$HOME`.
    *   **Autenticación Automática:** Ya está autenticado con tus credenciales de GCP, por lo que no necesitas configurar `gcloud`.
*   **Caso de Uso:** Es la forma más rápida de ejecutar comandos de `gcloud` o realizar tareas administrativas sin tener que instalar nada en tu máquina local. Ideal para experimentar, depurar o gestionar recursos sobre la marcha.

#### Cloud Code

*   **¿Qué es?** Es una extensión para IDEs populares como **VS Code** e **IntelliJ/JetBrains**. Trae las herramientas de desarrollo de la nube directamente a tu entorno de desarrollo local.
*   **Características:**
    *   **Desarrollo y Depuración de Kubernetes:** Permite ejecutar y depurar aplicaciones de GKE/Kubernetes directamente desde tu IDE. Gestiona la sincronización de archivos, el reenvío de puertos y el despliegue por ti.
    *   **Soporte para Cloud Run:** Facilita el despliegue y la visualización de registros de tus servicios de Cloud Run.
    *   **Explorador de APIs de GCP:** Permite navegar y habilitar las APIs de Google Cloud sin salir del IDE.
*   **Caso de Uso:** Para desarrolladores que trabajan con GKE o Cloud Run. Acelera drásticamente el ciclo de desarrollo iterativo al eliminar la necesidad de ejecutar manualmente comandos de `kubectl` o `gcloud` para cada cambio.

#### Cloud Source Repositories

*   **¿Qué es?** Son repositorios de Git privados, totalmente gestionados y alojados en Google Cloud.
*   **Características:**
    *   **Integración Profunda:** Se integra de forma nativa con otros servicios de GCP como Cloud Build (para CI/CD) y Cloud Debugger.
    *   **Sincronización:** Puede sincronizarse automáticamente con repositorios alojados en GitHub o Bitbucket.
*   **Caso de Uso:** Como un repositorio de código central para proyectos alojados en GCP, especialmente si se desea una integración estrecha con las herramientas de CI/CD y depuración de Google.

#### Artifact Registry

*   **¿Qué es?** Es el servicio recomendado para almacenar y gestionar artefactos de software. Es la evolución de Container Registry.
*   **Características:**
    *   **Soporte Multi-formato:** Puede almacenar imágenes de contenedor (Docker), paquetes de lenguajes (npm, Maven, Pip) y más, en un solo lugar.
    *   **Seguridad:** Se integra con IAM para un control de acceso granular y con Artifact Analysis para escanear vulnerabilidades en tus imágenes de contenedor.
    *   **Ubicaciones Regionales y Multi-regionales:** Permite almacenar artefactos cerca de tus sistemas de compilación y despliegue.
*   **Caso de Uso:** Es el registro privado estándar para tus imágenes de Docker que se desplegarán en GKE o Cloud Run, y para tus paquetes de software.

### ✍️ Resumen

El ecosistema de desarrollo de Google Cloud está diseñado para cerrar la brecha entre el IDE local y la nube. **Cloud Shell** proporciona un entorno de línea de comandos instantáneo y preconfigurado. **Cloud Code** integra el flujo de trabajo de Kubernetes y Serverless directamente en tu IDE, acelerando el ciclo de desarrollo. **Cloud Source Repositories** ofrece un hogar seguro para tu código fuente, y **Artifact Registry** hace lo mismo para tus artefactos compilados, como las imágenes de contenedor. Juntas, estas herramientas crean una experiencia de desarrollo más fluida y productiva para construir aplicaciones nativas de la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-007-desarrollo-en-la-nube)
