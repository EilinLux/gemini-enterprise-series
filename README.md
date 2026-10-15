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
DoubleClick Enterprise chose **Gemini Enterprise** (and the **Vertex AI Agent Builder** ecosystem) to build a unified, production-grade AI platform across 5 architectural pillars:
* **Part 1 (Knowledge Base):** Combine **Ingestion (Graph RAG)** over GCS & BigQuery with **Federation** for live zero-copy queries into Jira.
* **Part 2 (Conversational Modeling — *Current Branch*):** Blend deterministic compliance flows (**Dialogflow CX / Conversational Agents**) with autonomous multi-step Python agents (**ADK on Vertex AI Agent Engine**) and remote **A2A** agents.
* **Part 3 (UX/UI & Accessibility):** Deliver a white-labeled, accessible assistant with DoubleClick's custom logo, pinned shortcuts, and granular **Feature Management** governance.
* **Part 4 (Architecture & Monitoring):** Give leadership Looker-powered **Adoption & Quality Analytics**, while giving SREs deep **OpenTelemetry (`Cloud Trace`)** waterfall debugging and continuous **BigQuery / GenAI Evaluations**.
* **Part 5 (Integration & Security):** Enforce strict **Workforce Identity Federation**, **Document-Level ACLs**, and **Per-User OAuth 2.0 Actions**.

---

## 📚 Series Table of Contents & Git Branch Map

| Branch | Main Medium Article (Concepts & Console UI) | Companion EXTRA Article (Code & Terraform Deep-Dive) | What Gets Added in This Branch |
| :--- | :--- | :--- | :--- |
| **`01-knowledge-base-management`** | **[Part 1 — 📚 Knowledge Base Management](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-1-knowledge-base-management.md)** | **[Part 1 EXTRA — Code & Terraform Setup](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-1-extra-code-and-terraform-setup.md)** | • **DoubleClick Enterprise** messy data scenario (`data/unstructured/` & `data/structured/`)<br>• Modular Terraform (`apis.tf`, `storage.tf`, `bigquery.tf`, `discovery_engine.tf`) |
| **`02-conversational-modeling`** *(Current)* | **[Part 2 — 🗣️ Conversational Modeling](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-2-conversational-modeling.md)** | **[Part 2 EXTRA — Agent Code & Terraform Setup](file:///Users/zelda.luconi/Medium/gemini-enterprise-series/part-2-extra-code-and-terraform-setup.md)** | • **Conversational Agent (Dialogflow CX)** + Generative Playbook (`terraform/dialogflow_cx.tf`)<br>• **Gemini Enterprise App** (`google_discovery_engine_search_engine`) & **Q&A Chat Engine**<br>• **ADK Python Agent** (`agents/adk_double_click_agent/`), IAM (`terraform/vertex_ai_agent.tf`), & **A2A JSON Agent Card** |
| **`03-ux-ui-and-accessibility`** | **Part 3 — 🎨 UX/UI & Accessibility** *(Checkout branch `03-ux-ui-and-accessibility`)* | **Part 3 EXTRA — UI & Widget Terraform Setup** *(Checkout branch `03-ux-ui-and-accessibility`)* | • **Widget & Branding Config** (`terraform/widget_ui.tf` — `google_discovery_engine_widget_config`)<br>• Search UI, Logo, Pinned Shortcuts & Feature Management automation |
| **`04-architecture-and-monitoring`** | **Part 4 — 📈 Architecture & Monitoring** *(Checkout branch `04-architecture-and-monitoring`)* | **Part 4 EXTRA — Observability & Eval Setup** *(Checkout branch `04-architecture-and-monitoring`)* | • **OpenTelemetry Tracing** (`Cloud Trace`) & IAM bindings<br>• **Cloud Logging $\rightarrow$ BigQuery Sink** & **Cloud Monitoring Dashboard** (`terraform/observability.tf`) |
| **`05-integration-and-security`** | **Part 5 — 🛡️ Integration & Security** *(Checkout branch `05-integration-and-security`)* | **Part 5 EXTRA — Security, OAuth & Mock Web Portal** *(Checkout branch `05-integration-and-security`)* | • **Per-User OAuth 2.0 Actions**, **Secret Manager**, & **ACL Config** (`terraform/security.tf`)<br>• **Interactive Mocked Enterprise Intranet Web App (`webapp/`)** |

---

## 🛠️ How to Set Up the Infrastructure (Branch `02-conversational-modeling`)

All infrastructure across every branch is controlled by a **single `.env` file** in the root directory (git-ignored so your private project ID is never committed).

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
DIALOGFLOW_TIME_ZONE="Europe/Rome"
DIALOGFLOW_DEFAULT_LANGUAGE="en"
ADK_AGENT_DISPLAY_NAME="double-click-adk-concierge"
GEMINI_MODEL="gemini-2.5-pro"
```

### Step 2: Provision Part 1 + Part 2 Infrastructure
Run the automated setup script in the `scripts/` folder:
```bash
./scripts/setup_infra.sh
```
**What `./scripts/setup_infra.sh` does on Branch 02:**
1. Provisions all **Part 1 Knowledge Base** resources (`storage.tf`, `bigquery.tf`, `discovery_engine.tf`) and imports the unstructured GCS documents and structured BigQuery rows.
2. Provisions the **Gemini Enterprise App** (`double-click-enterprise-app` in `discovery_engine.tf`) attached to both Data Stores.
3. Provisions the **Conversational Agent / Dialogflow CX Agent** (`double-click_cx_custom_qa_agent`), its **Generative Playbook** (`DoubleClick Enterprise Knowledge & Policy Concierge`), and the **Q&A Chat Engine** (`double-click-qa-chat-engine`) via `terraform/dialogflow_cx.tf`.
4. Provisions the **ADK Agent Engine Service Account & IAM roles** via `terraform/vertex_ai_agent.tf`.

### Step 3: (Optional) Deploy the Python ADK Agent to Vertex AI Agent Engine
```bash
python3 agents/adk_double_click_agent/deploy_agent_engine.py
```

---

## 🖥️ How to Verify the Provisioned Resources in the Google Cloud Console UI

After running `./scripts/setup_infra.sh`, check the existence of both Part 1 and Part 2 resources in the Google Cloud Console UI:

1. **Verify the Gemini Enterprise App & Q&A Chat Engine:**
   * Open the [Google Cloud Console — Gemini Enterprise Apps](https://console.cloud.google.com/gen-app-builder/engines).
   * Confirm that **`DoubleClick Enterprise - Gemini Enterprise App`** (`double-click-enterprise-app`) and **`DoubleClick Enterprise - Grounded Q&A Chat Agent`** (`double-click-qa-chat-engine`) appear in the Apps list.
   * Click on **`DoubleClick Enterprise - Gemini Enterprise App` > Connected data stores** to verify both `double-click-unstructured-ds` and `double-click-structured-bq-ds` are attached!
2. **Verify the Conversational Agent & Playbook in the Dialogflow CX Console:**
   * Open the [Conversational Agents (Dialogflow CX) Console](https://dialogflow.cloud.google.com/cx/projects) and select your project.
   * Verify that **`double-click_cx_custom_qa_agent`** is listed in the `global` location.
   * Click on the agent and select **Playbooks** in the left sidebar to inspect the **`DoubleClick Enterprise Knowledge & Policy Concierge`** Playbook and its 3 grounding instructions.
3. **Link the Dialogflow CX or A2A Agent into Gemini Enterprise:**
   * Run `terraform -chdir=terraform output dialogflow_cx_agent_resource_name` to copy the exact `projects/<PROJECT>/locations/global/agents/<ID>` string.
   * In the Gemini Enterprise Console, go to **Apps > DoubleClick Enterprise - Gemini Enterprise App > Agents > + Add agent > Custom agent via Dialogflow** and paste the resource string (or choose **Custom agent via A2A** and paste the contents of `agents/a2a_agent_card/double_click_a2a_agent_card.json`).
4. **Verify the ADK Service Account in IAM:**
   * Open [Google Cloud Console — Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) and verify **`double-click-adk-agent-sa`** exists with Vertex AI, Discovery Engine, and BigQuery roles.

---

## 🧪 How to Test the Repository

Run the automated test suite (which unit-tests the ADK Python tools, validates the A2A JSON Agent Card, checks Bash syntax, and validates all modular Terraform files):

```bash
./scripts/test_infra.sh
```

---

## ⏭️ Next Step
Switch to the next branch to customize the **Gemini Enterprise UX/UI, Branding, Widget Configuration, and Feature Management**:
```bash
git checkout 03-ux-ui-and-accessibility
```
