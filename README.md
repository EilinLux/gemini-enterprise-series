# Building Enterprise Agents with Gemini — Part 5: Integration, Security & Intranet Portal (`05-integration-and-security`)

Welcome to the companion repository for the **Building Enterprise Agents with Gemini** Medium series (`DoubleClick Enterprise`).

Each branch in this repository corresponds to an article in our 5-part series and incrementally builds upon the previous branch:
* **`01-knowledge-base-management`**: Part 1 — Grounding with Unstructured (GCS) & Structured (BigQuery) Data Stores connected to a Gemini Enterprise App (`double-click-enterprise-app`).
* **`02-conversational-modeling`**: Part 2 — Integrating Conversational Agents (Dialogflow CX Playbooks), Code-First ADK Agents on Vertex AI Agent Engine, and Remote A2A Agent Cards.
* **`03-ux-ui-and-accessibility`**: Part 3 — Branding the Gemini Enterprise Web App & Widget (`google_discovery_engine_widget_config`) and configuring Feature Management governance.
* **`04-architecture-and-monitoring`**: Part 4 — OpenTelemetry tracing, BigQuery Agent Telemetry & Golden Evaluation sink (`double_click_agent_logs`), Cloud Monitoring Dashboard, and automated Golden Dataset Evaluator (`agents/evaluate_agent.py`).
* **`05-integration-and-security` (Current Branch)**: Part 5 — Securing OAuth 2.0 Action credentials in **Google Cloud Secret Manager**, least-privilege IAM, optional Discovery Engine ACL configuration (`terraform/security.tf`), and the **DoubleClick Enterprise Intranet Web Portal** (`webapp/`) embedding the live `<gen-search-widget>` alongside interactive **Workforce Identity ACL Pre-Filtering** and **Per-User OAuth 2.0 + Human-in-the-Loop (HITL) Jira Action** simulators.

---

## 📂 Service-Split Architecture (Parts 1–5)

All Terraform resources are cleanly split by Google Cloud service with `# 📌 Added since Article X:` annotations:

```text
gemini-enterprise-series/
├── .env.example                                  # Template for unified environment variables
├── README.md                                     # Full-series documentation & UI verification guide
├── data/
│   ├── structured/                               # Part 1: BigQuery JSONL datasets (project_db, retail_sales)
│   └── unstructured/                             # Part 1: Unstructured policy & contract documents
├── agents/
│   ├── adk_double_click_agent/                   # Part 2: Code-First ADK Agent + OpenTelemetry tracing
│   ├── a2a_agent_card/                           # Part 2: Remote A2A v0.3.0 Agent Card JSON
│   └── evaluate_agent.py                         # Part 4: Golden Dataset Evaluator & BigQuery JSONL exporter
├── webapp/                                       # 📌 Added since Article 5: DoubleClick Intranet Web Portal
│   ├── index.html                                # Embedded <gen-search-widget> + ACL & OAuth Simulator UI
│   ├── styles.css                                # Enterprise dark-mode design system
│   ├── app.js                                    # Workforce Identity ACL & Per-User OAuth 2.0 logic
│   └── serve_portal.py                           # Local HTTP server (http://localhost:8080)
├── scripts/
│   ├── setup_infra.sh                            # End-to-end provisioning & verification script
│   └── test_infra.sh                             # Pre-flight validation suite for Parts 1–5
└── terraform/
    ├── versions.tf                               # Terraform & Google Provider versions
    ├── variables.tf                              # Input variables across Parts 1–5
    ├── apis.tf                                   # Enables Discovery Engine, Dialogflow, Monitoring, Secret Manager
    ├── storage.tf                                # Article 1: GCS Bucket & unstructured policy documents
    ├── bigquery.tf                               # Article 1: BigQuery Dataset & tables
    ├── discovery_engine.tf                       # Articles 1–3: Data Stores + Gemini Enterprise App + Features
    ├── dialogflow_cx.tf                          # Article 2: Dialogflow CX Agent + Playbook + Agent Registration
    ├── vertex_agent_engine.tf                    # Article 2: ADK Agent Engine Service Account & IAM
    ├── widget_ui.tf                              # Article 3: Search Widget Config (configId)
    ├── observability.tf                          # Article 4: BigQuery Telemetry Sink & Cloud Monitoring Dashboard
    ├── security.tf                               # 📌 Added since Article 5: Secret Manager OAuth Vault & ACL Config
    └── outputs.tf                                # Outputs across all 5 articles
```

---

## 🚀 Prerequisites & Authentication

Before running any scripts or Terraform commands, ensure you have:
1. **Google Cloud SDK (`gcloud`)** and **Terraform (`>= 1.5`)** installed.
2. **Python 3.10+** installed.
3. **Authenticated your local environment with Google Cloud** (both user CLI credentials and Application Default Credentials for Terraform and Python SDKs):

```bash
gcloud auth login
gcloud auth application-default login
```

---

## ⚙️ Quickstart: Configure, Test, Deploy & Launch the Intranet Portal

### 1. Configure `.env`
Copy `.env.example` to `.env` and set your `PROJECT_ID`:

```bash
cp .env.example .env
```

### 2. Run Pre-Flight Validation (`test_infra.sh`)
Validates Terraform syntax, Python syntax, the Part 4 Golden Evaluation pipeline (3/3 test cases), and the Part 5 Web Portal assets:

```bash
./scripts/test_infra.sh
```

### 3. Deploy the Complete 5-Part Stack (`setup_infra.sh`)
Applies the Terraform stack across Parts 1–5, populates the BigQuery observability dataset with Golden Evaluation metrics, and verifies your Secret Manager OAuth vault:

```bash
./scripts/setup_infra.sh
```

### 4. Launch the DoubleClick Enterprise Intranet Web Portal (`serve_portal.py`)
Start the local portal server to interact with the live `<gen-search-widget>` and test Workforce Identity Document-Level ACL pre-filtering and Per-User OAuth 2.0 Jira Actions:

```bash
python3 webapp/serve_portal.py
```
Then open **`http://localhost:8080`** in your browser!

---

## 🖥️ Verifying Provisioned Resources in the Google Cloud Console UI

After running `./scripts/setup_infra.sh`, you can verify every layer of the 5-part architecture directly in the Google Cloud Console:

### Part 1: Knowledge Base & Data Stores
1. Go to **[Gemini Enterprise -> Data Stores](https://console.cloud.google.com/gen-app-builder/data-stores)**.
2. Verify **`double-click-unstructured-ds`** (Cloud Storage documents) and **`double-click-structured-bq-ds`** (BigQuery `double_click_kb` tables) are **Active** and connected to **`double-click-enterprise-app`**.

### Part 2: Conversational Modeling & Connected Agents
1. Go to **[Gemini Enterprise -> Apps](https://console.cloud.google.com/gen-app-builder/engines)** and click **`double-click-enterprise-app`**.
2. Open the **Agents** tab in the left navigation menu to verify the connected **Dialogflow CX Concierge Agent** (`DoubleClick Enterprise — Dialogflow CX Concierge`) and **Remote A2A Supply Chain Agent** (`DoubleClick Enterprise — Remote Supply Chain A2A Agent`).
3. Visit **[Dialogflow CX Console](https://conversational-agents.cloud.google.com/)** to inspect the `DoubleClick Enterprise Concierge` Playbook.

### Part 3: UX/UI Branding, Feature Management & Widget Config
1. Inside **`double-click-enterprise-app`**, click **Feature management** to verify the enterprise governance toggles (`agent-gallery`, `prompt-gallery`, `model-selector`, `notebook-lm`, `people-search`, `feedback`, etc.).
2. Click **Integration** in the left menu to view the **Widget** configuration (`configId = "9b9cd0cf-78eb-4495-b8ee-f1d6effec88b"`) and JWT/Public access settings.

### Part 4: Architecture, Observability & Evaluation
1. Go to **[Cloud Monitoring -> Dashboards](https://console.cloud.google.com/monitoring/dashboards)** and open **`DoubleClick Enterprise — Gemini Agent Observability (Part 4)`**.
2. Go to **[BigQuery Studio](https://console.cloud.google.com/bigquery)** and inspect dataset **`double_click_agent_logs`** -> table **`agent_telemetry_and_eval_logs`** to query your Golden Dataset evaluation scores (`trajectory_exact_match`, `groundedness_score`, `latency_ms`) and agent telemetry records.

### Part 5: Integration, Secret Manager OAuth Vault & Workforce Identity ACLs
1. **Secret Manager OAuth Vault:**
   * Go to **[Security -> Secret Manager](https://console.cloud.google.com/security/secret-manager)**.
   * Verify **`double-click-jira-action-oauth-secret`** exists with label `article: part-5-integration-and-security`.
   * Click the secret -> **Permissions** tab to confirm `double-click-adk-sa@<YOUR_PROJECT_ID>.iam.gserviceaccount.com` has the **Secret Manager Secret Accessor** (`roles/secretmanager.secretAccessor`) role.
2. **Gemini Enterprise Actions Tab:**
   * Go to **[Gemini Enterprise -> Apps](https://console.cloud.google.com/gen-app-builder/engines)** -> **`double-click-enterprise-app`** -> **Actions**.
   * Click **Add Action** to connect Jira, ServiceNow, Salesforce, Google Workspace, or custom OpenAPI/MCP tools using your OAuth 2.0 Client ID and the Client Secret stored in `double-click-jira-action-oauth-secret`.
3. **Workforce Identity & Document ACLs:**
   * In the left navigation menu of **Gemini Enterprise**, click **Settings** (or **Authentication**) to inspect identity provider integration (Google Identity or Workforce Identity Federation via SAML 2.0 / OIDC).
