# ============================================================================
# Gemini Enterprise / Discovery Engine Service Configuration (`discovery_engine.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
# 📌 Updated in:    Article 2 (Part 2 — 🗣️ Conversational Modeling)
#    Adds the Gemini Enterprise Search & Assistant App (`google_discovery_engine_search_engine`)
#    so we can connect our Data Stores and register our Dialogflow CX, ADK, and A2A Agents!
# ============================================================================

# 📌 Added since Article 1: INGESTION Data Store — Unstructured Docs (Layout Chunking + Graph RAG)
resource "google_discovery_engine_data_store" "unstructured_docs_ds" {
  location                    = var.discovery_engine_location
  data_store_id               = "${var.app_name}-unstructured-ds"
  display_name                = "${var.company_name} - Unstructured Docs (Ingested Graph RAG)"
  industry_vertical           = "GENERIC"
  content_config              = "CONTENT_REQUIRED"
  solution_types              = ["SOLUTION_TYPE_SEARCH", "SOLUTION_TYPE_CHAT"]
  create_advanced_site_search = false

  document_processing_config {
    default_parsing_config {
      digital_parsing_config {}
    }
    chunking_config {
      layout_based_chunking_config {
        chunk_size                = 500
        include_ancestor_headings = true
      }
    }
  }

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 1: INGESTION Data Store — Structured BigQuery Data
resource "google_discovery_engine_data_store" "structured_bq_ds" {
  location                    = var.discovery_engine_location
  data_store_id               = "${var.app_name}-structured-bq-ds"
  display_name                = "${var.company_name} - Structured BigQuery Data Store"
  industry_vertical           = "GENERIC"
  content_config              = "NO_CONTENT"
  solution_types              = ["SOLUTION_TYPE_SEARCH", "SOLUTION_TYPE_CHAT"]
  create_advanced_site_search = false

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 1: FEDERATION Data Connector — Live 3rd-Party SaaS Pass-Through (e.g., Jira)
resource "google_discovery_engine_data_connector" "federated_saas_connector" {
  count                   = var.enable_federated_connector ? 1 : 0
  location                = var.discovery_engine_location
  collection_id           = "${var.app_name}-federated-collection"
  collection_display_name = "${var.company_name} - Federated ${upper(var.federated_connector_source)} Connector"

  data_source       = var.federated_connector_source
  connector_modes   = ["FEDERATED"]
  refresh_interval  = "86400s"
  auto_run_disabled = false

  json_params = jsonencode({
    instance_uri = "https://doubleclick.atlassian.net"
  })

  entities {
    entity_name = "issue"
  }

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 1: Gemini Enterprise App ("Double-click" Search & Assistant Hub)
#    Connects the Unstructured (GCS) and Structured (BigQuery) Data Stores directly into
#    a true Gemini Enterprise Intranet App (APP_TYPE_INTRANET) with Private Knowledge Graph.
resource "google_discovery_engine_search_engine" "gemini_enterprise_app" {
  engine_id         = "${var.app_name}-enterprise-app"
  collection_id     = "default_collection"
  location          = google_discovery_engine_data_store.unstructured_docs_ds.location
  display_name      = "${var.company_name} - Gemini Enterprise App"
  industry_vertical = "GENERIC"
  app_type          = "APP_TYPE_INTRANET"

  data_store_ids = [
    google_discovery_engine_data_store.unstructured_docs_ds.data_store_id,
    google_discovery_engine_data_store.structured_bq_ds.data_store_id,
  ]

  common_config {
    company_name = var.company_name
  }

  search_engine_config {
    search_tier                = "SEARCH_TIER_ENTERPRISE"
    search_add_ons             = ["SEARCH_ADD_ON_LLM"]
    required_subscription_tier = "SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT"
  }

  knowledge_graph_config {
    enable_private_knowledge_graph = true
  }
}

