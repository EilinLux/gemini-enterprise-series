# 🚀 Building Enterprise Agents with Gemini — The “Double-Click” Enterprise Series

Welcome to the official companion repository for the **Building Enterprise Agents with Gemini** Medium series!

This repository follows an **incremental branch-per-article architecture**: each branch corresponds to one part of the 5-part series and builds directly on top of the previous branch, driven by a **single unified `.env` configuration file** at the root of the project.

---

## 🏢 The Business Scenario: Why “DoubleClick Enterprise” Needs Gemini Enterprise

### Why the Name “Double-Click”?
In corporate and consulting slang, to **“double-click”** on a topic means to *drill down, inspect the underlying details, and look beneath the surface*. 

Throughout this series, you step into the role of **Lead AI Architect at DoubleClick Enterprise**—a fast-growing omni-channel retail and B2B technology company with offices in Milan, London, and New York. We named our internal AI assistant **“Double-click”** because its mission is to let any employee—from a Business Analyst to an Account Executive or Site Reliability Engineer—*double-click* into the company’s scattered knowledge and get verified, actionable answers in seconds.

### The Problem: A Classic Case of Enterprise “Data Silos”
Like most real-world organizations, DoubleClick Enterprise doesn't suffer from a lack of data—it suffers from **fragmentation**. Before adopting Gemini Enterprise, employees wasted hours every day hunting across three disconnected data ecosystems:

1. **Unstructured Documents & Archives (Google Cloud Storage / Drive / SharePoint):**
   * **HR & People Policies (`WFH_Policy_Update_V2.txt`):** Employees constantly message HR asking about hybrid work core hours or how to claim the €750 ergonomic home office stipend.
   * **Legal & Client Contracts (`Acme_Corp_Master_Services_Agreement_2026.txt`):** Account Executives preparing for renewal calls have to manually dig through hundreds of PDF Master Services Agreements to check termination clauses, volume discounts, and SLA penalty notes (such as a 14-day delay on *Project Alpha* caused by hardware vendor *CloudNet Hardware Ltd.*).
   * **IT & Security Runbooks (`IT_Security_Onboarding_Playbook.txt`):** Engineers on call need instant answers on Private Service Connect (PSC) routing rules and P1 incident escalation paths.
2. **Structured Operational & Retail Warehouses (BigQuery):**
   * **Project Portfolio Tracking (`double_click_kb.project_db`):** Leadership needs real-time visibility into internal project statuses (`Double-click` is `ACTIVE`, `Phoenix` is `ON_HOLD` pending firewall sign-off, `Alpha` is `DELAYED`), budgets, and owners without writing SQL queries.
   * **Omni-Channel Retail Analytics (`double_click_kb.retail_sales`):** Business analysts need to correlate sales performance across Point-of-Sale (`pos_sales_table`), e-commerce (`website_sales_table`), and mobile (`mobile_app_sales_table`).
3. **Live Third-Party SaaS Tools (Jira / ServiceNow / Confluence / Salesforce):**
   * **Real-Time Ticketing & CRM:** Support tickets, sprint blockers, and customer opportunities change minute-by-minute. Because of strict compliance and data-residency rules, some of these third-party records cannot be copied into a separate storage bucket—they must be queried live via **Federation**, and updated via **Per-User OAuth 2.0 Actions**.

### Why Gemini Enterprise?
A standalone LLM chatbot cannot solve this problem—it doesn't know DoubleClick's internal policies, it can't run federated joins across BigQuery and GCS, and it doesn't respect document-level Access Control Lists (ACLs).

DoubleClick Enterprise chose **Gemini Enterprise** (and the **Vertex AI Agent Builder** ecosystem) to build a unified, production-grade AI platform across 5 architectural pillars:
* **Part 1 (Knowledge Base):** Combine **Ingestion (Graph RAG)** over GCS & BigQuery—so the Private Knowledge Graph automatically links *Project Alpha's* delay in BigQuery to the *CloudNet Hardware* supplier issue hidden in the Acme Corp PDF—with **Federation** for live zero-copy queries into Jira.
* **Part 2 (Conversational Modeling):** Blend deterministic compliance flows (**Dialogflow CX / Conversational Agents**) with autonomous multi-step Python agents (**ADK on Vertex AI Agent Engine**) and remote **A2A** agents.
* **Part 3 (UX/UI & Accessibility):** Deliver a white-labeled, accessible assistant with DoubleClick's custom logo, pinned shortcuts, and granular **Feature Management** governance.
* **Part 4 (Architecture & Monitoring):** Give leadership Looker-powered **Adoption & Quality Analytics**, while giving SREs deep **OpenTelemetry (`Cloud Trace`)** waterfall debugging and continuous **BigQuery / GenAI Evaluations**.
* **Part 5 (Integration & Security):** Enforce strict **Workforce Identity Federation**, **Document-Level ACLs**, and **Per-User OAuth 2.0 Actions** so the agent can create Jira tickets or update Salesforce strictly under the logged-in employee's permissions.

---

## 📚 Series Table of Contents & Git Branch Map

| Branch | Main Medium Article (Concepts & Console UI) | Companion EXTRA Article (Code & Terraform Deep-Dive) | What Gets Added in This Branch |
| :--- | :--- | :--- | :--- |
| **`01-knowledge-base-management`** *(Current)* | **[Part 1 — 📚 Knowledge Base Management](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-1-knowledge-base-management.md)** | **[Part 1 EXTRA — Code & Terraform Setup](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-1-extra-code-and-terraform-setup.md)** | • **DoubleClick Enterprise** messy data scenario (`data/unstructured/` & `data/structured/`)<br>• Terraform for **Ingestion Data Stores** (GCS Graph RAG + BigQuery) & **Federated Connector** (`google_discovery_engine_data_connector`)<br>• Automated `.env`-driven `./scripts/setup_infra.sh` & `./scripts/test_infra.sh` |
| **`02-conversational-modeling`** | **Part 2 — 🗣️ Conversational Modeling** *(Checkout branch `02-conversational-modeling`)* | **Part 2 EXTRA — Agent Code & Terraform Setup** *(Checkout branch `02-conversational-modeling`)* | • **Conversational Agent (Dialogflow CX)** + Generative Playbook in Terraform (`google_dialogflow_cx_agent`, `google_dialogflow_cx_playbook`)<br>• **ADK Python Agent** (`agents/adk_double_click_agent/`) + **A2A JSON Agent Card**<br>• Discovery Engine Chat/Search Engine bindings |
| **`03-ux-ui-and-accessibility`** | **Part 3 — 🎨 UX/UI & Accessibility** *(Checkout branch `03-ux-ui-and-accessibility`)* | **Part 3 EXTRA — UI & Widget Terraform Setup** *(Checkout branch `03-ux-ui-and-accessibility`)* | • **Gemini Enterprise App** (`google_discovery_engine_search_engine`)<br>• **Widget & Branding Config** (`google_discovery_engine_widget_config`)<br>• REST API automation for Search UI, Logo, Pinned Shortcuts & Feature Management |
| **`04-architecture-and-monitoring`** | **Part 4 — 📈 Architecture & Monitoring** *(Checkout branch `04-architecture-and-monitoring`)* | **Part 4 EXTRA — Observability & Eval Setup** *(Checkout branch `04-architecture-and-monitoring`)* | • **OpenTelemetry Tracing** (`Cloud Trace`) & IAM bindings<br>• **Cloud Logging $\rightarrow$ BigQuery Sink** (`google_logging_project_sink`)<br>• **Cloud Monitoring Custom Dashboard** (`google_monitoring_dashboard`) & GenAI Evaluation script |
| **`05-integration-and-security`** | **Part 5 — 🛡️ Integration & Security** *(Checkout branch `05-integration-and-security`)* | **Part 5 EXTRA — Security, OAuth & Mock Web Portal** *(Checkout branch `05-integration-and-security`)* | • **Per-User OAuth 2.0 Actions**, **Secret Manager** (`google_secret_manager_secret`), **ACL Config** (`google_discovery_engine_acl_config`), & **CMEK/WIF**<br>• **Interactive Mocked Enterprise Intranet Web App (`webapp/`)** embedding the branded Gemini Enterprise Widget & OAuth Action consent simulator |

---

## ⚠️ Prerequisites & Gemini Enterprise Licensing

1. **Google Cloud Project** with billing enabled.
2. **Gemini Enterprise License (or 180-Day Free Trial):**
   * In the Google Cloud Console, navigate to **Gemini Enterprise > Manage subscriptions** and activate **Gemini Enterprise Standard** or **Gemini Enterprise Plus** (or start the free trial).
   * Ensure your user has `roles/discoveryengine.agentspaceAdmin` and `roles/owner` (or `roles/editor`).
3. **Local Tools:**
   * `gcloud` CLI (authenticated via `gcloud auth login` and `gcloud auth application-default login`)
   * `terraform` (`>= 1.5.0`)
   * `python3` (`>= 3.10`) and `bq` (BigQuery CLI)

---

## 🛠️ How to Set Up the Infrastructure (Branch `01-knowledge-base-management`)

All infrastructure across every branch is controlled by a **single `.env` file** in the root directory (which is git-ignored so your private project ID is never committed).

### Step 0: Authenticate with Google Cloud
Before running the setup script, authenticate both your `gcloud` CLI session and your Terraform Application Default Credentials (ADC):
```bash
gcloud auth login
gcloud auth application-default login
```

### Step 1: Configure `.env`
```bash
cp .env.example .env
```
Open `.env` and set your `PROJECT_ID`:
```ini
PROJECT_ID="your-gcp-project-id"
REGION="europe-west1"
DISCOVERY_ENGINE_LOCATION="global"
APP_NAME="double-click"
COMPANY_NAME="DoubleClick Enterprise"
```

### Step 2: Provision the Infrastructure & Ingest Sample Data
Run the automated setup script in the `scripts/` folder:
```bash
./scripts/setup_infra.sh
```
**What `./scripts/setup_infra.sh` does on Branch 01:**
1. Reads `.env` and exports `TF_VAR_*` variables.
2. Runs `terraform init` and `terraform apply` inside `terraform/` to create:
   * The GCS bucket (`gs://<YOUR_PROJECT_ID>-double-click-docs-staging` in `europe-west1`) and uploads our 3 unstructured DoubleClick Enterprise documents (`WFH_Policy_Update_V2.txt`, `Acme_Corp_Master_Services_Agreement_2026.txt`, `IT_Security_Onboarding_Playbook.txt`).
   * The BigQuery dataset (`double_click_kb` in `europe-west1`) and structured tables (`project_db` and `retail_sales`).
   * The **Unstructured Ingested Data Store** (`double-click-unstructured-ds`) with 500-token layout-based chunking.
   * The **Structured BigQuery Data Store** (`double-click-structured-bq-ds`).
   * The **Gemini Enterprise App** (`double-click-enterprise-app`, `app_type = "APP_TYPE_INTRANET"`) with **Private Knowledge Graph** enabled and **both Data Stores automatically connected** via `data_store_ids`!
   * *(Optional)* The **Federated Third-Party SaaS Connector** (`google_discovery_engine_data_connector`) when `ENABLE_FEDERATED_CONNECTOR="true"`.
3. Seeds `project_db` and `retail_sales` in BigQuery using `data/structured/*.jsonl`.
4. Triggers the Discovery Engine `documents:import` REST API to index the GCS files and BigQuery rows.

---

## 🖥️ How to Verify the Provisioned Resources in the Google Cloud Console UI

After running `./scripts/setup_infra.sh`, you can verify that every Part 1 resource exists, is populated, and is **connected to the Gemini Enterprise App** directly from the Google Cloud Console UI:

1. **Verify the Unstructured Documents in Cloud Storage:**
   * Open the [Google Cloud Console — Cloud Storage Buckets](https://console.cloud.google.com/storage/browser).
   * Click on the bucket named **`<YOUR_PROJECT_ID>-double-click-docs-staging`**.
   * Open the `unstructured/` folder and verify that `WFH_Policy_Update_V2.txt`, `Acme_Corp_Master_Services_Agreement_2026.txt`, and `IT_Security_Onboarding_Playbook.txt` are present.
2. **Verify the Structured Tables & Rows in BigQuery:**
   * Open [Google Cloud Console — BigQuery Studio](https://console.cloud.google.com/bigquery).
   * In the left **Explorer** pane, expand your project and click on the **`double_click_kb`** dataset.
   * Click on the **`project_db`** and **`retail_sales`** tables, then switch to the **Preview** tab to confirm the rows (`Double-click`, `Phoenix`, `Alpha`, and retail channel transactions) are loaded.
3. **Verify the Gemini Enterprise App & Connected Data Stores in the Console:**
   * In the top search bar of the Cloud Console, search for **“Gemini Enterprise”** (or **“AI Applications”**) and click on **Apps**.
   * Verify that **`DoubleClick Enterprise - Gemini Enterprise App`** (`double-click-enterprise-app`) is listed. Click on it and open **Connected data stores** (or **Data**) in the left menu to confirm that both **`double-click-unstructured-ds`** and **`double-click-structured-bq-ds`** are attached!
   * Next, click on **Data Stores** in the main left-hand navigation (with **Location** set to **`global`**):
     * **`DoubleClick Enterprise - Unstructured Docs (Ingested Graph RAG)`** (`double-click-unstructured-ds`): Verify that **Connected apps** shows `DoubleClick Enterprise - Gemini Enterprise App`, and check the **Data** and **Activity** tabs to verify that the 3 GCS documents have been parsed and chunked.
     * **`DoubleClick Enterprise - Structured BigQuery Data Store`** (`double-click-structured-bq-ds`): Verify that **Connected apps** shows `DoubleClick Enterprise - Gemini Enterprise App`, and inspect the **Schema** and **Activity** tabs to verify the BigQuery `project_db` import status.
   * *(If `ENABLE_FEDERATED_CONNECTOR="true"`)* Check the **Connected data stores / Connectors** list to see the **`DoubleClick Enterprise - Federated JIRA Connector`** collection.

---

## 🧪 How to Test the Repository

You can validate the entire repository (environment variables, JSONL schemas, Bash scripts, and Terraform `validate`) by running:

```bash
./scripts/test_infra.sh
```

Or run the setup script in dry-run validation mode:
```bash
./scripts/setup_infra.sh --dry-run
```

---

## ⏭️ Next Step
Once you have explored Part 1, switch to the next branch to add **Conversational Modeling (Dialogflow CX, ADK Agent Engine, and A2A)**:
```bash
git checkout 02-conversational-modeling
```
