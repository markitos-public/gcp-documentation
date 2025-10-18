# 🛣️ Markitos' GCP DevOps Learning Path

Este repositorio contiene una ruta de aprendizaje personal y una colección de notas de estudio sobre Google Cloud Platform, con un enfoque en DevOps, DevSecOps y SRE. El objetivo es crear un cuaderno de estudio público, detallado y práctico.

---

## 📚 Índice General

### Módulo 1: Fundamentos de GCP (GCP Fundamentals)

*   **Conceptos Core**
    *   [001: La Computación en la Nube](./01-gcp-fundamentals/01-core-concepts/001-la-computacion-en-la-nube.md)
    *   [002: Modelos de Servicio en la Nube](./01-gcp-fundamentals/01-core-concepts/002-modelos-de-servicio-en-la-nube.md)
*   **Infraestructura Core**
    *   **Infraestructura Global**
        *   [001: Regiones y Zonas](./01-gcp-fundamentals/02-core-infrastructure/01-global-infrastructure/001-regions-and-zones.md)
    *   **Jerarquía de Recursos**
        *   [001: Visión General de la Jerarquía de Recursos](./01-gcp-fundamentals/02-core-infrastructure/02-resource-hierarchy/001-resource-hierarchy-overview.md)
*   **IAM (Identity and Access Management)**
    *   [001: Visión General de IAM](./01-gcp-fundamentals/03-iam/001-iam-overview.md)
    *   [002: Roles de IAM](./01-gcp-fundamentals/03-iam/002-iam-roles.md)
    *   [003: Cuentas de Servicio de IAM](./01-gcp-fundamentals/03-iam/003-iam-service-accounts.md)
    *   [004: Roles Personalizados de IAM](./01-gcp-fundamentals/03-iam/004-iam-custom-roles.md)
    *   [005: Condiciones de IAM](./01-gcp-fundamentals/03-iam/005-iam-conditions.md)
    *   [006: Políticas de Denegación de IAM](./01-gcp-fundamentals/03-iam/006-iam-deny-policies.md)
    *   [007: Mejores Prácticas de IAM](./01-gcp-fundamentals/03-iam/007-iam-best-practices.md)
    *   [008: Políticas de Organización (Organization Policies)](./01-gcp-fundamentals/03-iam/008-organization-policies.md)
*   **Redes VPC**
    *   [001: Visión General de VPC](./01-gcp-fundamentals/04-vpc-networking/001-vpc-overview.md)
    *   [002: Subredes y Rangos de IP](./01-gcp-fundamentals/04-vpc-networking/002-subnets-and-ip-ranges.md)
    *   [003: Reglas de Firewall](./01-gcp-fundamentals/04-vpc-networking/003-firewall-rules.md)
    *   [004: Peering de VPC y VPC Compartida](./01-gcp-fundamentals/04-vpc-networking/004-vpc-peering-and-shared-vpc.md)
*   **Facturación y Gestión de Costos**
    *   [001: Visión General de Facturación y Costos](./01-gcp-fundamentals/05-billing-and-cost-management/001-billing-and-cost-management-overview.md)

### Módulo 2: Desarrollo Nativo en la Nube (Cloud-Native Development)

*   **Plataformas de Cómputo**
    *   [001: Visión General de Plataformas de Cómputo](./02-cloud-native-development/01-compute-platforms/001-compute-platforms-overview.md)
    *   [002: Compute Engine](./02-cloud-native-development/01-compute-platforms/002-compute-engine.md)
    *   [003: Google Kubernetes Engine (GKE)](./02-cloud-native-development/01-compute-platforms/003-gke.md)
    *   [004: Cloud Run](./02-cloud-native-development/01-compute-platforms/004-cloud-run.md)
    *   [005: Cloud Functions](./02-cloud-native-development/01-compute-platforms/005-cloud-functions.md)
    *   [006: App Engine](./02-cloud-native-development/01-compute-platforms/006-app-engine.md)
*   **Herramientas de Desarrollo**
    *   [001: Cloud Code](./02-cloud-native-development/02-development-tools/001-cloud-code.md)
    *   [002: Cloud Source Repositories](./02-cloud-native-development/02-development-tools/002-cloud-source-repositories.md)
    *   [003: Cloud Shell](./02-cloud-native-development/02-development-tools/003-cloud-shell.md)
*   **Contenerización**
    *   [001: Visión General de Contenedores](./02-cloud-native-development/03-containerization/001-containers-overview.md)
    *   [002: Google Kubernetes Engine (GKE)](./02-cloud-native-development/03-containerization/002-google-kubernetes-engine-gke.md)
    *   [003: Artifact Registry](./02-cloud-native-development/03-containerization/003-artifact-registry.md)

### Módulo 3: Cultura y Principios SRE (SRE Culture and Principles)

*   **Conceptos SRE**
    *   [001: SLO, SLI, SLA](./03-sre-culture-and-principles/01-sre-concepts/001-slo-sli-sla.md)
    *   [002: Toil y Presupuestos de Error](./03-sre-culture-and-principles/01-sre-concepts/002-toil-and-error-budgets.md)
*   **Prácticas SRE**
    *   [001: Monitorización y Alertas](./03-sre-culture-and-principles/02-sre-practices/001-monitoring-and-alerting.md)
    *   [002: Gestión de Incidentes y Post-mortems](./03-sre-culture-and-principles/02-sre-practices/002-incident-management-and-postmortems.md)

### Módulo 4: CI/CD y Automatización (CI/CD and Automation)

*   **Conceptos de Automatización**
    *   [001: Infraestructura como Código (IaC)](./04-ci-cd-and-automation/01-automation-concepts/001-iac.md)
    *   [002: Terraform en GCP](./04-ci-cd-and-automation/01-automation-concepts/002-terraform-on-gcp.md)
*   **Herramientas de CI/CD**
    *   [001: Cloud Build](./04-ci-cd-and-automation/02-ci-cd-tools/001-cloud-build.md)
    *   [002: Cloud Deployment Manager](./04-ci-cd-and-automation/02-ci-cd-tools/002-cloud-deployment-manager.md)

### Módulo 5: Observabilidad y Operaciones (Observability and Operations)

*   **Pilares de la Observabilidad**
    *   [001: Cloud Monitoring](./05-observability-and-operations/01-observability-pillars/001-cloud-monitoring.md)
    *   [002: Cloud Logging](./05-observability-and-operations/01-observability-pillars/002-cloud-logging.md)
    *   [003: Cloud Trace](./05-observability-and-operations/01-observability-pillars/003-cloud-trace.md)
    *   [004: Cloud Profiler](./05-observability-and-operations/01-observability-pillars/004-cloud-profiler.md)
*   **Depuración y Perfilado**
    *   [001: Cloud Debugger](./05-observability-and-operations/02-debugging-and-profiling/001-cloud-debugger.md)

### Módulo 6: Seguridad y Cumplimiento (Security and Compliance)

*   **Seguridad del Pipeline**
    *   [001: Binary Authorization](./06-security-and-compliance/01-pipeline-security/001-binary-authorization.md)
    *   [002: Artifact Analysis](./06-security-and-compliance/01-pipeline-security/002-artifact-analysis.md)
*   **Seguridad de la Infraestructura**
    *   [001: Security Command Center](./06-security-and-compliance/02-infrastructure-security/001-security-command-center.md)
    *   [002: Cloud Key Management Service (KMS)](./06-security-and-compliance/02-infrastructure-security/002-cloud-key-management-service.md)
    *   [003: Secret Manager](./06-security-and-compliance/02-infrastructure-security/003-secret-manager.md)

### Módulo 7: Casos Prácticos

*   [001: Troubleshooting de Fallo de Comunicación en MIG](./07-casos-practicos/001-troubleshooting-mig-fallo-comunicacion.md)
*   [002: Implementando un Pipeline de CI/CD Seguro](./07-casos-practicos/002-implementando-un-pipeline-cicd-seguro.md)
*   [003: Troubleshooting de Binary Authorization](./07-casos-practicos/003-troubleshooting-binary-authorization.md)
*   [004: Respuesta a Hallazgo de API Key Expuesta en SCC](./07-casos-practicos/004-responding-to-scc-finding.md)
*   [005: Pipeline Automatizado de Rotación de Secretos](./07-casos-practicos/005-implementing-secret-rotation-pipeline.md)
*   [006: RCA de Lentitud en App con el Stack de Observabilidad](./07-casos-practicos/006-rca-observability-stack.md)
*   [007: Debugging de Aplicaciones en GKE](./07-casos-practicos/007-debugging-gke-apps.md)
*   [008: Debugging de Aplicaciones en Cloud Run](./07-casos-practicos/008-debugging-cloud-run-apps.md)
*   [009: Red Avanzada en Cloud Run (Dominio e IP Estática)](./07-casos-practicos/009-cloud-run-advanced-networking.md)

---

### ✍️ Firma

**Marco - DevSecOps Kulture**  
*The Artisan Path*  
📧 Contacto: [markitos.es.info@gmail.com](mailto:markitos.es.info@gmail.com)  
🐙 GitHub: [https://github.com/markitos-public](https://github.com/markitos-public)
