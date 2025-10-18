# ☁️ Roles de IAM: Definiendo Quién Puede Hacer Qué

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

Un **Rol** en Cloud IAM es una colección de permisos. Los permisos determinan qué operaciones están permitidas sobre un recurso. Cuando se asigna un rol a una identidad (principal), se le conceden todos los permisos que contiene ese rol. Los roles son el corazón del sistema de autorización de GCP, ya que son la forma de aplicar el principio de mínimo privilegio, concediendo solo los permisos necesarios para realizar una tarea y nada más.

---

## 📘 Detalles

Google Cloud organiza los roles en tres categorías principales.

### 1. Roles Básicos (Primitivos)

Son los roles originales de GCP, muy amplios y potentes. Se aplican a nivel de proyecto y afectan a todos los recursos dentro de él.
*   **Propietario (Owner):** El más poderoso. Puede hacer todo, incluyendo gestionar la facturación y eliminar el proyecto.
*   **Editor (Editor):** Puede crear, modificar y eliminar la mayoría de los recursos de GCP. No puede gestionar roles, facturación ni eliminar el proyecto.
*   **Visualizador (Viewer):** Permisos de solo lectura para la mayoría de los recursos.
*   **Navegador (Browser):** Un rol más limitado que el de Visualizador, permite navegar por la jerarquía de recursos del proyecto sin ver el contenido de los datos.

**Mejor práctica:** Evitar el uso de roles básicos en producción. Son demasiado permisivos y no se alinean con el principio de mínimo privilegio.

### 2. Roles Predefinidos

Son roles gestionados por Google que proporcionan permisos granulares para un servicio o un conjunto de servicios relacionados. Hay cientos de roles predefinidos.
*   **Sintaxis:** Siguen el formato `roles/<nombre_del_servicio>.<recurso>`. Por ejemplo:
    *   `roles/compute.instanceAdmin`: Permisos para administrar instancias de VM.
    *   `roles/storage.objectViewer`: Permisos para ver objetos en buckets de Cloud Storage.
    *   `roles/secretmanager.secretAccessor`: Permisos para leer el valor de un secreto.

**Mejor práctica:** Utilizar siempre roles predefinidos en lugar de roles básicos. Son la forma estándar de conceder permisos granulares.

### 3. Roles Personalizados (Custom Roles)

Cuando los roles predefinidos no se ajustan exactamente a tus necesidades, puedes crear tus propios roles personalizados. Un rol personalizado es una colección de permisos que tú defines. Esto te da el máximo control para aplicar el principio de mínimo privilegio.
*   **Caso de uso:** Imagina que necesitas una cuenta de servicio que pueda iniciar y detener VMs, pero no eliminarlas. El rol `compute.instanceAdmin` es demasiado permisivo. Podrías crear un rol personalizado que solo contenga los permisos `compute.instances.start` y `compute.instances.stop`.
*   **Alcance:** Los roles personalizados se pueden crear a nivel de proyecto o de organización.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Crearemos un rol personalizado para un auditor de seguridad que solo necesita listar las instancias de Compute Engine y los buckets de Cloud Storage, pero no ver su contenido. Luego, asignaremos ese rol a una cuenta de servicio.

### ARRANGE (Preparación)

```bash
# 1. Variables
export PROJECT_ID=$(gcloud config get-value project)
export CUSTOM_ROLE_ID="instance_storage_lister"
export SA_NAME="auditor-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 2. Crear la cuenta de servicio a la que asignaremos el rol
gcloud iam service-accounts create $SA_NAME --display-name="Auditor Service Account"
```

### ACT (Implementación)

```bash
# 1. Crear un rol personalizado a partir de un archivo de definición YAML
cat > role-definition.yaml << EOM
title: "Instance and Storage Lister"
description: "Custom role to list GCE instances and GCS buckets"
stage: "GA"
includedPermissions:
- compute.instances.list
- storage.buckets.list
EOM

# gcloud iam roles create: Crea un nuevo rol personalizado.
# $CUSTOM_ROLE_ID: El ID único para el nuevo rol.
# --project: El proyecto donde se creará el rol.
# --file: El archivo YAML o JSON que define los permisos del rol.
gcloud iam roles create $CUSTOM_ROLE_ID --project=$PROJECT_ID \
    --file=role-definition.yaml

# 2. Asignar el nuevo rol personalizado a la cuenta de servicio a nivel de proyecto.
# gcloud projects add-iam-policy-binding: Añade una asignación de rol a la política de IAM de un proyecto.
# $PROJECT_ID: El recurso (proyecto) al que se le añade el binding.
# --member: El principal (usuario, grupo, SA) que recibe el permiso.
# --role: El rol que se va a conceder.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}"

# 3. Permitir que el usuario actual suplante a la cuenta de servicio (necesario para el ASSERT)
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --member="user:$(gcloud config get-value account)" \
    --role="roles/iam.serviceAccountTokenCreator"

echo "⏳ Dando 30 segundos para que las políticas de IAM se propaguen..."
sleep 30
```

### ASSERT (Verificación)

```bash
# 1. Verificar que el rol personalizado fue creado (usando el ID corto y el proyecto)
gcloud iam roles describe $CUSTOM_ROLE_ID --project=$PROJECT_ID

# 2. Verificar que la cuenta de servicio tiene la asignación de rol (binding)
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format='table(bindings.role, bindings.members)' \
    --filter="bindings.members:${SA_EMAIL} AND bindings.role:projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}"

# 3. Simular una acción permitida y una denegada (usando la SA)
# La SA puede listar instancias:
gcloud compute instances list --impersonate-service-account=$SA_EMAIL

# La SA NO puede crear una instancia (el comando fallará con error de permisos):
gcloud compute instances create test-vm --impersonate-service-account=$SA_EMAIL --machine-type=e2-micro --zone=europe-west1-b || echo "Fallo esperado: Permiso denegado."
```

### CLEANUP (Limpieza)

```bash
# Eliminar la asignación de rol, el rol personalizado y la cuenta de servicio
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}"
gcloud iam roles delete $CUSTOM_ROLE_ID --project=$PROJECT_ID --quiet
gcloud iam service-accounts delete $SA_EMAIL --quiet
rm role-definition.yaml
```

---

## 💡 Lecciones Aprendidas

*   **El Mínimo Privilegio es la Norma:** Empieza siempre con los permisos más restrictivos posibles y añade más solo si es estrictamente necesario. El orden de preferencia es: **Rol Predefinido > Rol Personalizado > Rol Básico**.
*   **Los Roles son Colecciones de Permisos:** Un rol no hace nada por sí solo. Su poder reside en los permisos que contiene. Para entender qué puede hacer un rol, debes inspeccionar sus permisos.
*   **Los Roles Personalizados son para Casos Específicos:** No crees roles personalizados para todo. Son para cerrar las brechas que los cientos de roles predefinidos de Google no cubren.

---

## ⚠️ Errores y Confusiones Comunes

*   **Usar Roles Básicos por Comodidad:** Es muy tentador asignar el rol de `Editor` a una cuenta de servicio para "hacer que funcione". Esto es una práctica de seguridad muy pobre y debe evitarse a toda costa.
*   **Confundir Permisos con Roles:** Un permiso es una acción individual (ej. `compute.instances.create`). Un rol es una colección de esos permisos. No se asignan permisos directamente a los usuarios, se asignan roles.
*   **Modificar Roles Predefinidos:** Los roles predefinidos son gestionados por Google y no se pueden modificar. Si necesitas una variación, debes crear un rol personalizado.

---

## 🎯 Tips de Examen

*   **Jerarquía de Roles:** Conoce la diferencia entre roles **Básicos** (Owner, Editor, Viewer), **Predefinidos** (granulares, gestionados por Google) y **Personalizados** (creados por el usuario).
*   **Principio de Mínimo Privilegio:** Muchas preguntas de examen sobre IAM se basan en elegir el rol "más apropiado" para un escenario. La respuesta correcta es casi siempre el rol predefinido más restrictivo que cumpla con los requisitos.
*   **Cuándo Usar Roles Personalizados:** Si un escenario describe una necesidad de permisos muy específica que no encaja con ningún rol predefinido, la solución es crear un rol personalizado.

---

## 🧾 Resumen

Los roles de IAM son el mecanismo fundamental para conceder permisos en Google Cloud. Al entender la diferencia entre los roles básicos, predefinidos y personalizados, y al aplicar rigurosamente el principio de mínimo privilegio, las organizaciones pueden construir un entorno en la nube seguro y bien gobernado, asegurando que cada identidad (usuario o máquina) tenga solo los permisos que necesita para realizar su función.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-roles-de-iam-definiendo-quién-puede-hacer-qué)
