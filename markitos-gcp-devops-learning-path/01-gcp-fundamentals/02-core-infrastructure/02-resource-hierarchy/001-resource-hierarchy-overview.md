# 🏛️ Jerarquía de Recursos

## 📑 Índice

* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [🔬 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)

---

## 🧭 Descripción

La Jerarquía de Recursos de Google Cloud es el sistema que te permite organizar, gestionar y controlar todos tus recursos en la nube de una manera estructurada y lógica. Es análoga al organigrama de una empresa y es la base para la administración del control de acceso (IAM), la facturación y la aplicación de políticas organizativas.

Comprender esta jerarquía es esencial para cualquier administrador o arquitecto de la nube, ya que una estructura bien diseñada facilita la gobernanza, la seguridad y la escalabilidad de las operaciones de una organización en GCP.

---

## 📘 Detalles

La jerarquía consta de cuatro niveles principales, que funcionan de manera descendente.

### 🔹 Nodo Organización (Organization)

Es el nodo raíz de toda la jerarquía de una empresa. Se crea automáticamente cuando un cliente con una cuenta de **Google Workspace** o **Cloud Identity** crea su primer proyecto. Representa a la empresa en su totalidad (ej. `miempresa.com`).

*   **Control Centralizado:** Permite a los administradores tener una visibilidad y un control completos sobre todos los proyectos y recursos de la compañía.
*   **Políticas Globales:** Es el nivel más alto para aplicar políticas de IAM y Políticas de Organización que afectarán a toda la empresa.
*   **Requisito para Carpetas:** Para poder usar Carpetas, es imprescindible tener un nodo de Organización.

### 🔹 Carpetas (Folders)

Las **Carpetas** son un mecanismo de agrupación para proyectos. Permiten organizar los proyectos de una manera que refleje la estructura de la empresa. Se pueden anidar unas dentro de otras para crear jerarquías complejas.

*   **Agrupación Lógica:** Se usan comúnmente para separar departamentos (Ingeniería, Marketing), entornos (Producción, Desarrollo, Test) o equipos.
*   **Herencia de Políticas:** Las políticas (tanto de IAM como de Organización) aplicadas a una carpeta son heredadas por todos los proyectos y sub-carpetas que contenga.

### 🔹 Proyectos (Projects)

El **Proyecto** es la entidad fundamental y obligatoria para organizar los recursos. Todos los recursos de GCP (como VMs, buckets, etc.) deben pertenecer a un único proyecto.

*   **Base para los Servicios:** Un proyecto es el nivel en el que se habilitan las APIs, se gestiona la facturación y se configuran los permisos.
*   **Aislamiento:** Los proyectos proporcionan un límite de aislamiento. Los recursos de un proyecto están separados de los de otro, aunque se pueden conectar a través de la red.
*   **Identificadores:** Cada proyecto tiene un nombre legible (ej. "Mi Proyecto Web"), un ID de proyecto único a nivel global (ej. `mi-proyecto-web-12345`) y un número de proyecto.

### 🔹 Recursos (Resources)

Son los componentes y servicios individuales que utilizas para construir tu aplicación, como una instancia de Compute Engine, un bucket de Cloud Storage o una base de datos de Cloud SQL. Son los elementos finales de la jerarquía y siempre son hijos de un proyecto.

### ✨ Herencia de Políticas (Policy Inheritance)

Este es el concepto más importante de la jerarquía. Las políticas de IAM y las Políticas de Organización **fluyen hacia abajo** desde el nodo padre a los hijos.

*   Una política aplicada a nivel de Organización se aplica a todas las carpetas, proyectos y recursos de la empresa.
*   Si a un usuario se le da el rol de `Editor` en una carpeta, tendrá permisos de editor en todos los proyectos dentro de esa carpeta.
*   Las políticas son la **unión** de las políticas del recurso y las de sus ancestros. Sin embargo, las **Políticas de Organización** (que imponen restricciones) son más estrictas. Una restricción a nivel de carpeta (ej. "prohibir la creación de IPs públicas") no puede ser anulada por un permiso más permisivo en un proyecto hijo.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Este laboratorio es más conceptual, ya que la mayoría de los usuarios no tienen permisos para crear organizaciones o carpetas. Nos centraremos en explorar la jerarquía desde la perspectiva de un proyecto existente.

### ARRANGE (Preparación)

```bash
# Obtener el ID del proyecto actual
export PROJECT_ID=$(gcloud config get-value project)
echo "Trabajando con el proyecto: $PROJECT_ID"
```

### ACT (Implementación)

```bash
# 1. Describir el proyecto actual para ver sus detalles
echo "=== DESCRIPCIÓN DEL PROYECTO ==="
gcloud projects describe $PROJECT_ID

# 2. Obtener los ancestros del proyecto (su ruta en la jerarquía)
echo "
=== ANCESTROS DEL PROYECTO ==="
gcloud projects get-ancestors $PROJECT_ID --format="table(id,type)"

# 3. Listar la política de IAM aplicada directamente al proyecto
echo "
=== POLÍTICA DE IAM DEL PROYECTO ==="
gcloud projects get-iam-policy $PROJECT_ID --format="yaml"
```

### ASSERT (Verificación)

```bash
# La verificación es un análisis de la salida de los comandos.

echo "
=== ANÁLISIS DE LA JERARQUÍA ==="
# 1. En la descripción del proyecto, busca el campo 'parent'.
#    Su valor te dirá si el proyecto está dentro de una carpeta (folders/FOLDER_ID)
#    o directamente bajo la organización (organizations/ORGANIZATION_ID).
PARENT=$(gcloud projects describe $PROJECT_ID --format="value(parent.id)")
PARENT_TYPE=$(gcloud projects describe $PROJECT_ID --format="value(parent.type)")
echo "El padre de este proyecto es un '$PARENT_TYPE' con ID: $PARENT"

# 2. El comando 'get-ancestors' debe mostrar la ruta completa, empezando por el proyecto
#    y subiendo hasta la organización, confirmando la estructura.

# 3. La política de IAM muestra solo los permisos asignados a este nivel.
#    Recuerda que los permisos efectivos son la suma de estos y los heredados.
```

### CLEANUP (Limpieza)

```bash
# No se crearon recursos en este laboratorio, por lo que no se necesita limpieza.
echo "
✅ Laboratorio completado. No se requiere limpieza."
```

---

## 💡 Lecciones Aprendidas

*   **La jerarquía es para la gestión, no para la red:** Que dos proyectos estén en carpetas diferentes no les impide comunicarse por la red si las reglas de firewall y VPC lo permiten.
*   **Usa carpetas para aislar entornos:** La mejor práctica es tener carpetas para `produccion`, `desarrollo` y `pruebas`, aplicando políticas de seguridad más estrictas a la carpeta de producción.
*   **Aplica siempre el principio de mínimo privilegio:** Concede permisos en el nivel más bajo posible de la jerarquía que tenga sentido. No des permisos a nivel de organización si solo se necesitan en un proyecto.

---

## ⚠️ Errores y Confusiones Comunes

*   **Gestionar todo en un único proyecto:** Un anti-patrón muy común que genera caos en la facturación, los permisos y la gestión a medida que una empresa crece.
*   **No entender la herencia de políticas:** Intentar conceder un permiso a nivel de proyecto que ha sido denegado explícitamente por una Política de Organización en un nivel superior. La política más restrictiva suele prevalecer.
*   **Crear proyectos fuera de una Organización:** Cuando los empleados crean proyectos con sus cuentas personales, la empresa pierde todo el control centralizado sobre esos recursos y datos.

---

## 🎯 Tips de Examen

*   Memoriza la jerarquía: **Organización ➡️ Carpetas ➡️ Proyectos ➡️ Recursos**.
*   Entiende que las políticas de **IAM se heredan hacia abajo** y son aditivas.
*   Recuerda que los **Proyectos** son la base para la **facturación** y la **habilitación de APIs**.
*   Un nodo de **Organización** está vinculado a una cuenta de **Google Workspace** o **Cloud Identity** y es un requisito para poder usar **Carpetas**.

---

## 🧾 Resumen

La jerarquía de recursos es el esqueleto organizativo de tu presencia en Google Cloud. Una estructura bien planificada con una Organización, Carpetas y Proyectos te permite aplicar políticas de seguridad y gobernanza de forma centralizada, gestionar los costos eficazmente y escalar tus operaciones en la nube de manera ordenada y segura.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-jerarquía-de-recursos)