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
| **`05-integration-and-security`** | **Part 5 — 🛡️ Integration & Security** *(Checkout branch `05-integration-and-security`)* | **Part 5 EXTRA — Security, OAuth & Mock Web Portal** *(Checkout branch `05-integration-and-security`)* | • **Per-User OAuth 2.0 Actions**, **Secret Manager** (`google_secret_manager_secret`), **ACL Config** (`google_discovery_engine_acl_config`), & **CMEK/WIF**<br>• **Interactive Mocked Enterprise Intranet Web App (`webapp/`)** embedding the branded Gemini Enterprise Widget & OAuth Action consent simulator |

---

## ⚠️ Prerequisites & Google Cloud Account Setup

Before provisioning the infrastructure for **Part 1 (Knowledge Base Management)**, ensure your local environment and Google Cloud project meet these requirements:

### 1. Required IAM Roles
Your GCP user or service account must have the following IAM roles on the target project:
* **`roles/editor`** (or `roles/owner`): Required to manage cloud resources and enable APIs.
* **`roles/discoveryengine.editor`** (or `roles/discoveryengine.admin`): Required to create Data Stores, collections, and Gemini Enterprise Apps.
* **`roles/storage.admin`**: Required to create GCS staging buckets and upload unstructured documents.
* **`roles/bigquery.admin`**: Required to create BigQuery datasets and load structured JSONL tables.

### 2. Local Tools
Ensure you have the following CLI utilities installed:
* **`gcloud` CLI** (`>= 480.0.0`)
* **`terraform`** (`>= 1.5.0`)
* **`python3`** (`>= 3.10`)
* **`bq`** (Google Cloud BigQuery CLI, bundled with `gcloud`)
* **`curl`**

---

## 🛠️ Step-by-Step Setup Guide (Branch `01-knowledge-base-management`)

All infrastructure and scripts are driven by a **single `.env` configuration file** at the root of the project.

### Step 1: Authenticate `gcloud` and Application Default Credentials (ADC)
Terraform and the setup scripts communicate with Google Cloud APIs using Application Default Credentials (ADC). Authenticate both your CLI and ADC:

```bash
# 1. Log in to gcloud and update Application Default Credentials (ADC) in one step:
gcloud auth login your-email@example.com --update-adc

# (Alternatively, you can run them separately):
# gcloud auth login your-email@example.com
# gcloud auth application-default login
```

### Step 2: Set the Active Project and ADC Quota Project
To prevent quota and permission errors when Terraform calls Google Cloud APIs, configure both your active CLI project and your ADC quota project:

```bash
# Set your active gcloud project:
gcloud config set project <YOUR_PROJECT_ID>

# Crucial for Terraform & Google client libraries: set the ADC quota project
gcloud auth application-default set-quota-project <YOUR_PROJECT_ID>
```

> [!IMPORTANT]
> **Terms of Service (ToS) Precondition in New Projects / Sandboxes:**
> If you are using a newly created Google Cloud project or a lab sandbox (such as `gcplab.me`), calling APIs or Terraform directly may return:
> `FAILED_PRECONDITION: The terms of service 'cloud' for service(s) 'discoveryengine.googleapis.com' must be accepted.`
> 
> **How to resolve:**
> 1. Open the [Google Cloud Console](https://console.cloud.google.com/?project=YOUR_PROJECT_ID) in your browser while logged in as your GCP user.
> 2. Accept the Terms of Service banner (*"I agree to the Google Cloud Platform Terms of Service"* $\rightarrow$ Click **Agree and Continue**).
> 3. Visit the [Vertex AI Search / Discovery Engine Console](https://console.cloud.google.com/gen-app-builder/data-stores?project=YOUR_PROJECT_ID) to ensure the service is activated.

### Step 3: Configure the Unified `.env` File
Create your local `.env` from the provided example template:

```bash
cp .env.example .env
```

Open `.env` in your editor and configure your project parameters:

```ini
# ============================================================================
# Gemini Enterprise Series — Part 1 Configuration (.env)
# ============================================================================

# Core Google Cloud Settings
PROJECT_ID="your-gcp-project-id"        # Replace with your actual GCP Project ID
REGION="europe-west1"                   # Region for GCS bucket and BigQuery dataset
DISCOVERY_ENGINE_LOCATION="global"      # Location for Discovery Engine Data Stores (global)

# DoubleClick Enterprise Branding & App Naming
APP_NAME="double-click"
COMPANY_NAME="DoubleClick Enterprise"

# Part 1: Knowledge Base Management (Ingestion + Federation)
BQ_DATASET_ID="double_click_kb"
GCS_BUCKET_SUFFIX="docs-staging"
FEDERATED_CONNECTOR_SOURCE="jira"
ENABLE_FEDERATED_CONNECTOR="false"      # Keep "false" for initial setup; set "true" once Jira credentials exist
```

### Step 4: Validate the Code & Schemas (Unit Tests & Dry-Run)
Before creating any cloud resources, run the verification test suite:

```bash
# 1. Run unit tests, schema checks, and Terraform syntax validation:
./scripts/test_infra.sh

# 2. Run a Terraform dry-run plan:
./scripts/setup_infra.sh --dry-run
```

### Step 5: Provision Infrastructure and Seed Sample Data
Execute the automated provisioning script:

```bash
./scripts/setup_infra.sh
```

#### What `./scripts/setup_infra.sh` executes under the hood:
1. **Reads `.env`** and exports matching `TF_VAR_*` variables to Terraform.
2. **Enables Cloud APIs (`apis.tf`):**
   * `discoveryengine.googleapis.com` (Gemini Enterprise / Vertex AI Search)
   * `bigquery.googleapis.com` (BigQuery Structured Data Warehouse)
   * `storage.googleapis.com` (Cloud Storage Document Archive)
3. **Provisions Storage & Uploads Unstructured Docs (`storage.tf`):**
   * Creates GCS bucket `gs://<PROJECT_ID>-double-click-docs-staging` in `europe-west1`.
   * Uploads our 3 DoubleClick enterprise documents:
     * `unstructured/WFH_Policy_Update_V2.txt` (Hybrid work core hours, home office stipend)
     * `unstructured/Acme_Corp_Master_Services_Agreement_2026.txt` (Client legal contract, SLA penalty notes, vendor CloudNet Hardware)
     * `unstructured/IT_Security_Onboarding_Playbook.txt` (PSC routing rules, P1 incident escalation)
4. **Provisions BigQuery Dataset & Tables (`bigquery.tf`):**
   * Creates dataset `double_click_kb` in `europe-west1`.
   * Provisions schemas for `project_db` (internal project tracking) and `retail_sales` (omni-channel retail revenue).
5. **Creates Discovery Engine Data Stores & App (`discovery_engine.tf`):**
   * **Unstructured Data Store** (`double-click-unstructured-ds`): Configured with layout-based chunking (`chunk_size = 500`) and ancestor headings for Graph RAG.
   * **Structured BigQuery Data Store** (`double-click-structured-bq-ds`): Points to the BigQuery dataset.
   * **Gemini Enterprise App** (`double-click-enterprise-app`): Intranet App (`APP_TYPE_INTRANET`) with Private Knowledge Graph enabled, automatically binding both Data Stores!
   * *(Optional)* Federated Data Connector (`google_discovery_engine_data_connector`) when `ENABLE_FEDERATED_CONNECTOR="true"`.
6. **Populates BigQuery Structured Data:**
   * Loads `data/structured/project_db.jsonl` into `double_click_kb.project_db`.
   * Loads `data/structured/retail_sales.jsonl` into `double_click_kb.retail_sales`.
7. **Triggers Document Ingestion:**
   * Calls Discovery Engine `documents:import` REST API to index unstructured GCS documents.
   * Calls Discovery Engine `documents:import` REST API to index structured BigQuery rows.

---

## 🔎 Automated Live Cloud Verification

You can verify all live provisioned resources on Google Cloud in one command:

```bash
./scripts/verify_live_infra.sh
```

This script automatically verifies:
1. GCS bucket existence and presence of the 3 unstructured documents (`WFH_Policy_Update_V2.txt`, `Acme_Corp_Master_Services_Agreement_2026.txt`, `IT_Security_Onboarding_Playbook.txt`).
2. BigQuery dataset and validates table row counts (`project_db` and `retail_sales`).
3. Discovery Engine Unstructured and Structured Data Stores via REST API.
4. Gemini Enterprise App and confirms both Data Stores are connected.

---

## 🖥️ How to Verify the Provisioned Resources in Google Cloud Console

Once `./scripts/setup_infra.sh` completes, you can also inspect every component directly in the Google Cloud Console UI:

### 1. Cloud Storage (Unstructured Documents)
* Open [Cloud Storage Buckets](https://console.cloud.google.com/storage/browser).
* Click on **`<PROJECT_ID>-double-click-docs-staging`**.
* Open the `unstructured/` folder and verify that:
  * `WFH_Policy_Update_V2.txt`
  * `Acme_Corp_Master_Services_Agreement_2026.txt`
  * `IT_Security_Onboarding_Playbook.txt`
  are present and populated.

### 2. BigQuery Studio (Structured Operational Tables)
* Open [BigQuery Studio](https://console.cloud.google.com/bigquery).
* In the left **Explorer** pane, expand your project $\rightarrow$ **`double_click_kb`**.
* Select the **`project_db`** table and click the **Preview** tab:
  * Confirm rows for `Double-click` (`ACTIVE`), `Phoenix` (`ON_HOLD`), and `Alpha` (`DELAYED`) are visible.
* Select the **`retail_sales`** table and click the **Preview** tab:
  * Confirm transactions across `pos_sales_table`, `website_sales_table`, and `mobile_app_sales_table` are loaded.

### 3. Gemini Enterprise / Discovery Engine Console
* Open [Vertex AI Search / Gemini Enterprise](https://console.cloud.google.com/gen-app-builder/engines).
* **Verify the App:** Under **Apps**, select **`DoubleClick Enterprise - Gemini Enterprise App`** (`double-click-enterprise-app`):
  * Open **Connected data stores** in the left menu.
  * Confirm that both **`double-click-unstructured-ds`** and **`double-click-structured-bq-ds`** are connected.
* **Verify the Data Stores:** In the left navigation, click on **Data Stores** (ensure location is set to **`global`**):
  * Click on **`double-click-unstructured-ds`** $\rightarrow$ Check the **Activity** tab to see the GCS document import job status. Once completed, the **Documents** tab will list the 3 indexed documents.
  * Click on **`double-click-structured-bq-ds`** $\rightarrow$ Check the **Activity** tab to confirm the BigQuery import job and the **Schema** tab showing mapped fields.

---

## 🔧 Troubleshooting & Common Gotchas

| Issue | Cause | Resolution |
| :--- | :--- | :--- |
| `FAILED_PRECONDITION: The terms of service 'cloud' ... must be accepted` | The target project has not yet accepted Google Cloud Terms of Service. | Open `https://console.cloud.google.com/?project=<PROJECT_ID>` in your browser with the user account, click **Agree and Continue**, then re-run `./scripts/setup_infra.sh`. |
| `Your active project does not match the quota project` | Application Default Credentials (ADC) has a different quota project than `PROJECT_ID`. | Run `gcloud auth application-default set-quota-project <PROJECT_ID>`. |
| `Error 403: Caller does not have required permission to use project` | Missing IAM roles on the GCP account. | Ensure your user has `roles/editor` (or `roles/owner`), `roles/discoveryengine.editor`, `roles/storage.admin`, and `roles/bigquery.admin`. |
| BigQuery `Not found: Dataset` during import | Region mismatch between BigQuery dataset and load command. | `.env` sets `REGION="europe-west1"`. Both `bigquery.tf` and `scripts/setup_infra.sh` pass `--location="${REGION}"`. |
| Discovery Engine API 404 on regional endpoints | Discovery Engine location mismatch. | Keep `DISCOVERY_ENGINE_LOCATION="global"` in `.env` for standard multi-tenant enterprise data stores. |

---

## ⏭️ Next Step

Once you have validated Part 1, proceed to **Part 2 (Conversational Modeling)** to build our Dialogflow CX Agent Playbook, Vertex AI Agent Engine ADK Python Agent, and A2A Agent Card:

```bash
git checkout 02-conversational-modeling
```

