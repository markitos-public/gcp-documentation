# ☁️ Visión General de Facturación y Gestión de Costos en GCP

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

La **Gestión de Costos y Facturación (Billing and Cost Management)** en Google Cloud es el conjunto de herramientas y procesos que permiten entender, controlar y optimizar los costos asociados al uso de los servicios de GCP. No se trata solo de pagar la factura, sino de tener visibilidad sobre qué servicios consumen presupuesto, asignar costos a equipos o proyectos específicos, establecer alertas para evitar sorpresas y tomar decisiones informadas para reducir gastos. Para un rol DevSecOps, dominar la gestión de costos es tan crucial como gestionar el rendimiento o la seguridad.

---

## 📘 Detalles

La gestión de costos en GCP se articula en torno a varios componentes clave que trabajan juntos.

### 🔹 Cuentas de Facturación (Billing Accounts)

Una cuenta de facturación es el recurso de GCP que se utiliza para pagar por el uso de los servicios. Un proyecto de GCP debe estar vinculado a una cuenta de facturación para poder habilitar la mayoría de las APIs. Existen dos tipos de cuentas: de **autoservicio** (pago con tarjeta de crédito o débito) y de **facturación** (pago mediante factura, requiere un acuerdo con Google). Una única cuenta de facturación puede estar vinculada a múltiples proyectos, lo que permite una facturación centralizada.

### 🔹 Presupuestos y Alertas (Budgets and Alerts)

Los **presupuestos** son una herramienta fundamental para el control de costos. Permiten definir un monto mensual esperado para un proyecto, un conjunto de servicios o una cuenta de facturación completa. Se pueden establecer umbrales (ej. al 50%, 90% y 100% del presupuesto) que, al alcanzarse, disparan **alertas** por correo electrónico o a través de notificaciones de Pub/Sub. Estas alertas son informativas y **no detienen los servicios automáticamente**, pero permiten tomar acciones proactivas.

### 🔹 Informes de Costos (Cost Reports)

La consola de GCP ofrece informes de costos detallados y personalizables. Estos informes permiten visualizar los gastos a lo largo del tiempo, agruparlos por proyecto, servicio, etiqueta (label) o SKU (Stock Keeping Unit). Son la herramienta principal para analizar tendencias, identificar los servicios más costosos y entender la distribución del gasto.

### 🔹 Exportación de Datos de Facturación (Billing Data Export)

Para un análisis más profundo, GCP permite exportar datos de facturación detallados a **BigQuery**. Esto abre la puerta a la creación de dashboards personalizados (por ejemplo, en Looker Studio), al análisis de costos a nivel de recurso individual y a la implementación de lógicas de FinOps complejas. Se pueden exportar tres tipos de datos: datos de costos estándar, datos de costos detallados (incluyendo recursos) y datos de precios.

### 🔹 Optimización de Costos

GCP proporciona recomendaciones de optimización de costos a través del **Recommender API**. Este servicio analiza el uso de tus recursos y sugiere acciones para ahorrar dinero, como cambiar el tamaño de VMs infrautilizadas (`rightsizing`), reclamar recursos inactivos o comprometerse a descuentos por uso continuo (CUDs).

---

## 🔬 Laboratorio Práctico (CLI-TDD)

Este laboratorio muestra cómo crear un presupuesto y una alerta para un proyecto usando `gcloud`.

### ARRANGE (Preparación)

```bash
# Estos comandos se ejecutan en Cloud Shell.

# Habilitar la API de Billing
gcloud services enable billingbudgets.googleapis.com

# Obtener el ID de tu cuenta de facturación activa
# NOTA: Debes tener permisos de Administrador de Cuentas de Facturación para esto.
export BILLING_ACCOUNT_ID=$(gcloud beta billing accounts list --filter="open=true" --format="value(accountId)" | head -n 1)

# Verificar que la variable no esté vacía
if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
  echo "No se pudo obtener una cuenta de facturación activa. Verifica tus permisos."
  exit 1
fi

echo "Usando la cuenta de facturación: $BILLING_ACCOUNT_ID"
```

### ACT (Implementación)

```bash
# Crear un presupuesto de 100 EUR para la cuenta de facturación completa
# Se notificarà al alcanzar el 50%, 90% y 100% del presupuesto.
gcloud beta billing budgets create --billing-account=$BILLING_ACCOUNT_ID \
    --display-name="Presupuesto General DevSecOps" \
    --budget-amount=100 \
    --budget-currency-code="EUR" \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90 \
    --threshold-rule=percent=100
```

### ASSERT (Verificación)

```bash
# Listar los presupuestos para verificar que se ha creado
gcloud beta billing budgets list --billing-account=$BILLING_ACCOUNT_ID

# Describir el presupuesto específico para ver sus detalles
gcloud beta billing budgets describe "Presupuesto General DevSecOps" --billing-account=$BILLING_ACCOUNT_ID
```

### CLEANUP (Limpieza)

```bash
# Obtener el ID del presupuesto para poder eliminarlo
BUDGET_ID=$(gcloud beta billing budgets list --billing-account=$BILLING_ACCOUNT_ID --filter="displayName='Presupuesto General DevSecOps'" --format="value(budgetId)")

# Eliminar el presupuesto
gcloud beta billing budgets delete $BUDGET_ID

# Verificar que ya no existe
gcloud beta billing budgets list --billing-account=$BILLING_ACCOUNT_ID
```

---

## 💡 Lecciones Aprendidas

*   **La Visibilidad es el Primer Paso:** No puedes optimizar lo que no puedes ver. El primer paso en la gestión de costos es siempre configurar la exportación a BigQuery y familiarizarse con los informes de costos.
*   **Las Alertas son tus Amigas:** Los presupuestos y las alertas son la red de seguridad más simple y efectiva para evitar sorpresas desagradables en la factura. Configúralos siempre, incluso para proyectos pequeños.
*   **La Optimización es un Proceso Continuo:** La gestión de costos no es una tarea única. Es un ciclo continuo de análisis (informes), control (presupuestos) y optimización (recomendaciones, `rightsizing`).

---

## ⚠️ Errores y Confusiones Comunes

*   **Creer que los Presupuestos Detienen el Gasto:** El error más peligroso es pensar que alcanzar un presupuesto detiene automáticamente los servicios. **No lo hace**. Un presupuesto solo genera notificaciones. Para detener el gasto, se necesita una acción programática (ej. una Cloud Function que reaccione a la alerta de Pub/Sub).
*   **Ignorar los Costos "Ocultos":** A menudo, los equipos se centran en los costos obvios (VMs, bases de datos) e ignoran los costos de red (egress), almacenamiento de logs o llamadas a APIs, que pueden crecer significativamente.
*   **No Usar Etiquetas (Labels):** Sin un etiquetado consistente de los recursos, es casi imposible asignar costos a equipos, entornos (prod, dev) o aplicaciones específicas. La falta de etiquetas es el principal obstáculo para una buena visibilidad de costos.

---

## 🎯 Tips de Examen

*   **Presupuestos vs. Cuotas:** Una pregunta de examen podría intentar confundir estos dos conceptos. **Presupuesto (Budget)** se refiere al **costo monetario**. **Cuota (Quota)** se refiere a los **límites de uso de un recurso** (ej. número de VMs por región). Son conceptos diferentes.
*   **Exportación a BigQuery:** Si una pregunta habla de análisis de costos avanzado, visualización personalizada o FinOps, la respuesta correcta casi siempre implica **exportar los datos de facturación a BigQuery**.
*   **Los Presupuestos NO detienen servicios:** Este es un punto clave y muy preguntado. Las alertas de presupuesto son solo para **notificar**.

---

## 🧾 Resumen

La gestión de costos en GCP es una disciplina esencial que va más allá del simple pago de facturas. Mediante el uso de herramientas como las cuentas de facturación centralizadas, los presupuestos con alertas, los informes de costos y la exportación a BigQuery, los equipos de DevSecOps pueden obtener visibilidad, ejercer control y optimizar continuamente su gasto en la nube, asegurando que la infraestructura sea no solo potente y segura, sino también costo-eficiente.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-visión-general-de-facturación-y-gestión-de-costos-en-gcp)
