# ☁️ Cloud Debugger

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

Cloud Debugger es una funcionalidad de Google Cloud que te permite inspeccionar el estado de una aplicación en ejecución en tiempo real, sin detenerla ni ralentizarla significativamente. Su propósito es permitirte capturar el estado del código (variables y pila de llamadas) en producción como si tuvieras un depurador tradicional, pero de una manera segura y no intrusiva.

Resuelve un problema clásico del desarrollo: la dificultad de diagnosticar errores que solo ocurren en el entorno de producción. Elimina la necesidad de añadir logs a ciegas y redesplegar (el llamado "printf debugging") para entender un problema, reduciendo drásticamente el tiempo necesario para diagnosticar y solucionar problemas complejos.

---

## 📘 Detalles

Debugger ofrece dos herramientas principales para inspeccionar tu código en vivo.

### 🔹 Snapshots (Instantáneas)

Una **Snapshot** es una captura única del estado de tu aplicación en una línea de código específica. Cuando estableces una snapshot:
1.  El agente de Debugger vigila esa línea de código.
2.  La próxima vez que una solicitud de un usuario ejecute esa línea, el agente captura los valores de las variables locales y la pila de llamadas completa en ese preciso instante.
3.  Los datos capturados se envían a la consola de Debugger para su análisis.

Lo más importante es que este proceso es **no bloqueante**. La aplicación no se detiene. La captura añade apenas unos milisegundos de latencia a esa única solicitud y luego se desactiva automáticamente. Es como tomar una fotografía instantánea del interior de tu código en un momento exacto.

### 🔹 Logpoints (Puntos de Registro)

Un **Logpoint** te permite inyectar una nueva línea de log en una aplicación que ya está en ejecución, **sin necesidad de cambiar el código ni de redesplegar**. Cuando estableces un logpoint:
1.  Eliges una línea de código y escribes el mensaje de log que quieres emitir, que puede incluir expresiones para evaluar variables (ej. "Procesando el pedido para el usuario: {user_id}").
2.  Cada vez que una solicitud ejecuta esa línea, el agente de Debugger inyecta el mensaje de log y lo envía a Cloud Logging.

Los logpoints permanecen activos hasta que los eliminas o expiran (tras 24 horas), lo que te permite observar el comportamiento de una parte del código a lo largo del tiempo.

### 🔹 Condiciones

Tanto las snapshots como los logpoints pueden tener **condiciones** (ej. `user.id == "12345"` o `items.count > 10`). La snapshot o el logpoint solo se activarán si la expresión de la condición es verdadera en el momento de la ejecución, lo que permite un diagnóstico increíblemente específico y dirigido.

### 🔹 Instrumentación

Al igual que Trace y Profiler, Debugger requiere que un **agente** se integre en tu aplicación. Es una pequeña librería que se añade a las dependencias de tu proyecto y se inicia en el código. Este agente se comunica de forma segura con el backend de Debugger para saber dónde están los puntos de inspección activos. Hay agentes disponibles para los lenguajes más populares como Java, Python, Go, Node.js, Ruby y .NET.

---

## 🔬 Laboratorio Práctico (CLI-TDD)

**Escenario:** Debugger es una herramienta principalmente visual e interactiva. Usaremos la CLI para desplegar una aplicación con el agente de Debugger y luego te guiaré por los pasos manuales en la consola de Google Cloud para usarlo.

### ARRANGE (Preparación)

```bash
# Variables del proyecto y configuración
export PROJECT_ID=$(gcloud config get-value project)
export REGION="europe-west"

# Habilitar APIs necesarias
echo "Habilitando APIs de App Engine y Debugger..."
gcloud services enable appengine.googleapis.com clouddebugger.googleapis.com sourcerepo.googleapis.com

# Crear una aplicación de App Engine (si no existe)
gcloud app create --region=$REGION

# Crear el código de una aplicación Python con el agente de Debugger
mkdir gae-debugger-demo
cd gae-debugger-demo

cat > main.py <<EOF
from flask import Flask, request
import googleclouddebugger

app = Flask(__name__)

@app.route('/')
def hello():
    user_id = request.args.get('user', 'guest')
    message = f"Hello, {user_id}!"
    process_request(user_id, message)
    return message

def process_request(user, msg):
    # Aquí es donde pondremos nuestra snapshot y logpoint
    data = {"user": user, "message": msg, "status": "processed"}
    print("Request processed")

if __name__ == '__main__':
    try:
        # Iniciar el agente de Debugger
        googleclouddebugger.enable(
            module='debugger-demo-app',
            version='1.0.0'
        )
    except Exception as e:
        print(f"Could not start debugger: {e}")
    app.run(host='127.0.0.1', port=8080, debug=True)
EOF

cat > requirements.txt <<EOF
Flask==2.2.2
google-cloud-debugger==4.2.0
EOF

cat > app.yaml <<EOF
runtime: python39
EOF
```

### ACT (Implementación)

```bash
# 1. Desplegar la aplicación en App Engine
# El código fuente se sube automáticamente y será visible en Debugger
echo "Desplegando aplicación..."
gcloud app deploy --quiet

# 2. Obtener la URL de la aplicación desplegada
export APP_URL=$(gcloud app browse --no-launch-browser)
echo "Aplicación desplegada en: $APP_URL"

# 3. Enviar tráfico a la aplicación
echo "Enviando una petición de prueba..."
curl "$APP_URL?user=markitos"
```

### ASSERT (Verificación Manual en la UI)

```bash
# La verificación de Debugger es un proceso manual e interactivo.

echo "✅ Aplicación desplegada. Ahora puedes usar Debugger en la consola."
echo ""
echo "---
Pasos para la Snapshot --- (Capturar estado)"
echo "1. Ve a la consola de Google Cloud -> Debugger."
echo "2. Selecciona 'debugger-demo-app' y el fichero 'main.py'."
echo "3. Haz clic en el número de la línea 14 (dentro de la función process_request). Se creará una Snapshot."
echo "4. Envía otra petición desde tu terminal: curl \"$APP_URL?user=test-user\""
echo "5. Vuelve a la consola. La snapshot se activará y podrás ver las variables 'user', 'msg' y 'data' en el panel derecho."


echo "---
Pasos para el Logpoint --- (Inyectar logs)"
echo "1. En la misma interfaz, haz clic derecho en la línea 15 y selecciona 'Add Logpoint'."
echo "2. En el cuadro de texto, escribe: \"Procesando datos para el usuario: {user}\" y pulsa Enter."
echo "3. Envía otra petición: curl \"$APP_URL?user=logpoint-test\""
echo "4. Ve a la consola de Google Cloud -> Logging -> Log Explorer."
echo "5. Deberías ver un nuevo log con el mensaje: 'Procesando datos para el usuario: logpoint-test'."
```

### CLEANUP (Limpieza)

```bash
echo "⚠️  Eliminando recursos de laboratorio..."
gcloud app services delete default --quiet
cd ..
rm -rf gae-debugger-demo

echo "✅ Laboratorio completado - Recursos eliminados"
```

---

## 💡 Lecciones Aprendidas

*   **Depurar en producción ya no es un tabú:** Herramientas como Cloud Debugger lo hacen seguro y efectivo, permitiéndote encontrar errores que son imposibles de replicar en entornos locales.
*   **Snapshots para el "qué", Logpoints para el "cómo":** Las snapshots son para una inmersión profunda en el estado de un momento concreto. Los logpoints son para observar el comportamiento o el flujo de una parte del código a lo largo del tiempo.
*   **El contexto de producción es irreplicable:** Poder inspeccionar el estado de tu aplicación con datos y patrones de tráfico reales es una capacidad de diagnóstico de un valor incalculable.

---

## ⚠️ Errores y Confusiones Comunes

*   **Pensar que es un depurador tradicional:** Esperar que la aplicación se detenga (breakpoint) o poder avanzar paso a paso. Cloud Debugger es **no bloqueante** y solo toma una "fotografía" (snapshot).
*   **Agente mal configurado:** Olvidar incluir la librería del agente en las dependencias o no iniciarla correctamente en el código de la aplicación. Si el servicio no aparece en la UI de Debugger, este suele ser el motivo.
*   **Falta de permisos IAM:** El usuario que intenta establecer una snapshot o un logpoint necesita el rol `clouddebugger.agent` para poder interactuar con el servicio.

---

## 🎯 Tips de Examen

*   Conoce las dos funcionalidades principales: **Snapshots** (capturan la pila de llamadas y las variables una vez) y **Logpoints** (inyectan mensajes de log sin redesplegar).
*   Entiende que Debugger es **no bloqueante** y seguro para producción. **No detiene** la ejecución de la aplicación.
*   Recuerda que requiere un **agente** que debe ser incluido en el código de la aplicación.
*   Asocia Debugger con la inspección del **estado de la aplicación** en un entorno en vivo.

---

## 🧾 Resumen

Cloud Debugger cierra la brecha entre el desarrollo y la producción, permitiendo a los desarrolladores inspeccionar de forma segura el estado de una aplicación en vivo sin detenerla. Mediante el uso de snapshots para capturar variables y logpoints para inyectar logs dinámicos, acelera drásticamente el proceso de diagnóstico y corrección de errores que son específicos de los entornos de producción.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-cloud-debugger)
