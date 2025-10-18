
# 📜 002: Cloud DNS

## 📝 Índice

1.  [Descripción](#descripción)
2.  [Conceptos Clave](#conceptos-clave)
3.  [Tipos de Zonas DNS](#tipos-de-zonas-dns)
4.  [Políticas de DNS y Reenvío](#políticas-de-dns-y-reenvío)
5.  [DNSSEC (DNS Security Extensions)](#dnssec-dns-security-extensions)
6.  [🧪 Laboratorio Práctico (CLI-TDD)](#laboratorio-práctico-cli-tdd)
7.  [🧠 Lecciones Aprendidas](#lecciones-aprendidas)
8.  [💡 Tips de Examen](#tips-de-examen)
9.  [✍️ Resumen](#resumen)
10. [🔖 Firma](#firma)

---

### Descripción

**Cloud DNS** es un servicio de sistema de nombres de dominio (DNS) de alto rendimiento, resiliente y global de Google Cloud. Se encarga de traducir nombres de dominio legibles por humanos (como `www.example.com`) a direcciones IP numéricas (como `104.198.14.52`) que las máquinas utilizan para comunicarse entre sí.

Cloud DNS es un servicio fundamental que actúa como la "guía telefónica" de Internet y de tus redes VPC privadas, permitiendo un descubrimiento de servicios fiable y de baja latencia.

### Conceptos Clave

*   **Dominio:** El nombre que estás registrando (ej. `example.com`).
*   **Zona Administrada (Managed Zone):** Es el contenedor para todos los registros DNS que pertenecen al mismo nombre de dominio (ej. la zona `example-com` contiene todos los registros para `example.com`).
*   **Conjunto de Registros (Record Set):** Una entrada dentro de una zona que mapea un nombre a una dirección IP u otra información. Los tipos comunes son:
    *   **A:** Mapea un nombre de host a una dirección IPv4.
    *   **AAAA:** Mapea un nombre de host a una dirección IPv6.
    *   **CNAME:** Crea un alias de un nombre de host a otro (Canonical Name).
    *   **MX:** Especifica los servidores de correo para el dominio (Mail Exchange).
    *   **TXT:** Contiene texto arbitrario, usado para verificación de dominios, políticas de SPF, etc.
*   **Servidores de Nombres (Name Servers - NS):** Son los servidores que Cloud DNS asigna a tu zona pública para que el resto de Internet sepa dónde buscar los registros de tu dominio.

### Tipos de Zonas DNS

1.  **Zona Pública (Public Zone):**
    *   **Visibilidad:** Visible para toda la Internet pública.
    *   **Caso de Uso:** Alojar los registros DNS para tu sitio web público, APIs, servidores de correo, etc. (`www.mycompany.com`).
    *   **Proceso:** Creas la zona en Cloud DNS y luego actualizas los servidores de nombres (NS) en tu registrador de dominios (como GoDaddy, Namecheap, etc.) para que apunten a los de Google.

2.  **Zona Privada (Private Zone):**
    *   **Visibilidad:** Visible únicamente desde una o más redes VPC que tú autorices.
    *   **Caso de Uso:** Crear un DNS interno para tus máquinas virtuales y servicios dentro de GCP. Por ejemplo, puedes tener un registro `db.corp.internal` que resuelve a la IP interna de tu base de datos. Esto permite el descubrimiento de servicios sin exponerlos a Internet.

### Políticas de DNS y Reenvío

Cloud DNS permite configurar cómo se resuelven las consultas DNS desde tus VPCs para escenarios híbridos:

*   **Reenvío de Salida (Outbound Forwarding):**
    *   **Concepto:** Permite que las VMs de tu VPC resuelvan nombres de un servidor DNS on-premise.
    *   **Cómo funciona:** Creas una **política de reenvío** que envía las consultas para zonas específicas (ej. `*.onprem.corp`) a tus servidores DNS corporativos a través de una VPN o Interconnect.

*   **Reenvío de Entrada (Inbound Forwarding):**
    *   **Concepto:** Permite que tus servidores on-premise resuelvan nombres de tus zonas privadas de Cloud DNS.
    *   **Cómo funciona:** Creas una **política de servidor de entrada** que asigna una dirección IP interna en tu VPC. Tus servidores on-premise pueden enviar consultas a esta IP, y GCP las responderá.

*   **Peering de DNS (DNS Peering):**
    *   **Concepto:** Permite que una VPC (consumidora) resuelva registros de una zona privada de Cloud DNS que está alojada en otra VPC (productora).
    *   **Caso de Uso:** Arquitecturas de servicios compartidos donde una VPC central aloja el DNS para otras VPCs.

### DNSSEC (DNS Security Extensions)

*   **¿Qué es?** Es una funcionalidad para las **zonas públicas** que añade una capa de seguridad al DNS. Protege tu dominio contra ataques de suplantación (spoofing) y envenenamiento de caché (cache poisoning).
*   **¿Cómo funciona?** Firma criptográficamente tus registros DNS. Cuando un cliente resuelve un dominio, puede verificar la firma para asegurarse de que la respuesta es auténtica y no ha sido manipulada.
*   **En Cloud DNS:** Puedes habilitar y administrar DNSSEC con un solo clic o comando. Cloud DNS se encarga de la rotación de claves y la firma de la zona.

### 🧪 Laboratorio Práctico (CLI-TDD)

**Objetivo:** Crear una zona DNS privada para una VPC.

```bash
# Prerrequisito: Tener una VPC llamada 'vpc-a'

# 1. Crear una zona DNS privada
gcloud dns managed-zones create my-private-zone \
    --description="Mi zona privada" \
    --dns-name="corp.internal." \
    --visibility=private \
    --networks=vpc-a

# 2. Añadir un registro A a la zona
gcloud dns record-sets transaction start --zone=my-private-zone
gcloud dns record-sets transaction add "10.0.1.10" --name="db.corp.internal." --ttl=300 --type=A --zone=my-private-zone
gcloud dns record-sets transaction execute --zone=my-private-zone

# 3. Test (Verificación): Listar los registros de la zona
gcloud dns record-sets list --zone=my-private-zone
# Esperado: Debería aparecer el registro 'db.corp.internal.' con el tipo A y el valor '10.0.1.10'.
```

### 🧠 Lecciones Aprendidas

*   **El punto final es importante:** No olvides el punto (`.`) al final de los nombres de dominio completos (FQDN) en los comandos de DNS (ej. `corp.internal.`).
*   **Las zonas privadas simplifican la arquitectura:** Evitan tener que gestionar archivos `/etc/hosts` o sistemas de descubrimiento de servicios complejos para la comunicación interna.

### 💡 Tips de Examen

*   **Pública vs. Privada:** Si la pregunta implica resolución de nombres **dentro de una VPC** o para un entorno híbrido, la respuesta probablemente sea una **Zona Privada**. Si es para un sitio web accesible desde Internet, es una **Zona Pública**.
*   **Conectividad Híbrida:** Si se mencionan servidores **on-premise**, busca respuestas que incluyan **políticas de reenvío de DNS** (entrada o salida).
*   **DNSSEC:** Es para seguridad y autenticidad de **zonas públicas** únicamente.

### ✍️ Resumen

Cloud DNS es un servicio DNS gestionado, escalable y fundamental en GCP. Proporciona una solución fiable tanto para la resolución de nombres de dominio públicos en Internet como para el descubrimiento de servicios internos dentro de tus redes VPC. Con funcionalidades avanzadas como el reenvío para entornos híbridos y DNSSEC para la seguridad, Cloud DNS es una pieza clave en cualquier arquitectura de Google Cloud.

---

## ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)

---

[⬆️ **Volver arriba**](#-002-cloud-dns)
