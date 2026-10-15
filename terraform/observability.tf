# ============================================================================
# Cloud Observability, BigQuery Log Sink & Monitoring Dashboard (`observability.tf`)
#
# 📌 Introduced in: Article 4 (Part 4 — 📈 Architecture & Monitoring)
#
# Purpose:
#   Provisions the 3-layer production observability architecture for DoubleClick
#   Enterprise:
#   1. A dedicated BigQuery Dataset (`double_click_agent_logs`) for storing
#      structured conversation history, grounded citations, and audit logs.
#   2. A Cloud Logging Project Sink (`google_logging_project_sink`) that routes
#      Vertex AI Agent Engine (`ReasoningEngine`), Dialogflow CX, and Gemini
#      Enterprise (`discoveryengine.googleapis.com`) logs into partitioned
#      BigQuery tables in real time.
#   3. Resource-level BigQuery IAM bindings granting the Log Sink's unique
#      writer identity `roles/bigquery.dataEditor` and our ADK Service Account
#      `roles/bigquery.dataViewer` for automated GenAI Evaluation jobs.
#   4. A Cloud Monitoring Custom Dashboard (`google_monitoring_dashboard`)
#      tracking Agent Engine request volume, Dialogflow CX turns, and BigQuery
#      log sink export throughput.
# ============================================================================

# 📌 Added since Article 4: BigQuery Dataset for Conversation History, Audit Logs & GenAI Evaluation
resource "google_bigquery_dataset" "agent_observability_logs" {
  dataset_id                  = var.bq_log_sink_dataset_id
  friendly_name               = "${var.company_name} — Agent & Gemini Enterprise Observability Logs"
  description                 = "Provisioned in Article 4: Destination dataset for Cloud Logging sink (Dialogflow CX, Discovery Engine, and Vertex AI Agent Engine) and continuous GenAI Evaluation."
  location                    = var.region
  delete_contents_on_destroy  = true

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 4: Partitioned BigQuery Table for Structured Agent Telemetry & GenAI Evaluation Runs
resource "google_bigquery_table" "agent_telemetry_and_eval_logs" {
  dataset_id          = google_bigquery_dataset.agent_observability_logs.dataset_id
  table_id            = "agent_telemetry_and_eval_logs"
  deletion_protection = false
  description         = "Added in Article 4: Stores structured conversation turns, OpenTelemetry trace IDs, tool trajectories, and GenAI Evaluation scores."

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  schema = jsonencode([
    { name = "eval_id",                 type = "STRING",    mode = "REQUIRED", description = "Unique evaluation or conversation turn ID" },
    { name = "timestamp",               type = "TIMESTAMP", mode = "REQUIRED", description = "UTC timestamp of the agent interaction or evaluation run" },
    { name = "category",                type = "STRING",    mode = "NULLABLE", description = "Scenario category (e.g., Contract & Pricing, Operational BigQuery)" },
    { name = "prompt",                  type = "STRING",    mode = "NULLABLE", description = "User query sent to the DoubleClick Enterprise agent" },
    { name = "expected_tool",           type = "STRING",    mode = "NULLABLE", description = "Expected ADK / Dialogflow tool invoked" },
    { name = "trajectory_match",        type = "FLOAT",     mode = "NULLABLE", description = "Tool trajectory accuracy score (0.0 to 1.0)" },
    { name = "groundedness_score",      type = "FLOAT",     mode = "NULLABLE", description = "Groundedness score against Part 1 Data Stores (0.0 to 1.0)" },
    { name = "safety_guardrail_passed", type = "BOOLEAN",   mode = "NULLABLE", description = "Whether banned-phrase guardrails (e.g. Project Chimera) passed" }
  ])
}

# 📌 Added since Article 4: Cloud Logging Sink routing Agent Engine, Dialogflow CX & Discovery Engine logs to BigQuery
#    (Enabled when var.enable_log_router_sink = true; requires roles/logging.configWriter)
resource "google_logging_project_sink" "agent_logs_to_bq" {
  count       = var.enable_log_router_sink ? 1 : 0
  name        = "${var.app_name}-agent-logs-bq-sink"
  description = "Added in Article 4: Streams Vertex AI Agent Engine (ReasoningEngine), Dialogflow CX, and Gemini Enterprise logs to BigQuery."
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.agent_observability_logs.dataset_id}"

  # Captures Vertex AI Agent Engine, Dialogflow CX, and Gemini Enterprise (Discovery Engine) logs
  filter = <<-EOT
    resource.type="aiplatform.googleapis.com/ReasoningEngine" OR
    resource.type="dialogflow.googleapis.com/Agent" OR
    logName:"dialogflow" OR
    logName:"discoveryengine.googleapis.com"
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }

  depends_on = [google_bigquery_dataset.agent_observability_logs]
}

# 📌 Added since Article 4: Grant the Log Sink Writer Identity permission to write into the BigQuery dataset
resource "google_bigquery_dataset_iam_member" "log_sink_bq_writer" {
  count      = var.enable_log_router_sink ? 1 : 0
  dataset_id = google_bigquery_dataset.agent_observability_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.agent_logs_to_bq[0].writer_identity
}

# 📌 Added since Article 4: Grant our ADK Agent / Evaluation Service Account read access to the Observability Dataset
resource "google_bigquery_dataset_iam_member" "adk_sa_observability_bq_viewer" {
  dataset_id = google_bigquery_dataset.agent_observability_logs.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

# 📌 Added since Article 4: Optional project-level OpenTelemetry Tracing, Logging & Monitoring IAM bindings
#    (Enabled when var.grant_project_iam_roles = true)
locals {
  part_4_observability_roles = [
    "roles/cloudtrace.agent",        # Emit OpenTelemetry spans from ADK Agent Engine to Cloud Trace
    "roles/logging.logWriter",       # Write structured agent logs to Cloud Logging
    "roles/monitoring.metricWriter", # Emit token & latency metrics to Cloud Monitoring
  ]
}

resource "google_project_iam_member" "adk_observability_bindings" {
  for_each = var.grant_project_iam_roles ? toset(local.part_4_observability_roles) : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

# 📌 Added since Article 4: Cloud Monitoring Custom Dashboard for DoubleClick Enterprise Agents
resource "google_monitoring_dashboard" "double_click_agent_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.company_name} — Gemini Enterprise & Agent Observability (Part 4)"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Cloud Logging -> BigQuery Sink Exported Log Entries (${var.app_name}-agent-logs-bq-sink)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"logging.googleapis.com/exports/byte_count\" resource.type=\"logging_sink\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "BigQuery Knowledge Base & Observability Query Count"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"bigquery.googleapis.com/query/count\" resource.type=\"bigquery_project\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_SUM"
                      }
                    }
                  }
                  plotType = "STACKED_BAR"
                }
              ]
            }
          }
        }
      ]
    }
  })

  depends_on = [google_project_service.enabled_apis]
}
