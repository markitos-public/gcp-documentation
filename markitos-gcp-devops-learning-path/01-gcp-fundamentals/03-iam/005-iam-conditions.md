# ⚖️ IAM Conditions y Deny Policies

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#️-iam-conditions-y-deny-policies)

---

## 🧭 Descripción

IAM Conditions y Deny Policies son dos mecanismos avanzados de Cloud IAM que te permiten ir más allá de los roles básicos para implementar un control de acceso verdaderamente granular y seguro. Las condiciones permiten que los permisos sean válidos solo si se cumplen ciertos atributos (como la hora del día o el tipo de recurso), mientras que las Deny Policies ofrecen una forma contundente de bloquear permisos, independientemente de qué otros roles de permiso tenga un principal.

---

## 📘 Detalles

### IAM Conditions (Condiciones de IAM)

Una condición es una expresión lógica que se añade a una asignación de rol (una "role binding"). La asignación de rol solo se aplicará si la condición se evalúa como verdadera (`true`).

*   **Basadas en Atributos:** Las condiciones se basan en atributos del recurso (ej. nombre, etiqueta), de la petición (ej. fecha/hora, dirección IP de origen) o del principal.
*   **Lenguaje CEL:** Las condiciones se escriben usando el Common Expression Language (CEL), un lenguaje de expresiones de código abierto.
*   **Caso de Uso Típico:** Conceder a un desarrollador permiso para crear y borrar instancias de Compute Engine, pero *solo* si las instancias tienen una etiqueta específica de su equipo (ej. `resource.labels.team == 'frontend'`). Esto evita que un equipo modifique los recursos de otro.

### Deny Policies (Políticas de Denegación)

Una Deny Policy es una barandilla de seguridad. Te permite establecer prohibiciones que **anulan cualquier permiso `allow` existente**.

*   **Evaluación Prioritaria:** IAM siempre comprueba las Deny Policies *antes* que las políticas `allow`. Si una Deny Policy bloquea un permiso, el acceso se deniega, incluso si el principal tiene el rol de `Owner`.
*   **Herencia:** Al igual que las políticas `allow`, las Deny Policies se heredan hacia abajo en la jerarquía de recursos.
*   **Caso de Uso Típico:** Prohibir a todos los principales (excepto a un grupo de administradores de seguridad) la eliminación de claves de encriptación de Cloud KMS (`cloudkms.cryptoKeyVersions.destroy`) para prevenir la pérdida de datos catastrófica.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario: Acceso Condicional a Prefijo de Objetos
**Contexto:** Este es el caso de uso canónico para condiciones de IAM en Cloud Storage. Daremos a una cuenta de servicio permiso para leer objetos, pero **solo** si esos objetos se encuentran dentro de una "carpeta" (prefijo) específica llamada `public/`.

**Puntos Clave de Aprendizaje:**
1.  **Aislamiento:** Las pruebas de IAM se deben hacer con una cuenta de servicio (`principal`) que no tenga otros permisos que puedan interferir.
2.  **Acceso Uniforme:** Para usar condiciones de IAM en un bucket, este **debe** tener habilitado el "Acceso Uniforme a Nivel de Bucket".
3.  **Ámbito:** La política condicional se aplica directamente **en el bucket**.

**Script Completo Definitivo:**
*Este script es 100% funcional. Solo necesitas reemplazar el valor de `PROJECT_ID`.*

```bash
#!/bin/bash

# --- 1. ARRANGE (Preparación) ---
# ⚠️ ¡IMPORTANTE!: Reemplaza este valor con el tuyo
export PROJECT_ID="markitos-mdk-labs"

export SA_NAME="prefix-cond-tester-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export BUCKET_NAME="iam-prefix-test-bucket-${PROJECT_ID}"

# Crear Cuenta de Servicio
echo "--- Creando cuenta de servicio: $SA_EMAIL ---"
gcloud iam service-accounts create $SA_NAME --display-name="Prefix Condition Tester" --project=$PROJECT_ID

# Crear Bucket CON ACCESO UNIFORME HABILITADO
echo "--- Creando bucket con acceso uniforme... ---"
gcloud storage buckets create gs://$BUCKET_NAME --uniform-bucket-level-access --project=$PROJECT_ID

# Subir ficheros a dos "carpetas"
echo "--- Subiendo ficheros de prueba... ---"
echo "public-data" > public.txt
echo "private-data" > private.txt
gcloud storage cp public.txt gs://$BUCKET_NAME/public/public.txt
gcloud storage cp private.txt gs://$BUCKET_NAME/private/private.txt

# --- 2. ACT (Implementación) ---
echo -e "\n--- Aplicando política condicional en el bucket... ---"
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.objectViewer" \
    --condition='expression=resource.name.startsWith("projects/_/buckets/'$BUCKET_NAME'/objects/public/"),title=access_to_public_folder,description=Grants access to public/ folder'

echo "Política aplicada."

# --- 3. ASSERT (Verificación) ---
echo -e "\n--- Verificando el acceso (puede tardar ~10s en propagarse)... ---"
sleep 10

# Test 1: Acceder a la carpeta PÚBLICA (debería funcionar)
echo "Intentando leer de 'public/public.txt' (debería funcionar)..."
if gcloud storage cat gs://$BUCKET_NAME/public/public.txt --impersonate-service-account=$SA_EMAIL --project=$PROJECT_ID &> /dev/null; then
    echo "✅ ÉXITO: Se pudo leer de la carpeta pública."
else
    echo "❌ ERROR: No se pudo leer de la carpeta pública."
fi

# Test 2: Acceder a la carpeta PRIVADA (debería fallar)
echo "Intentando leer de 'private/private.txt' (debería fallar)..."
if gcloud storage cat gs://$BUCKET_NAME/private/private.txt --impersonate-service-account=$SA_EMAIL --project=$PROJECT_ID &> /dev/null; then
    echo "❌ ERROR: Se pudo leer de la carpeta privada. La condición no funcionó."
else
    echo "✅ ÉXITO: Acceso denegado a la carpeta privada, como se esperaba."
fi

# --- 4. CLEANUP (Limpieza) ---
echo -e "\n--- Limpiando recursos... ---"

# Eliminar el bucket
echo "Eliminando bucket..."
gcloud storage rm --recursive gs://$BUCKET_NAME

# Eliminar la Cuenta de Servicio
echo "Eliminando cuenta de servicio..."
gcloud iam service-accounts delete $SA_EMAIL --quiet --project=$PROJECT_ID

# Eliminar ficheros locales
rm public.txt private.txt

echo -e "\nLimpieza completada."
```

---

## 💡 Lecciones Aprendidas

*   **Las Condiciones son para el "cuándo" y el "cómo":** Úsalas para añadir lógica contextual a tus permisos (ej. acceso temporal, por IP, por etiqueta de recurso).
*   **Deny es para el "nunca":** Usa Deny Policies para establecer barandillas de seguridad no negociables que protejan tus recursos más críticos.
*   **Combinación potente:** Puedes usar Deny Policies con excepciones. Por ejemplo, denegar un permiso a todos excepto a los miembros de un grupo específico (`principalSet.except('group:mi-grupo@example.com')`).

---

## ⚠️ Errores y Confusiones Comunes

*   **Condiciones demasiado complejas:** Una expresión CEL muy compleja puede ser difícil de depurar y entender. Mantén las condiciones lo más simple posible.
*   **Olvidar que Deny anula todo:** Un administrador puede sorprenderse al no poder realizar una acción para la que tiene un rol `allow`, sin darse cuenta de que una Deny Policy a un nivel superior de la jerarquía se lo está impidiendo.
*   **Condiciones vs. Deny:** No son intercambiables. Las condiciones refinan un permiso `allow`. Deny es un bloqueo absoluto.

---

## 🎯 Tips de Examen

*   **Acceso condicional = IAM Conditions:** Si un escenario describe la necesidad de conceder acceso basado en atributos (fecha/hora, etiquetas, etc.), la respuesta es IAM Conditions.
*   **Bloqueo absoluto = Deny Policy:** Si un escenario requiere prohibir una acción a (casi) todos para evitar un desastre, la respuesta es una Deny Policy.
*   **Orden de evaluación:** Recuerda que IAM evalúa Deny *antes* que Allow. Si Deny dice no, la evaluación se detiene y el acceso es denegado.

---

## 🧾 Resumen

IAM Conditions y Deny Policies son las herramientas de precisión de Cloud IAM. Mientras que los roles definen "qué" se puede hacer, las condiciones y las políticas de denegación te dan un control sin precedentes sobre el "cómo", "cuándo", "dónde" y, lo más importante, el "nunca". Dominar estas herramientas es esencial para implementar una seguridad de privilegio mínimo verdaderamente robusta y contextual en Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#️-iam-conditions-y-deny-policies)
