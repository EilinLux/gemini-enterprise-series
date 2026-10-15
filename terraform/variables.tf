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
  description = "Since Article 1: Default GCP region for regional resources (BigQuery, GCS, Vertex AI Agent Engine)."
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

# ----------------------------------------------------------------------------
# 📌 Added since Article 2: Conversational Modeling (Dialogflow CX & ADK)
# ----------------------------------------------------------------------------

variable "dialogflow_time_zone" {
  description = "Since Article 2: Time zone for the Conversational Agent / Dialogflow CX Agent."
  type        = string
  default     = "Europe/Rome"
}

variable "dialogflow_default_language" {
  description = "Since Article 2: Default language code for the Conversational Agent."
  type        = string
  default     = "en"
}

variable "adk_agent_display_name" {
  description = "Since Article 2: Display name for the ADK Agent deployed on Vertex AI Agent Engine."
  type        = string
  default     = "double-click-adk-concierge"
}

variable "gemini_model" {
  description = "Since Article 2: Default Gemini foundation model used by the ADK Agent."
  type        = string
  default     = "gemini-2.5-pro"
}

variable "grant_project_iam_roles" {
  description = "Since Article 2: Set to true if your caller identity has Project IAM Admin (resourcemanager.projects.setIamPolicy) to bind project-level roles in addition to resource-level GCS/BigQuery IAM bindings."
  type        = bool
  default     = false
}

variable "enable_ces_studio_app" {
  description = "Since Article 2: Set to true if your caller identity has Customer Engagement Suite Admin (ces.apps.create) to also provision a standalone google_ces_app alongside Dialogflow CX."
  type        = bool
  default     = false
}


# ----------------------------------------------------------------------------
# 📌 Added since Article 3: UX/UI, Branding, Widget & Shortcuts
# ----------------------------------------------------------------------------

variable "company_logo_url" {
  description = "Since Article 3: Public HTTPS URL for the DoubleClick Enterprise logo displayed in the Gemini Enterprise Web App and Search Widget."
  type        = string
  default     = "https://upload.wikimedia.org/wikipedia/commons/6/6b/Double-click-161563.svg"
}

variable "shortcut_title" {
  description = "Since Article 3: Title of the pinned navigation shortcut in the Gemini Enterprise Web App."
  type        = string
  default     = "Google News"
}

variable "shortcut_url" {
  description = "Since Article 3: Destination URL of the pinned navigation shortcut in the Gemini Enterprise Web App."
  type        = string
  default     = "https://news.google.com/"
}

variable "allowlisted_domains" {
  description = "Since Article 3: Comma-separated list of domains allowed to embed the Gemini Enterprise `<gen-search-widget>`."
  type        = string
  default     = "localhost,internal.doubleclick.example.com"
}


# ----------------------------------------------------------------------------
# 📌 Added since Article 4: Architecture, Observability & Log Export
# ----------------------------------------------------------------------------

variable "bq_log_sink_dataset_id" {
  description = "Since Article 4: BigQuery Dataset ID where Cloud Logging exports Gemini Enterprise, Dialogflow CX, and Vertex AI Agent Engine conversation/audit logs."
  type        = string
  default     = "double_click_agent_logs"
}

variable "enable_cloud_trace" {
  description = "Since Article 4: Whether OpenTelemetry distributed tracing (Cloud Trace) is enabled for the ADK Agent on Vertex AI Agent Engine."
  type        = bool
  default     = true
}

variable "enable_log_router_sink" {
  description = "Since Article 4: Set to true if your caller identity has Logging Config Writer (roles/logging.configWriter / logging.sinks.create) to provision the project-level Cloud Logging -> BigQuery sink in addition to the BigQuery Observability Dataset & Table."
  type        = bool
  default     = false
}



