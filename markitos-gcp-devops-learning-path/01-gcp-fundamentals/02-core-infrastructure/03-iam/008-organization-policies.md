
# 📜 008: Políticas de Organización (Organization Policies)

## 📝 Índice

1.  [Descripción](#descripción)
2.  [La Diferencia Clave: IAM vs. Políticas de Organización](#la-diferencia-clave-iam-vs-políticas-de-organización)
3.  [Detalles](#detalles)
    *   [Constraints (Restricciones)](#constraints-restricciones)
    *   [Herencia en la Jerarquía de Recursos](#herencia-en-la-jerarquía-de-recursos)
    *   [Tipos de Políticas](#tipos-de-políticas)
    *   [Comandos `gcloud` Ilustrativos](#comandos-gcloud-ilustrativos)
4.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
5.  [🧠 Lecciones Aprendidas](#lecciones-aprendidas)
6.  [🤔 Errores y Confusiones Comunes](#errores-y-confusiones-comunes)
7.  [💡 Tips de Examen](#tips-de-examen)
8.  [✍️ Resumen](#resumen)
9.  [🔖 Firma](#firma)

---

### Descripción

Las **Políticas de Organización** son un servicio de GCP que permite a los administradores establecer un control centralizado y programático sobre los recursos de la nube de su organización. A diferencia de IAM, que gestiona "quién puede hacer qué", las Políticas de Organización definen "qué se puede hacer" en un ámbito jerárquico (Organización, Carpeta o Proyecto), estableciendo barreras de seguridad y cumplimiento normativo.

Permiten imponer restricciones sobre cómo se pueden configurar y utilizar los servicios de GCP. Por ejemplo, puedes restringir la creación de IPs externas para VMs, limitar las regiones geográficas donde se pueden desplegar recursos o forzar que los buckets de Cloud Storage no sean públicos.

### La Diferencia Clave: IAM vs. Políticas de Organización

Esta es la fuente de confusión más habitual. Aclarémoslo:

*   👤 **IAM (Identity and Access Management):**
    *   **Propósito:** Controlar el **acceso**.
    *   **Pregunta que responde:** ¿**Quién** (un usuario, un grupo, una service account) tiene **qué permiso** (rol) sobre **qué recurso**?
    *   **Enfoque:** En la **identidad** (el "principal").
    *   **Ejemplo:** "El usuario `developer@example.com` tiene el rol `roles/compute.instanceAdmin` en el proyecto `my-project`". Esto le permite administrar VMs.

*   📜 **Políticas de Organización (Organization Policies):**
    *   **Propósito:** Controlar la **configuración** de los recursos.
    *   **Pregunta que responde:** ¿**Qué configuraciones** están permitidas para los recursos dentro de esta Organización, Carpeta o Proyecto?
    *   **Enfoque:** En el **recurso** y sus atributos.
    *   **Ejemplo:** "La política de organización `constraints/compute.vmExternalIpAccess` está configurada en `deny` para toda la organización". Esto significa que **nadie**, ni siquiera un `owner` del proyecto, podrá crear una VM con una IP externa. La política prevalece sobre el permiso de IAM.

En resumen, IAM autoriza a las identidades, mientras que las Políticas de Organización restringen el comportamiento de los propios recursos. Son dos capas de gobernanza complementarias y potentes.

### Requisitos Previos

Antes de poder utilizar el Servicio de Políticas de Organización, es fundamental cumplir con dos requisitos clave:

1.  **Recurso de Organización:** Es **obligatorio** tener un recurso de **Organización** en Google Cloud. Este servicio no está disponible para cuentas que solo utilizan proyectos de forma aislada. La jerarquía que comienza con una Organización es un prerrequisito indispensable.

2.  **Permisos de IAM:** Para ver o administrar políticas de organización, necesitas un rol de IAM específico. El rol predefinido principal es:
    *   `roles/orgpolicy.policyAdmin` (**Administrador de políticas de la organización**): Concede todos los permisos para crear, modificar, eliminar y ver políticas.
    *   Para solo ver las políticas existentes, el rol `roles/orgpolicy.policyViewer` es suficiente.

Sin estos dos elementos, no podrás implementar la gobernanza a través de las Políticas de Organización.

### Detalles

#### Constraints (Restricciones)

El corazón de las Políticas de Organización son las **constraints**. Una constraint es una definición de un comportamiento específico de un servicio de GCP que puede ser controlado. Hay dos tipos:

1.  **List Constraints:** La política se evalúa contra una lista de valores permitidos o denegados.
    *   `allow`: Define una lista de valores permitidos.
    *   `deny`: Define una lista de valores denegados.
    *   **Ejemplo:** `constraints/compute.trustedImageProjects`: Solo permite usar imágenes de VMs de una lista específica de proyectos.

2.  **Boolean Constraints:** La política se aplica para todo el recurso y su valor es `true` o `false`.
    *   `enforce: true`: La restricción está activa.
    *   **Ejemplo:** `constraints/compute.vmExternalIpAccess`: Si se establece en `enforce: true` (o `deny` en la CLI), se prohíbe la creación de IPs externas en VMs.

#### Herencia en la Jerarquía de Recursos

Las políticas se heredan de forma descendente en la jerarquía de GCP: **Organización -> Carpeta -> Proyecto**.

*   Una política definida a nivel de Organización se aplica a todas las carpetas y proyectos que contiene.
*   Un administrador en un nivel inferior (ej. Proyecto) puede definir una política más restrictiva que la heredada, pero **nunca más permisiva**.
*   Si una política se establece como `inherit: true` en un nodo inferior, simplemente hereda la configuración del nodo superior.

#### Comandos `gcloud` Ilustrativos

```bash
# 1. Listar todas las constraints disponibles
gcloud org-policies list-custom-constraints

# 2. Describir una constraint específica para ver qué hace
gcloud org-policies describe constraints/compute.vmExternalIpAccess

# 3. Ver la política efectiva para un proyecto
gcloud org-policies describe constraints/compute.vmExternalIpAccess --project="my-gcp-project"

# 4. Crear un fichero de política (policy.yaml) para denegar IPs externas
# enforce: true
# O, para una lista:
# list_policy:
#   denied_values:
#     - "projects/untrusted-project"

# 5. Aplicar la política a nivel de proyecto
gcloud org-policies set-policy "projects/my-gcp-project" policy.yaml
```

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Restringir la creación de Service Accounts a un dominio específico (`@example.com`) para un proyecto.

1.  **Test (Verificación inicial):** Primero, describe la política `iam.allowedPolicyMemberDomains` en tu proyecto. Por defecto, no estará configurada.
    ```bash
    gcloud org-policies describe constraints/iam.allowedPolicyMemberDomains --project=$PROJECT_ID
    # Esperado: La política no está definida (no `listPolicy`).
    ```

2.  **Act (Aplicar la política):** Crea un archivo `allow-domains-policy.yaml` con el siguiente contenido:
    ```yaml
    constraint: "constraints/iam.allowedPolicyMemberDomains"
    listPolicy:
      allValues: "ALLOW"
      allowedValues:
        - "domain:example.com" # ¡Reemplaza con un dominio que controles!
    ```

3.  **Apply (Establecer la política):**
    ```bash
    gcloud org-policies set-policy "projects/$PROJECT_ID" allow-domains-policy.yaml
    ```

4.  **Test (Verificación final):** Intenta añadir un miembro a una política IAM que no pertenezca al dominio permitido (ej. una cuenta de `@gmail.com`).
    ```bash
    # Intenta añadir un usuario externo a un rol del proyecto
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="user:some.user@gmail.com" \
        --role="roles/viewer"
    # Esperado: Error. La operación falla indicando una violación de la política de organización.
    ```

5.  **Cleanup:** Para limpiar, crea un `cleanup-policy.yaml` y aplícalo.
    ```yaml
    constraint: "constraints/iam.allowedPolicyMemberDomains"
    listPolicy:
      allValues: "ALLOW" # Restaura el comportamiento por defecto
    ```
    ```bash
    gcloud org-policies set-policy "projects/$PROJECT_ID" cleanup-policy.yaml
    ```

### 🧠 Lecciones Aprendidas

*   Las Políticas de Organización son una barrera de seguridad proactiva, no reactiva. Previenen problemas de configuración antes de que ocurran.
*   La separación entre IAM y Políticas de Organización es clave para una buena gobernanza: IAM para el acceso, Org Policies para el comportamiento de los recursos.
*   La herencia es tu aliada. Define políticas restrictivas en los niveles altos de la jerarquía para garantizar una base de seguridad sólida en toda la organización.

### 🤔 Errores y Confusiones Comunes

*   **Confundir IAM y Org Policies:** El error más común. Recuerda: IAM = Quién, Org Policies = Qué.
*   **Intentar "ignorar" una política con permisos de IAM:** Un `owner` de proyecto no puede saltarse una Política de Organización. La política siempre gana.
*   **Sintaxis de los ficheros YAML:** Un error en el `constraint` o en la estructura de `listPolicy` hará que el comando `gcloud` falle. Valida la sintaxis con cuidado.
*   **No entender la herencia:** Aplicar una política en un proyecto y no ver el resultado esperado porque una política más restrictiva está definida en una carpeta superior.

### 💡 Tips de Examen

*   Si una pregunta de examen te presenta un escenario donde un usuario con permisos de `owner` no puede realizar una acción (como crear un recurso con una configuración específica), la respuesta casi siempre involucra una **Política de Organización** que lo está bloqueando.
*   Memoriza ejemplos clave de constraints:
    *   `compute.vmExternalIpAccess`: Controlar IPs públicas.
    *   `iam.allowedPolicyMemberDomains`: Restringir identidades por dominio.
    *   `gcp.resourceLocations`: Limitar las regiones donde se pueden crear recursos.
*   Comprende la diferencia entre `allow` y `deny` en `ListConstraint` y cómo se fusionan las políticas heredadas.

### ✍️ Resumen

Las Políticas de Organización son una herramienta de gobernanza esencial en GCP para aplicar restricciones a nivel de toda la jerarquía de recursos. Definen qué configuraciones de servicios están permitidas o denegadas, actuando como una capa de control que complementa a IAM. Mientras IAM gestiona el acceso de las identidades, las Políticas de Organización garantizan que los recursos se mantengan dentro de los límites de cumplimiento y seguridad definidos por la organización.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-mejores-prácticas-de-iam-iam-best-practices)
