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

| Branch | Main Medium Article (Concepts & Console UI) | Companion EXTRA Article (Code & Terraform Deep-Dive) | What Gets Added in This Branch |
| :--- | :--- | :--- | :--- |
| **`01-knowledge-base-management`** | **[Part 1 — 📚 Knowledge Base Management](part-1-knowledge-base-management.md)** | **[Part 1 EXTRA — Code & Terraform Setup](part-1-extra-code-and-terraform-setup.md)** | • **DoubleClick Enterprise** messy data (`data/unstructured/` & `data/structured/`)<br>• Modular Terraform (`apis.tf`, `storage.tf`, `bigquery.tf`, `discovery_engine.tf`) connecting Data Stores to the Gemini Enterprise App |
| **`02-conversational-modeling`** | **[Part 2 — 🗣️ Conversational Modeling](part-2-conversational-modeling.md)** | **[Part 2 EXTRA — Agent Code & Terraform Setup](part-2-extra-code-and-terraform-setup.md)** | • **Dialogflow CX** (`dialogflow_cx.tf`) + Generative Playbook<br>• **ADK Python Agent** (`agents/adk_double_click_agent/`) + **A2A JSON Agent Card** + `vertex_ai_agent.tf` |
| **`03-ux-ui-and-accessibility`** *(Current)* | **[Part 3 — 🎨 UX/UI & Accessibility](part-3-ux-ui-and-accessibility.md)** | **[Part 3 EXTRA — UI & Widget Terraform Setup](part-3-extra-code-and-terraform-setup.md)** | • **Widget & Branding Config (`terraform/widget_ui.tf`):** Custom DoubleClick SVG logo, `SEARCH_WITH_FOLLOW_UPS`, Autocomplete, Feedback, Allowlisted Domains<br>• **Feature Management Governance (`terraform/discovery_engine.tf`):** `features` map controlling Agent Gallery, No-Code Builder, NotebookLM, Memory & Admin Approval |
| **`04-architecture-and-monitoring`** | **Part 4 — 📈 Architecture & Monitoring** *(Checkout `04-architecture-and-monitoring`)* | **Part 4 EXTRA — Observability & Eval Setup** *(Checkout `04-architecture-and-monitoring`)* | • **OpenTelemetry Tracing** (`observability.tf`), **BigQuery Log Sink**, **Cloud Monitoring Dashboard**, and GenAI Eval runner |
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
   Edit `.env` to set `PROJECT_ID="your-gcp-project-id"` and review the Part 3 UX/UI variables (`COMPANY_LOGO_URL`, `SHORTCUT_TITLE`, `SHORTCUT_URL`, `ALLOWLISTED_DOMAINS`).

---

## 🛠️ How to Provision & Test (Branch `03-ux-ui-and-accessibility`)

### 1. Run the Automated Verification Suite
```bash
./scripts/test_infra.sh
```
This validates all `.env.example` keys, sample data, Part 2 ADK Python tools & A2A JSON card, and validates all modular Terraform files (including `terraform/widget_ui.tf`).

### 2. Validate Configuration & Inspect Terraform Plan
```bash
# Validates Terraform syntax and verifies that ADK root_agent loads cleanly:
./scripts/setup_infra.sh --dry-run

# Inspect the Terraform execution plan driven directly by .env:
./scripts/setup_infra.sh --plan
```

### 3. Provision Part 1 + Part 2 + Part 3 Infrastructure
```bash
./scripts/setup_infra.sh
```
What this script performs automatically:
1. Enables required Google Cloud APIs (`discoveryengine`, `bigquery`, `storage`, `dialogflow`, `aiplatform`, and `iam`).
2. Applies Terraform to configure Part 3 Widget Config (`google_discovery_engine_widget_config`) and Feature Governance toggles on the Gemini Enterprise App.
3. Seeds BigQuery structured tables and triggers Discovery Engine document imports.
4. Configures the Gemini Enterprise Default Assistant with system instructions and customer policies.

After `setup_infra.sh` completes, print your ready-to-embed `<gen-search-widget>` HTML snippet:
```bash
terraform -chdir=terraform output embedded_widget_html_snippet
```

### 4. Automated Live Cloud Verification
Verify all provisioned resources directly against live GCP APIs with a single command:
```bash
./scripts/verify_live_infra.sh
```

## 🖥️ How to Verify the Provisioned Resources in the Google Cloud Console UI

After running `./scripts/setup_infra.sh`, you can verify every Part 1, Part 2, and Part 3 resource in the Google Cloud Console UI:

1. **Part 1 — Verify Data Stores & Connected App:**
   * Open [Cloud Storage Buckets](https://console.cloud.google.com/storage/browser) (`<YOUR_PROJECT_ID>-double-click-docs-staging`) and [BigQuery Studio](https://console.cloud.google.com/bigquery) (`double_click_kb.project_db` & `retail_sales`).
   * In **Gemini Enterprise > Apps**, click **`DoubleClick Enterprise - Gemini Enterprise App`** (`double-click-enterprise-app`) and open **Connected data stores** to confirm both `double-click-unstructured-ds` and `double-click-structured-bq-ds` are attached.
2. **Part 2 — Verify Conversational Agents:**
   * Open the [Dialogflow CX Console](https://dialogflow.cloud.google.com/cx/projects) (location **`global`**) and verify **`double-click_cx_custom_qa_agent`** and its **`DoubleClick Enterprise Knowledge & Policy Concierge`** Playbook.
3. **Part 3 — Verify Branding, Search UI, Feature Management & Widget Integration:**
   * In **Gemini Enterprise > Apps > `DoubleClick Enterprise - Gemini Enterprise App`**, click **Configurations** in the left-hand navigation menu:
     * **Search UI tab:** Verify that **Show autocomplete suggestions** and **Enable feedback** are toggled **On**, and that the **Logo image** field displays our DoubleClick Enterprise SVG URL (`https://upload.wikimedia.org/wikipedia/commons/6/6b/Double-click-161563.svg`). You can also add the **Google News** Pinned Shortcut (`https://news.google.com/`) in the preview panel and click **Save and Publish**.
     * **Feature Management tab:** Verify that **Agent gallery**, **Prompt gallery**, **NotebookLM**, and **Memory & customization** are toggled **On**, while unapproved organization-wide agent sharing is restricted.
   * Click **Integration** in the left-hand menu:
     * Verify that `localhost` and `internal.doubleclick.example.com` are listed under **Authorized domains** and inspect the `<gen-search-widget>` snippet.

---

## ⏭️ Next Step
Switch to Branch 04 to add **Architecture, OpenTelemetry Tracing, BigQuery Log Sinks, and Cloud Monitoring Dashboards**:
```bash
git checkout 04-architecture-and-monitoring
```
