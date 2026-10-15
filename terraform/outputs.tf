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

