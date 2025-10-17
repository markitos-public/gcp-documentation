# 📦 Visión General de Contenedores

## 📑 Índice
* [🧭 Descripción](#-descripción)
* [📘 Detalles](#-detalles)
* [💻 Laboratorio Práctico (CLI-TDD)](#-laboratorio-práctico-cli-tdd)
* [💡 Lecciones Aprendidas](#-lecciones-aprendidas)
* [⚠️ Errores y Confusiones Comunes](#️-errores-y-confusiones-comunes)
* [🎯 Tips de Examen](#-tips-de-examen)
* [🧾 Resumen](#-resumen)
* [✍️ Firma](#-firma)
* [⬆️ Volver arriba](#-visión-general-de-contenedores)

---

## 🧭 Descripción

Los contenedores son una tecnología de virtualización a nivel de sistema operativo que resuelve el clásico problema del desarrollo de software: "¡Funciona en mi máquina!". Un contenedor empaqueta el código de una aplicación junto con todas sus dependencias (librerías, binarios, ficheros de configuración) en una única unidad ejecutable. Esta unidad, la **imagen de contenedor**, es portable y puede ejecutarse de forma consistente en cualquier entorno que soporte contenedores, desde el portátil de un desarrollador hasta un cluster de producción en la nube.

---

## 📘 Detalles

### Contenedores vs. Máquinas Virtuales (VMs)

La principal diferencia radica en el nivel de abstracción:

*   **Máquinas Virtuales (VMs):** Virtualizan el hardware. Cada VM incluye una copia completa de un sistema operativo, las librerías necesarias y la aplicación. Esto las hace pesadas (gigas de tamaño) y lentas para arrancar.
*   **Contenedores:** Virtualizan el sistema operativo. Comparten el kernel del sistema operativo anfitrión (host) y solo empaquetan el código y las dependencias que no están ya en el SO base. Esto los hace extremadamente ligeros (megas de tamaño) y rápidos para arrancar (segundos o milisegundos).

### Componentes Clave del Ecosistema de Contenedores (Docker)

1.  **Dockerfile:** Es un fichero de texto que contiene las instrucciones para construir una imagen de contenedor. Es la "receta" de tu aplicación. Define la imagen base, las dependencias a instalar, el código a copiar y el comando a ejecutar.

2.  **Imagen (Image):** Es el artefacto inmutable y portable que se crea a partir de un Dockerfile. Es una plantilla de solo lectura.

3.  **Contenedor (Container):** Es una instancia en ejecución de una imagen. Es la capa de lectura/escritura sobre la imagen donde tu aplicación vive y respira.

4.  **Registro (Registry):** Es un repositorio para almacenar y distribuir imágenes de contenedor. **Docker Hub** es el registro público más conocido. **Artifact Registry** es el servicio gestionado de GCP para este propósito.

---

## 💻 Laboratorio Práctico (CLI-TDD)

### 📋 Escenario 1: Construir y Ejecutar un Contenedor Docker Localmente
**Contexto:** Crearemos una aplicación web simple en Python con Flask, la empaquetaremos en un contenedor Docker y la ejecutaremos en nuestra máquina local. (Este laboratorio asume que tienes Docker instalado localmente).

#### ARRANGE (Preparación del laboratorio)
```bash
# Crear un directorio para el proyecto
mkdir mi-app-docker && cd mi-app-docker

# Crear el fichero de la aplicación Python
cat <<EOT > app.py
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return "¡Hola desde mi primer contenedor!"

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
EOT

# Crear el fichero de dependencias
echo "Flask" > requirements.txt

# Crear el Dockerfile (la receta para construir la imagen)
cat <<EOT > Dockerfile
# 1. Usar una imagen base oficial de Python
FROM python:3.9-slim

# 2. Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# 3. Copiar las dependencias e instalarlas
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiar el código de la aplicación
COPY . .

# 5. Exponer el puerto en el que la app escuchará
EXPOSE 8080

# 6. Definir el comando para ejecutar la aplicación
CMD ["python", "app.py"]
EOT
```

#### ACT (Implementación del escenario)
*Construimos la imagen a partir del Dockerfile y luego creamos un contenedor a partir de esa imagen.*
```bash
# 1. Construir la imagen de contenedor
# El -t le da un nombre (tag) a la imagen: mi-app:v1
docker build -t mi-app:v1 .

# 2. Ejecutar un contenedor a partir de la imagen
# -d: modo "detached" (en segundo plano)
# -p 8080:8080: mapea el puerto 8080 de la máquina host al puerto 8080 del contenedor
# --name mi-app-running: le da un nombre a la instancia del contenedor
docker run -d -p 8080:8080 --name mi-app-running mi-app:v1
```

#### ASSERT (Verificación de funcionalidades)
*Verificamos que el contenedor está corriendo y que la aplicación responde.*
```bash
# 1. Listar los contenedores en ejecución
docker ps

# 2. Probar la aplicación con curl
curl http://localhost:8080
# Debería devolver: ¡Hola desde mi primer contenedor!
```

#### CLEANUP (Limpieza de recursos)
```bash
# 1. Detener y eliminar el contenedor
docker stop mi-app-running
docker rm mi-app-running

# 2. Eliminar la imagen
docker rmi mi-app:v1

# 3. Eliminar el directorio del proyecto
cd .. && rm -rf mi-app-docker
```

---

## 💡 Lecciones Aprendidas

*   **Consistencia de Entornos:** Los contenedores eliminan los problemas de "funciona en mi máquina" al asegurar que el entorno de ejecución es idéntico en desarrollo, pruebas y producción.
*   **Portabilidad:** Una imagen de contenedor construida en un portátil con Linux puede ejecutarse sin cambios en una VM de Windows en la nube (siempre que Docker esté instalado).
*   **Eficiencia de Recursos:** Al compartir el kernel del host, los contenedores son mucho más ligeros que las VMs, lo que permite una mayor densidad de aplicaciones en el mismo hardware.

---

## ⚠️ Errores y Confusiones Comunes

*   **Tratar Contenedores como VMs:** Los contenedores son efímeros y sin estado por diseño. No debes guardar datos importantes dentro de un contenedor en ejecución; para eso se usan volúmenes o bases de datos externas.
*   **Crear Imágenes Enormes:** Un error común es usar una imagen base muy grande (ej. `ubuntu:latest`) e instalar muchas herramientas innecesarias. Las imágenes deben ser lo más pequeñas posible para acelerar la construcción y el despliegue. Usa imágenes `slim` o `alpine` cuando sea posible.
*   **Ejecutar Procesos como Root:** Por defecto, los procesos dentro de un contenedor se ejecutan como el usuario `root`, lo cual es una mala práctica de seguridad. Los Dockerfiles deben configurarse para usar un usuario sin privilegios.

---

## 🎯 Tips de Examen

*   **Contenedor vs. VM:** Es la pregunta más clásica. Contenedor = virtualiza el SO. VM = virtualiza el hardware.
*   **Dockerfile:** Es el fichero de instrucciones para construir una imagen.
*   **Imagen vs. Contenedor:** Una imagen es la plantilla inmutable (la clase). Un contenedor es una instancia en ejecución de esa imagen (el objeto).

---

## 🧾 Resumen

Los contenedores han revolucionado la forma en que se desarrollan, distribuyen y ejecutan las aplicaciones. Al proporcionar un formato de empaquetado estandarizado, portable y ligero, permiten a los equipos de desarrollo moverse más rápido y de forma más fiable. Son la base del desarrollo de aplicaciones nativas de la nube y la tecnología fundamental sobre la que se construyen servicios como Google Kubernetes Engine y Cloud Run.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-visión-general-de-contenedores)
