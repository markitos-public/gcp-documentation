# ☁️ Cloud Key Management Service (KMS): Gestión Centralizada de Claves Criptográficas

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

**Cloud Key Management Service (KMS)** es un servicio gestionado de Google Cloud que permite crear, importar y gestionar claves criptográficas y realizar operaciones con ellas en una ubicación centralizada. Cloud KMS no expone directamente el material de la clave; en su lugar, proporciona una API para cifrar y descifrar datos utilizando esas claves. Esto permite a las aplicaciones y servicios de GCP proteger datos en reposo (at-rest) y en uso, aplicando el principio de separación de responsabilidades: los datos están en un lugar (ej. Cloud Storage) y las claves para descifrarlos están en otro (Cloud KMS), gestionadas con permisos de IAM distintos.

---

## 📘 Detalles

Cloud KMS se organiza en una jerarquía de recursos que facilita la gestión y el control de acceso.

### 🔹 Jerarquía de Recursos de KMS

1.  **Key Ring (Anillo de Claves):** Es un agrupador lógico de claves que pertenece a un proyecto de GCP y reside en una ubicación geográfica específica (ej. `europe-west1` o `global`). No se puede cambiar la ubicación de un Key Ring después de su creación. Sirve para organizar claves por entorno (desarrollo, producción) o por aplicación.

2.  **Key (Clave):** Representa una clave criptográfica con un propósito específico (ej. cifrado simétrico, firma asimétrica). Una clave contiene una o más versiones.

3.  **Key Version (Versión de la Clave):** Es el recurso que contiene el material criptográfico real. Cuando se rota una clave, se crea una nueva versión y se convierte en la "versión primaria". Las versiones antiguas se pueden seguir utilizando para descifrar datos que fueron cifrados con ellas, pero no para cifrar datos nuevos. Las versiones se pueden habilitar, deshabilitar o destruir.

### 🔹 Tipos de Claves y Operaciones

*   **Cifrado Simétrico:** Se utiliza una única clave tanto para cifrar como para descifrar. Es el caso de uso más común para proteger datos en reposo. Los servicios de GCP utilizan este método para el Cifrado de Claves de Cifrado (Envelope Encryption).
*   **Cifrado Asimétrico:** Se utiliza un par de claves: una pública para cifrar y una privada (gestionada por KMS) para descifrar. Útil cuando una entidad no confiable necesita cifrar datos que solo el propietario de la clave privada puede leer.
*   **Firma Digital Asimétrica:** Se utiliza una clave privada (gestionada por KMS) para firmar datos y una clave pública para verificar la firma. Esto garantiza la autenticidad e integridad de los datos. Es la base de servicios como Binary Authorization.

### 🔹 Envelope Encryption (Cifrado de Sobre)

Es el patrón estándar para cifrar grandes volúmenes de datos. En lugar de enviar gigabytes de datos a la API de KMS (lo cual sería lento y costoso), el proceso es:
1.  Se genera una clave localmente, llamada Clave de Cifrado de Datos (DEK - Data Encryption Key).
2.  Se utilizan los datos para cifrar la DEK con una clave de KMS, llamada Clave de Cifrado de Claves (KEK - Key Encryption Key).
3.  Se almacenan los datos cifrados junto con la DEK *cifrada*. La DEK en texto plano se descarta.
4.  Para descifrar, se recupera la DEK cifrada, se llama a la API de KMS para descifrarla usando la KEK, y luego se usa la DEK en texto plano para descifrar los datos localmente.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio demuestra el patrón de Envelope Encryption usando `gcloud`.

### ARRANGE (Preparación)

```bash
# 1. Definir variables de entorno
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west1"
export KEYRING_NAME="my-app-keyring"
export KEY_NAME="data-protection-key"

# 2. Habilitar la API de Cloud KMS
gcloud services enable cloudkms.googleapis.com

# 3. Crear un Key Ring
gcloud kms keyrings create $KEYRING_NAME --location=$REGION

# 4. Crear una Key para cifrado simétrico
gcloud kms keys create $KEY_NAME \
    --keyring=$KEYRING_NAME \
    --location=$REGION \
    --purpose=encryption

# 5. Crear un archivo de ejemplo con datos sensibles
echo "Este es mi secreto más grande" > secret.txt
```

### ACT (Implementación)

```bash
# 1. Cifrar el archivo usando la clave de KMS (gcloud gestiona el Envelope Encryption por nosotros)
# gcloud generará una DEK, cifrará el archivo con ella, y luego cifrará la DEK con nuestra KEK de KMS.
gcloud kms encrypt \
  --keyring=$KEYRING_NAME \
  --key=$KEY_NAME \
  --location=$REGION \
  --plaintext-file=secret.txt \
  --ciphertext-file=secret.txt.enc

# 2. (Opcional) Inspeccionar el archivo cifrado. No será legible.
cat secret.txt.enc
```

### ASSERT (Verificación)

```bash
# 1. Descifrar el archivo usando la misma clave de KMS
# gcloud leerá la DEK cifrada del archivo, la enviará a KMS para descifrarla, y usará la DEK resultante para descifrar el archivo.
gcloud kms decrypt \
  --keyring=$KEYRING_NAME \
  --key=$KEY_NAME \
  --location=$REGION \
  --ciphertext-file=secret.txt.enc \
  --plaintext-file=secret.decrypted.txt

# 2. Verificar que el contenido descifrado es idéntico al original
diff secret.txt secret.decrypted.txt
# Si no hay salida, los archivos son idénticos, lo que prueba que el ciclo de cifrado/descifrado funcionó.
```

### CLEANUP (Limpieza)

```bash
# Eliminar los archivos locales
rm secret.txt secret.txt.enc secret.decrypted.txt

# Deshabilitar y destruir la versión de la clave (¡ACCIÓN DESTRUCTIVA!)
# Primero, obtenemos la versión 1 de la clave
export KEY_VERSION=1
gcloud kms keys versions disable $KEY_VERSION --key=$KEY_NAME --keyring=$KEYRING_NAME --location=$REGION
gcloud kms keys versions destroy $KEY_VERSION --key=$KEY_NAME --keyring=$KEYRING_NAME --location=$REGION

# Nota: La destrucción de claves es irreversible. Hay un período de gracia (configurable) antes de la destrucción final.

# Eliminar la clave y el keyring (opcional, pueden ser reutilizados)
# gcloud kms keys delete $KEY_NAME --keyring=$KEYRING_NAME --location=$REGION
# gcloud kms keyrings delete $KEYRING_NAME --location=$REGION
```

---

## 💡 Lecciones Aprendidas

*   **Nunca Almacenes Claves en el Código:** El propósito fundamental de KMS es externalizar la gestión de claves. Las claves deben estar en KMS, y el acceso a ellas debe ser controlado por IAM, no por secretos hardcodeados en el código o en archivos de configuración.
*   **Separación de Responsabilidades es Poder:** Al separar los datos de las claves, se crea una barrera de seguridad muy fuerte. Un atacante que logra acceder a un bucket de Cloud Storage no puede leer los datos si no tiene también los permisos de IAM (`roles/cloudkms.cryptoKeyDecrypter`) para usar la clave en KMS.
*   **La Rotación de Claves es Higiene Criptográfica:** Rotar las claves regularmente limita el "radio de explosión" si una versión de clave se viera comprometida. KMS automatiza este proceso, creando nuevas versiones sin interrumpir la capacidad de descifrar datos antiguos.

---

## ⚠️ Errores y Confusiones Comunes

*   **Error: Intentar Extraer el Material de la Clave:** Cloud KMS es un sistema de "caja negra". Está diseñado para que el material criptográfico de las claves gestionadas por Google nunca salga del servicio. No se puede exportar una clave privada; solo se puede usar para operaciones *dentro* de KMS.
*   **Confusión: Cloud KMS vs. Secret Manager:** KMS gestiona *claves criptográficas* para realizar operaciones (cifrar, firmar). Secret Manager gestiona *secretos de aplicación* (API keys, contraseñas, certificados) para ser entregados a las aplicaciones en tiempo de ejecución. Aunque KMS puede usarse para cifrar los secretos que almacena Secret Manager, sus propósitos son diferentes.
*   **Problema: Permisos de IAM Demasiado Amplios:** Asignar el rol `roles/cloudkms.admin` a una cuenta de servicio de aplicación es un gran riesgo. Las aplicaciones solo necesitan roles específicos como `roles/cloudkms.cryptoKeyEncrypter` o `roles/cloudkms.cryptoKeyDecrypter` para realizar su trabajo, siguiendo el principio de mínimo privilegio.

---

## 🎯 Tips de Examen

*   **Jerarquía:** Recuerda el orden: **Key Ring** (ubicación, proyecto) > **Key** (propósito, nombre) > **Key Version** (material criptográfico).
*   **Envelope Encryption:** Entiende el concepto de DEK (Data Encryption Key) y KEK (Key Encryption Key). Es un patrón fundamental para el cifrado de datos en la nube.
*   **Roles de IAM:** Conoce los roles clave: `cloudkms.admin` (gestión), `cloudkms.cryptoKeyEncrypter` (solo cifrar), `cloudkms.cryptoKeyDecrypter` (solo descifrar), y `cloudkms.signer` (firmar).
*   **Importación de Claves (BYOK/HYOK):** KMS permite importar tus propias claves (Bring Your Own Key) o usar claves gestionadas en un sistema externo (Hold Your Own Key con KMS Externo).

---

## 🧾 Resumen

Cloud KMS es el ancla de confianza para la protección de datos en GCP. Al centralizar la gestión de claves y controlar estrictamente su uso a través de IAM, permite a las organizaciones cifrar datos sensibles de forma segura y escalable. Su diseño de "caja negra" y la implementación del patrón de Envelope Encryption son esenciales para una estrategia de seguridad de datos robusta en la nube.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-key-management-service-kms-gestión-centralizada-de-claves-criptográficas)
