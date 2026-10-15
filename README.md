# 🚀 Building Enterprise Agents with Gemini — The “Double-Click” Enterprise Series

Welcome to the official companion repository for the **Building Enterprise Agents with Gemini** Medium series!

This repository follows an **incremental branch-per-article architecture**: each branch corresponds to one part of the 5-part series and builds directly on top of the previous branch, driven by a **single unified `.env` configuration file** at the root of the project.

---

## 🏢 The Business Scenario: Why “DoubleClick Enterprise” Needs Gemini Enterprise

### Why the Name “Double-Click”?
In corporate and consulting slang, to **“double-click”** on a topic means to *drill down, inspect the underlying details, and look beneath the surface*. 

Throughout this series, you step into the role of **Lead AI Architect at DoubleClick Enterprise**—a fast-growing omni-channel retail and B2B technology company with offices in Milan, London, and New York. We named our internal AI assistant **“Double-click”** because its mission is to let any employee—from a Business Analyst to an Account Executive or Site Reliability Engineer—*double-click* into the company’s scattered knowledge and get verified, actionable answers in seconds.

### The Problem: A Classic Case of Enterprise “Data Silos”
Before adopting Gemini Enterprise, DoubleClick employees wasted hours every day hunting across three disconnected data ecosystems:
1. **Unstructured Documents & Archives (Google Cloud Storage):**
   * **HR & People Policies (`WFH_Policy_Update_V2.txt`):** Hybrid work rules & the €750 ergonomic home office stipend.
   * **Legal & Client Contracts (`Acme_Corp_Master_Services_Agreement_2026.txt`):** Renewal discount tiers & SLA penalty notes (linking *Project Alpha's* 14-day delay to vendor *CloudNet Hardware Ltd.*).
   * **IT & Security Runbooks (`IT_Security_Onboarding_Playbook.txt`):** Private Service Connect (PSC) rules & P1 escalation paths.
2. **Structured Operational & Retail Warehouses (BigQuery):**
   * **Project Portfolio Tracking (`double_click_kb.project_db`):** Real-time status (`Double-click` is `ACTIVE`, `Phoenix` is `ON_HOLD`, `Alpha` is `DELAYED`), budgets, and owners.
   * **Omni-Channel Retail Analytics (`double_click_kb.retail_sales`):** Sales across POS (`pos_sales_table`), website (`website_sales_table`), and mobile (`mobile_app_sales_table`).
3. **Live Third-Party SaaS Tools (Jira / ServiceNow / Salesforce):**
   * Zero-copy **Federation** for live issue lookups and **Per-User OAuth 2.0 Actions** for ticket creation.

---

## 📚 Series Table of Contents & Git Branch Map

| Branch | Medium Article Topic | Companion EXTRA Deep-Dive | What Gets Added in This Branch |
| :--- | :--- | :--- | :--- |
| **`01-knowledge-base-management`** | **Part 1 — 📚 Knowledge Base Management** | **Part 1 EXTRA — Code & Terraform Setup** | • **DoubleClick Enterprise** messy data (`data/unstructured/` & `data/structured/`)<br>• Modular Terraform (`apis.tf`, `storage.tf`, `bigquery.tf`, `discovery_engine.tf`) connecting Data Stores to the Gemini Enterprise App |
| **`02-conversational-modeling`** | **Part 2 — 🗣️ Conversational Modeling** | **Part 2 EXTRA — Agent Code & Terraform Setup** | • **Dialogflow CX / CX Agent Studio** (`dialogflow_cx.tf`) + Generative Playbook (`startPlaybook`)<br>• **ADK Python Agent** (`agents/adk_double_click_agent/`) + **A2A JSON Agent Card** + `vertex_ai_agent.tf` |
| **`03-ux-ui-and-accessibility`** | **Part 3 — 🎨 UX/UI & Accessibility** | **Part 3 EXTRA — UI & Widget Terraform Setup** | • **Widget & Branding Config (`terraform/widget_ui.tf`):** Custom DoubleClick SVG logo, `SEARCH_WITH_FOLLOW_UPS`, Autocomplete, Feedback, Allowlisted Domains<br>• **Feature Management Governance (`terraform/discovery_engine.tf`):** `features` map controlling Agent Gallery, No-Code Builder, NotebookLM, Memory & Admin Approval |
| **`04-architecture-and-monitoring`** *(Current)* | **Part 4 — 📈 Architecture & Monitoring** | **Part 4 EXTRA — Observability & Eval Setup** | • **Observability & Audit Pipeline (`terraform/observability.tf`):** Partitioned BigQuery Dataset (`double_click_agent_logs`), **Cloud Logging Router Sink** (`double-click-agent-logs-bq-sink`), least-privilege dataset IAM, and **Cloud Monitoring Custom Dashboard**<br>• **Continuous Quality & Trajectory Evaluator (`agents/evaluate_agent.py`):** Golden dataset evaluator for tool trajectory, groundedness & safety guardrails |
| **`05-integration-and-security`** | **Part 5 — 🛡️ Integration & Security** *(Checkout `05-integration-and-security`)* | **Part 5 EXTRA — Security, OAuth & Mock Web Portal** *(Checkout `05-integration-and-security`)* | • **Per-User OAuth 2.0 Actions**, **Secret Manager** (`security.tf`), **ACL Config**, & **Interactive Mocked Enterprise Intranet Web App (`webapp/`)** |

---

## ⚠️ Prerequisites & Authentication

1. **Google Cloud Project** with billing enabled and **Gemini Enterprise Standard/Plus** (or 180-day trial) active under **Gemini Enterprise > Manage subscriptions**.
2. **Authenticate your `gcloud` CLI and Terraform Application Default Credentials (ADC):**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. **Configure `.env`:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to set `PROJECT_ID="your-gcp-project-id"` and review the Part 4 observability variables (`BQ_LOGS_DATASET_ID="double_click_agent_logs"`, `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY="true"`, and `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT="EVENT_ONLY"`).

---

## 🛠️ How to Provision & Test (Branch `04-architecture-and-monitoring`)

### 1. Run the Automated Verification & Golden Evaluation Suite
```bash
./scripts/test_infra.sh
```
This validates all `.env.example` keys, sample data, Part 2 ADK Python tools & A2A JSON card, Part 3 Widget Config, Part 4 `terraform/observability.tf`, and runs `python3 agents/evaluate_agent.py` against the DoubleClick Enterprise Golden Dataset.

### 2. Provision Parts 1–4 Infrastructure
```bash
./scripts/setup_infra.sh
```
After `setup_infra.sh` completes, you can also run the standalone Golden Dataset Evaluator at any time:
```bash
# Fast deterministic CI/CD trajectory & groundedness evaluation
python3 agents/evaluate_agent.py

# Live LLM-as-a-Judge evaluation via Vertex AI GenAI Evaluation Service (EvalTask)
python3 agents/evaluate_agent.py --live-vertex-eval
```

---

## 🖥️ How to Verify the Provisioned Resources in the Google Cloud Console UI

After running `./scripts/setup_infra.sh`, you can verify every Part 1–4 resource in the Google Cloud Console UI:

1. **Part 1 — Verify Data Stores & Connected App:**
   * Open [Cloud Storage Buckets](https://console.cloud.google.com/storage/browser) (`<YOUR_PROJECT_ID>-double-click-docs-staging`) and [BigQuery Studio](https://console.cloud.google.com/bigquery) (`double_click_kb.project_db` & `retail_sales`).
   * In **Gemini Enterprise > Apps**, click **`DoubleClick Enterprise - Gemini Enterprise App`** (`double-click-enterprise-app`) and open **Data Stores** to confirm both `double-click-unstructured-ds` and `double-click-structured-bq-ds` are attached.
2. **Part 2 — Verify Conversational Agents:**
   * Open [CX Agent Studio / Dialogflow CX Console](https://dialogflow.cloud.google.com/cx/projects) (location **`global`**) and verify **`double-click_cx_custom_qa_agent`** and its **`DoubleClick Enterprise Knowledge & Policy Concierge`** Playbook.
3. **Part 3 — Verify Branding, Search UI, Feature Management & Widget Integration:**
   * In **Gemini Enterprise > Apps > `DoubleClick Enterprise - Gemini Enterprise App` > Configurations**, verify the **Search UI** branding logo, autocomplete, feedback, and **Feature Management** toggles, plus **Integration** authorized domains (`localhost`, `internal.doubleclick.example.com`).
4. **Part 4 — Verify Analytics, BigQuery Log Sink, Cloud Trace & Monitoring Dashboard:**
   * **Gemini Enterprise Built-In Analytics:** Inside **Gemini Enterprise > Apps > `DoubleClick Enterprise - Gemini Enterprise App`**, click **Analytics** at the bottom of the left navigation menu to inspect the Looker-powered **Adoption**, **Usage & Quality** (👍/👎 feedback & citation CTR), and **Agent Metrics** tabs.
   * **Cloud Logging Router Sink:** Open [Cloud Logging > Log Router](https://console.cloud.google.com/logs/router) and verify that **`double-click-agent-logs-bq-sink`** is listed and routing `ReasoningEngine`, `dialogflow`, and `discoveryengine.googleapis.com` logs into BigQuery.
   * **BigQuery Observability Dataset:** Open [BigQuery Studio](https://console.cloud.google.com/bigquery) and confirm the **`double_click_agent_logs`** dataset is provisioned alongside `double_click_kb`, with `roles/bigquery.dataEditor` granted to the sink's unique writer identity.
   * **Cloud Monitoring Custom Dashboard:** Open [Cloud Monitoring > Dashboards](https://console.cloud.google.com/monitoring/dashboards) and click **`DoubleClick Enterprise — Gemini Enterprise & Agent Observability (Part 4)`** to view real-time log sink export throughput and BigQuery query volume charts.
   * **Cloud Trace Waterfall:** Open [Cloud Trace > Trace Explorer](https://console.cloud.google.com/traces/list) to inspect OpenTelemetry execution spans (`AdkApp.query`, `call_llm`, `execute_tool`) emitted when `enable_tracing=True`.

---

## ⏭️ Next Step
Switch to Branch 05 (Finale) to add **Security, Per-User OAuth 2.0 Actions, Secret Manager, Document ACLs, and the Interactive Mocked DoubleClick Intranet Web Portal**:
```bash
git checkout 05-integration-and-security
```
