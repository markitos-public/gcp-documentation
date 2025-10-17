# ⚖️ Roles y Permisos Personalizados en IAM

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#️-roles-y-permisos-personalizados-en-iam)

---

## 🧭 Descripción

Aunque Google Cloud ofrece cientos de roles predefinidos, a veces necesitas un conjunto de permisos que no se ajusta exactamente a ninguno de ellos. Para estos casos, IAM te permite crear **Roles Personalizados**. Este capítulo de profundización explora cuándo, por qué y cómo crear roles a medida para aplicar el Principio de Privilegio Mínimo con la máxima precisión.

---

## 📘 Detalles

Un rol personalizado es simplemente un conjunto de permisos que tú defines. Te permite agrupar permisos específicos de uno o más servicios de GCP en un solo rol que puedes asignar a los principales (usuarios, cuentas de servicio, etc.).

### ¿Cuándo usar Roles Personalizados?

La recomendación de Google es usar siempre roles predefinidos si es posible. Sin embargo, deberías crear un rol personalizado cuando:

*   Un rol predefinido concede **demasiados permisos** de los que el principal necesita.
*   Necesitas conceder un conjunto de permisos que abarcan **múltiples servicios** y no existe un rol predefinido que los combine de la forma que necesitas.

### Ciclo de Vida de un Rol Personalizado

1.  **Creación:** Defines el rol con un ID, un título, una descripción y una lista de permisos. Los roles personalizados solo se pueden crear a nivel de **Proyecto** u **Organización** (no en carpetas).
2.  **Asignación:** Asignas el rol a un principal en un recurso, igual que harías con un rol predefinido.
3.  **Mantenimiento:** Si Google añade nuevos permisos a un servicio, estos **no se añaden automáticamente** a tus roles personalizados. Eres responsable de mantenerlos actualizados.
4.  **Desactivación:** Puedes desactivar un rol para que no se pueda asignar a nuevos principales, pero los principales que ya lo tienen lo conservan.
5.  **Eliminación:** Puedes borrar un rol si ya no se necesita.

### Fases de Lanzamiento de Permisos

Los permisos tienen fases de lanzamiento (`TESTING`, `SUPPORTED`). Al crear un rol, puedes especificar qué fase de permisos quieres incluir. Por defecto, solo se incluyen los permisos `SUPPORTED` (estables).

```bash
# Ejemplo ilustrativo: Listar todos los permisos disponibles para el servicio de Compute Engine.
# Esto te da la materia prima para construir tu rol personalizado.
gcloud iam permissions list --service=compute.googleapis.com
```

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Ciclo de Vida de un Rol para Administrador de VMs (Lectura y Creación)
**Contexto:** Este es un laboratorio completo "paso a paso" para demostrar el poder de los roles personalizados.
1.  Crearemos una Cuenta de Servicio (SA) y un rol personalizado que solo permite **listar** VMs.
2.  Verificaremos que la SA puede listar VMs, pero **falla** al intentar crear una.
3.  Actualizaremos el rol para añadir el permiso de **creación**.
4.  Verificaremos que la SA ahora **sí puede** crear una VM.

#### ARRANGE (Preparación del laboratorio)
```bash
# Variables
export PROJECT_ID=$(gcloud config get-value project)
export CUSTOM_ROLE_ID="vm_operator_mdk"
export SA_NAME="vm-operator-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export VM_TO_LIST="vm-for-listing"
export VM_TO_CREATE="vm-created-by-sa"
export ZONE="europe-west1-b"

# 1. Habilitar APIs necesarias
gcloud services enable iam.googleapis.com compute.googleapis.com --project=$PROJECT_ID

# 2. Crear una VM de prueba para que la SA pueda listarla
echo "--- Creando VM de prueba para listar: $VM_TO_LIST ---"
gcloud compute instances create $VM_TO_LIST --zone=$ZONE --quiet

# 3. Crear la Cuenta de Servicio
echo "--- Creando Cuenta de Servicio: $SA_NAME ---"
gcloud iam service-accounts create $SA_NAME --display-name="VM Operator SA"
```

#### ACT 1 (Implementar Rol de Solo Lectura)
```bash
# 1. Definir el rol de solo lectura en un fichero YAML
cat > vm-role-readonly.yaml << EOM
title: "VM Lister"
description: "Permite listar las VMs de Compute Engine."
stage: "GA"
includedPermissions:
- compute.instances.list
EOM

# 2. Crear el rol personalizado
# gcloud iam roles create: Crea un nuevo rol personalizado.
# $CUSTOM_ROLE_ID: (Requerido) El ID único para el nuevo rol.
# --project: (Requerido) El proyecto donde se creará el rol.
# --file: (Requerido) El archivo YAML que define los permisos del rol.
gcloud iam roles create $CUSTOM_ROLE_ID --project=$PROJECT_ID --file=vm-role-readonly.yaml

# 3. Asignar (bind) el rol a la Cuenta de Servicio a nivel de proyecto
# gcloud projects add-iam-policy-binding: Añade una asignación de rol a la política de IAM de un proyecto.
# $PROJECT_ID: (Requerido) El proyecto al que se le añade el binding.
# --member: (Requerido) El principal (la SA) que recibe el permiso.
# --role: (Requerido) El rol personalizado que se va a conceder.
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}"

echo "⏳ Dando 30 segundos para que la política de IAM se propague..."
sleep 30
```

#### ASSERT 1 (Verificar Permisos de Solo Lectura)
```bash
# 1. Intentar listar VMs (debería funcionar)
echo "--- 1/2: Verificando que la SA PUEDE listar VMs (debe funcionar) ---"
# gcloud compute instances list: Lista las VMs.
# --impersonate-service-account: (Opcional) Ejecuta el comando con la identidad de la SA.
# --project: (Opcional si está configurado) Asegura que se lista en el proyecto correcto.
gcloud compute instances list --impersonate-service-account=$SA_EMAIL --project=$PROJECT_ID

# 2. Intentar crear una VM (debería fallar)
echo "--- 2/2: Verificando que la SA NO PUEDE crear VMs (debe fallar) ---"
# gcloud compute instances create: Intenta crear una VM. El rol actual no tiene este permiso.
gcloud compute instances create $VM_TO_CREATE --zone=$ZONE --impersonate-service-account=$SA_EMAIL --project=$PROJECT_ID || echo "✅ Fallo esperado: Permiso denegado. ¡El rol de solo lectura funciona!"
```

#### ACT 2 (Actualizar Rol para Permitir Creación)
```bash
# 1. Definir el rol actualizado con el permiso de creación
cat > vm-role-creator.yaml << EOM
title: "VM Operator"
description: "Permite listar y crear VMs de Compute Engine."
stage: "GA"
includedPermissions:
- compute.instances.list
- compute.instances.create   # <-- Permiso añadido
- compute.instances.setMetadata # Necesario para crear
- compute.disks.create # Necesario para crear
- compute.subnetworks.use # Necesario para crear
- compute.subnetworks.useExternalIp # Necesario para crear
- iam.serviceAccounts.actAs # Necesario para asignar una SA a la VM
EOM

# 2. Actualizar el rol existente
gcloud iam roles update $CUSTOM_ROLE_ID --project=$PROJECT_ID --file=vm-role-creator.yaml

echo "⏳ Dando 30 segundos para que los permisos se propaguen..."
sleep 30
```

#### ASSERT 2 (Verificar Permisos de Creación)
```bash
# 1. Intentar crear la VM de nuevo (ahora debería funcionar)
echo "--- Verificando que la SA AHORA SÍ PUEDE crear VMs (debe funcionar) ---"
gcloud compute instances create $VM_TO_CREATE --zone=$ZONE --impersonate-service-account=$SA_EMAIL --project=$PROJECT_ID

# 2. Verificar que la nueva VM existe
gcloud compute instances describe $VM_TO_CREATE --zone=$ZONE --project=$PROJECT_ID
echo "✅ Éxito: ¡La SA ha creado la VM $VM_TO_CREATE!"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar la asignación de rol, el rol personalizado, las VMs y la SA
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="projects/${PROJECT_ID}/roles/${CUSTOM_ROLE_ID}" --quiet
gcloud iam roles delete $CUSTOM_ROLE_ID --project=$PROJECT_ID --quiet
gcloud compute instances delete $VM_TO_LIST --zone=$ZONE --quiet
gcloud compute instances delete $VM_TO_CREATE --zone=$ZONE --quiet
gcloud iam service-accounts delete $SA_EMAIL --quiet
rm vm-role-readonly.yaml vm-role-creator.yaml
echo "✅ Laboratorio 1 completado y recursos eliminados."
```

### 📋 Escenario 2: Ciclo de Vida de un Rol para Acceso a Bucket (Lectura y Escritura)
**Contexto:** Crearemos un rol que primero solo permite leer objetos de un bucket. Verificaremos que no puede escribir. Luego, actualizaremos el rol para añadir permisos de escritura y verificaremos que ahora sí puede. Este es un caso de uso muy común para aplicar el mínimo privilegio de forma dinámica.

#### ARRANGE (Preparación del laboratorio)
```bash
# 1. Variables
export PROJECT_ID=$(gcloud config get-value project)
export CUSTOM_ROLE_ID="bucket_object_mdk"
export SA_NAME="bucket-ops-mdk-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export BUCKET_NAME="bucket-custom-${PROJECT_ID}"
export TEST_FILE="local-file.txt"

# 2. Crear cuenta de servicio y bucket
gcloud iam service-accounts create $SA_NAME --display-name="Bucket Operator SA" --quiet
gsutil mb gs://$BUCKET_NAME

# 3. Crear un archivo local para las pruebas
echo "Contenido de prueba" > $TEST_FILE
```

#### ACT (Implementación y Verificación - Parte 1: Solo Lectura)
```bash
# 1. Definir el rol personalizado de solo lectura
cat > role-definition-readonly.yaml << EOM
title: "Bucket Object Viewer"
description: "Permite listar y leer objetos en buckets de GCS."
stage: "GA"
includedPermissions:
- storage.objects.get
- storage.objects.list
EOM

# 2. Crear el rol personalizado
gcloud iam roles create $CUSTOM_ROLE_ID --project=$PROJECT_ID --file=role-definition-readonly.yaml

# 3. Asignar el rol a la cuenta de servicio a nivel del bucket
gsutil iam ch serviceAccount:$SA_EMAIL:projects/$PROJECT_ID/roles/$CUSTOM_ROLE_ID gs://$BUCKET_NAME

# 4. ASSERT: Verificar que puede leer pero no escribir
echo "--- Verificando permisos de SOLO LECTURA ---"
# 4.1. Intentar listar objetos (debería funcionar)
echo "1/2: Intentando listar objetos (debería funcionar)..."
gsutil ls gs://$BUCKET_NAME/ --impersonate-service-account=$SA_EMAIL
# 4.2. Intentar subir un archivo (debería fallar)
echo "2/2: Intentando subir un archivo (debería fallar)..."
gsutil cp $TEST_FILE gs://$BUCKET_NAME/ --impersonate-service-account=$SA_EMAIL || echo "✅ Fallo esperado: La cuenta de servicio NO puede escribir. ¡El rol funciona!"
```

#### ACT (Implementación y Verificación - Parte 2: Lectura y Escritura)
```bash
# 1. Definir una nueva versión del rol que incluye permisos de escritura
cat > role-definition-readwrite.yaml << EOM
title: "Bucket Object Operator"
description: "Permite listar, leer y crear objetos en buckets de GCS."
stage: "GA"
includedPermissions:
- storage.objects.get
- storage.objects.list
- storage.objects.create   # <-- Permiso añadido
EOM

# 2. Actualizar el rol personalizado existente
gcloud iam roles update $CUSTOM_ROLE_ID --project=$PROJECT_ID --file=role-definition-readwrite.yaml

echo "⏳ Dando 30 segundos para que los permisos se propaguen..."
sleep 30

# 3. ASSERT: Intentar subir el archivo de nuevo (ahora debería funcionar)
echo "--- Verificando permisos de LECTURA/ESCRITURA ---"
echo "1/2: Intentando subir el archivo de nuevo (ahora debería funcionar)..."
gsutil cp $TEST_FILE gs://$BUCKET_NAME/ --impersonate-service-account=$SA_EMAIL

# 4. Verificar que el archivo existe en el bucket
echo "2/2: Verificando que el archivo se ha subido correctamente..."
gsutil ls gs://$BUCKET_NAME/$TEST_FILE --impersonate-service-account=$SA_EMAIL
echo "✅ Éxito: ¡La cuenta de servicio ahora puede escribir en el bucket!"
```

#### CLEANUP (Limpieza de recursos)
```bash
# Eliminar todos los recursos creados
gsutil rm -r gs://$BUCKET_NAME
gcloud iam roles delete $CUSTOM_ROLE_ID --project=$PROJECT_ID --quiet
gcloud iam service-accounts delete $SA_EMAIL --quiet
rm $TEST_FILE role-definition-readonly.yaml role-definition-readwrite.yaml

echo "✅ Laboratorio completado y recursos eliminados."
```

---

## 💡 Lecciones Aprendidas

*   **Precisión Quirúrgica:** Los roles personalizados son tu herramienta para aplicar el privilegio mínimo con la máxima precisión posible.
*   **Responsabilidad de Mantenimiento:** A diferencia de los roles predefinidos, tú eres responsable de mantener actualizados los permisos de tus roles personalizados.
*   **Crear a Nivel de Organización:** Si un rol va a ser útil para múltiples proyectos, créalo a nivel de Organización para que esté disponible en toda la jerarquía.

---

## ⚠️ Errores y Confusiones Comunes

*   **Crear un rol personalizado cuando ya existe uno predefinido:** Siempre busca en la lista de roles predefinidos antes de crear uno nuevo. Es menos trabajo de mantener.
*   **Clonar y modificar un rol básico:** No puedes clonar los roles básicos (Propietario, Editor, Visualizador). Debes construir tu rol personalizado desde cero o clonando un rol predefinido.
*   **Asignar demasiados permisos:** El propósito de un rol personalizado es la restricción. Si acabas añadiendo cientos de permisos, probablemente estás diseñando mal el rol.

---

## 🎯 Tips de Examen

*   **Cuándo usar roles personalizados:** La respuesta es cuando un rol predefinido es demasiado permisivo y necesitas aplicar el principio de privilegio mínimo.
*   **Dónde se crean:** Los roles personalizados se pueden crear a nivel de **Proyecto** y **Organización**.
*   **`gcloud iam roles create`:** Recuerda el comando para crear un rol. Necesita un ID, un proyecto (u organización) y un fichero de definición (YAML o JSON).

---

## 🧾 Resumen

Los roles personalizados son una potente herramienta de IAM que te permite ir más allá de los roles predefinidos por Google. Te dan el poder de definir conjuntos de permisos a medida, permitiéndote implementar el principio de privilegio mínimo de forma estricta y precisa, lo cual es esencial para una postura de seguridad robusta en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#️-roles-y-permisos-personalizados-en-iam)
