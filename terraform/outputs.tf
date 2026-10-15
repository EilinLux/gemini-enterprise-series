# ============================================================================
# Terraform Outputs (`outputs.tf`)
# ============================================================================

# ----------------------------------------------------------------------------
# 📌 Added since Article 1: Knowledge Base & Data Store Outputs
# ----------------------------------------------------------------------------

output "gcs_docs_and_staging_bucket" {
  description = "Added in Article 1: GCS bucket containing the uploaded DoubleClick unstructured policy & contract documents."
  value       = "gs://${google_storage_bucket.enterprise_docs_and_staging.name}"
}

output "bigquery_project_db_table" {
  description = "Added in Article 1: Full BigQuery table ID for operational project Q&A (project_db)."
  value       = "${var.project_id}.${google_bigquery_dataset.enterprise_kb.dataset_id}.${google_bigquery_table.project_db.table_id}"
}

output "bigquery_retail_sales_table" {
  description = "Added in Article 1: Full BigQuery table ID for the Retail Sales Use Case (retail_sales)."
  value       = "${var.project_id}.${google_bigquery_dataset.enterprise_kb.dataset_id}.${google_bigquery_table.retail_sales.table_id}"
}

output "unstructured_ingested_data_store_id" {
  description = "Added in Article 1 (Ingestion / Graph RAG): Resource ID of the Unstructured Docs Data Store."
  value       = google_discovery_engine_data_store.unstructured_docs_ds.id
}

output "structured_bigquery_data_store_id" {
  description = "Added in Article 1 (Structured RAG): Resource ID of the Structured BigQuery Data Store."
  value       = google_discovery_engine_data_store.structured_bq_ds.id
}

output "federated_connector_status" {
  description = "Added in Article 1 (Federation / Pass-Through): Status of the Federated SaaS Data Connector."
  value       = var.enable_federated_connector ? google_discovery_engine_data_connector.federated_saas_connector[0].id : "Disabled (Set ENABLE_FEDERATED_CONNECTOR=true in .env to provision)"
}

output "gemini_enterprise_app_id" {
  description = "Added in Article 1: The Gemini Enterprise App ID ('double-click-enterprise-app') connected to our Unstructured and Structured Data Stores."
  value       = google_discovery_engine_search_engine.gemini_enterprise_app.engine_id
}

# ----------------------------------------------------------------------------
# 📌 Added since Article 2: Conversational Modeling & Agent Integration Outputs
# ----------------------------------------------------------------------------

output "dialogflow_cx_agent_resource_name" {
  description = "Added in Article 2: Exact Dialogflow CX Agent resource string to paste into Gemini Enterprise -> '+ Add agent' -> 'Custom agent via Dialogflow'."
  value       = "projects/${var.project_id}/locations/${google_dialogflow_cx_agent.double_click_cx_agent.location}/agents/${google_dialogflow_cx_agent.double_click_cx_agent.name}"
}

output "dialogflow_cx_playbook_id" {
  description = "Added in Article 2: Resource ID of the Generative Playbook created inside our Dialogflow CX Agent."
  value       = google_dialogflow_cx_playbook.double_click_concierge_playbook.id
}

output "ces_studio_app_name" {
  description = "Added in Article 2: Resource name of the Customer Engagement Suite (CX Agent Studio) App (when enable_ces_studio_app = true)."
  value       = var.enable_ces_studio_app ? google_ces_app.double_click_ces_studio_app[0].name : "Disabled (Set TF_VAR_enable_ces_studio_app=true if you have roles/ces.admin; note that startPlaybook is automatically enabled on our Dialogflow CX Agent for Conversational Agents Studio!)"
}

output "gemini_enterprise_assistant_name" {
  description = "Added in Article 2: Resource name of the Default Assistant configured inside the Gemini Enterprise App."
  value       = "${google_discovery_engine_search_engine.gemini_enterprise_app.name}/assistants/default_assistant"
}

output "adk_agent_service_account_email" {
  description = "Added in Article 2: Dedicated Service Account email for deploying the ADK Agent on Vertex AI Agent Engine."
  value       = google_service_account.adk_agent_engine_sa.email
}

output "adk_deploy_cli_command" {
  description = "Added in Article 2: Ready-to-run ADK CLI command using the provisioned GCS staging bucket."
  value       = <<-EOT
    adk deploy agent_engine \
      --project=${var.project_id} \
      --region=${var.region} \
      --staging_bucket=gs://${google_storage_bucket.enterprise_docs_and_staging.name} \
      --display_name="${var.adk_agent_display_name}" \
      ./agents/adk_double_click_agent
  EOT
}

# ----------------------------------------------------------------------------
# 📌 Added since Article 3: UX/UI, Widget Config & Web Component Snippet
# ----------------------------------------------------------------------------

output "widget_config_name" {
  description = "Added in Article 3: Full resource name of the configured Gemini Enterprise Widget & Branding config."
  value       = google_discovery_engine_widget_config.double_click_widget_config.name
}

output "widget_obfuscated_config_id" {
  description = "Added in Article 3: Obfuscated configId used inside the <gen-search-widget> HTML web component."
  value       = google_discovery_engine_widget_config.double_click_widget_config.config_id
}

output "embedded_widget_html_snippet" {
  description = "Added in Article 3: Ready-to-embed HTML snippet for the DoubleClick Enterprise <gen-search-widget>."
  value       = <<-EOT
    <script src="https://cloud.google.com/ai/gen-app-builder/client?hl=en_US"></script>
    <gen-search-widget
      configId="${google_discovery_engine_widget_config.double_click_widget_config.config_id}"
      triggerId="searchWidgetTrigger">
    </gen-search-widget>
    <input placeholder="Double-click into company knowledge..." id="searchWidgetTrigger" />
  EOT
}

