# ============================================================================
# Terraform Input Variables (`variables.tf`)
# ============================================================================

# ----------------------------------------------------------------------------
# 📌 Added since Article 1: Core Project, Location & Knowledge Base Variables
# ----------------------------------------------------------------------------

variable "project_id" {
  description = "Since Article 1: The Google Cloud Project ID where Gemini Enterprise resources will be deployed (loaded from .env via TF_VAR_project_id)."
  type        = string
}

variable "region" {
  description = "Since Article 1: Default GCP region for regional resources (BigQuery, GCS)."
  type        = string
  default     = "europe-west1"
}

variable "discovery_engine_location" {
  description = "Since Article 1: Location for Gemini Enterprise / Discovery Engine Data Stores ('global', 'us', or 'eu')."
  type        = string
  default     = "global"
}

variable "app_name" {
  description = "Since Article 1: Prefix/name for the DoubleClick Enterprise application."
  type        = string
  default     = "double-click"
}

variable "company_name" {
  description = "Since Article 1: Company name used in Gemini Enterprise configuration."
  type        = string
  default     = "DoubleClick Enterprise"
}

variable "bq_dataset_id" {
  description = "Since Article 1: BigQuery Dataset ID for the DoubleClick Knowledge Base."
  type        = string
  default     = "double_click_kb"
}

variable "gcs_bucket_suffix" {
  description = "Since Article 1: Suffix for the GCS unstructured documents bucket."
  type        = string
  default     = "docs-staging"
}

variable "enable_federated_connector" {
  description = "Since Article 1: Set to true to provision the 3rd-party Federated Data Connector resource alongside our Ingested Data Stores."
  type        = bool
  default     = false
}

variable "federated_connector_source" {
  description = "Since Article 1: Third-party data source type for Federation (e.g., 'jira', 'confluence', 'salesforce', 'slack')."
  type        = string
  default     = "jira"
}
