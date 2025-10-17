#!/bin/bash
set -euo pipefail

# Directorio donde se instalará la CLI de gcloud
INSTALL_DIR="${HOME}/.local"
GCLOUD_SDK_DIR="${INSTALL_DIR}/google-cloud-sdk"
GCLOUD_ARCHIVE="google-cloud-cli-linux-x86_64.tar.gz"
GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_ARCHIVE}"

echo "Instalando Google Cloud CLI en ${GCLOUD_SDK_DIR}..."

# 1. Crear el directorio de instalación si no existe
echo "Asegurando que el directorio ${INSTALL_DIR} existe..."
mkdir -p "${INSTALL_DIR}"

# 2. Descargar el archivo en /tmp
echo "Descargando ${GCLOUD_URL}..."
curl -o "/tmp/${GCLOUD_ARCHIVE}" "${GCLOUD_URL}"

# 3. Extraer el archivo en el directorio de destino
echo "Extrayendo el archivo en ${INSTALL_DIR}..."
tar -xzf "/tmp/${GCLOUD_ARCHIVE}" -C "${INSTALL_DIR}"

# 4. Ejecutar el script de instalación
echo "Ejecutando el script de instalación..."
"${GCLOUD_SDK_DIR}/install.sh"

# 5. Limpiar el archivo descargado
echo "Limpiando archivos temporales..."
rm "/tmp/${GCLOUD_ARCHIVE}"

echo ""
echo "¡Instalación completada!"
echo "Por favor, reinicia tu terminal o ejecuta 'source ~/.bashrc' (o el archivo de tu shell) para aplicar los cambios en el PATH."
