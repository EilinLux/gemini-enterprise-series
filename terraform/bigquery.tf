# ============================================================================
# Google BigQuery Service Configuration (`bigquery.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
#    Provisions the DoubleClick Enterprise Knowledge Base dataset and structured
#    tables (`project_db` for operational Q&A and `retail_sales` for omni-channel RAG).
# ============================================================================

# 📌 Added since Article 1: BigQuery Dataset for Structured Knowledge Base tables
resource "google_bigquery_dataset" "enterprise_kb" {
  dataset_id    = var.bq_dataset_id
  friendly_name = "${var.company_name} Knowledge Base Dataset"
  description   = "Part 1 Hands-on: Structured operational project_db and retail_sales tables for DoubleClick Enterprise"
  location      = var.region

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 1: Operational Project Portfolio Table (`project_db`)
resource "google_bigquery_table" "project_db" {
  dataset_id          = google_bigquery_dataset.enterprise_kb.dataset_id
  table_id            = "project_db"
  deletion_protection = false
  description         = "Operational project status table used in Part 1 Q&A and metadata discovery examples"

  schema = jsonencode([
    { name = "project_id",   type = "STRING",  mode = "REQUIRED", description = "Unique identifier of the internal project" },
    { name = "project_name", type = "STRING",  mode = "REQUIRED", description = "Name of the project (e.g., Double-click, Phoenix, Alpha)" },
    { name = "status",       type = "STRING",  mode = "REQUIRED", description = "Current lifecycle status (ACTIVE, ON_HOLD, DELAYED, COMPLETED)" },
    { name = "owner_email",  type = "STRING",  mode = "NULLABLE", description = "Project lead email address" },
    { name = "department",   type = "STRING",  mode = "NULLABLE", description = "Owning business unit or engineering department" },
    { name = "budget_usd",   type = "INTEGER", mode = "NULLABLE", description = "Allocated annual budget in USD" },
    { name = "summary",      type = "STRING",  mode = "NULLABLE", description = "Executive summary of project deliverables and blockers" }
  ])
}

# 📌 Added since Article 1: Multi-Channel Retail Sales Table (`retail_sales`)
resource "google_bigquery_table" "retail_sales" {
  dataset_id          = google_bigquery_dataset.enterprise_kb.dataset_id
  table_id            = "retail_sales"
  deletion_protection = false
  description         = "Part 1 Section 3 Retail Use Case: Unified sales across POS, Website, and Mobile App channels"

  schema = jsonencode([
    { name = "transaction_id", type = "STRING", mode = "REQUIRED", description = "Unique transaction record ID" },
    { name = "channel",        type = "STRING", mode = "REQUIRED", description = "Source table/channel (website_sales_table, pos_sales_table, mobile_app_sales_table)" },
    { name = "product_line",   type = "STRING", mode = "REQUIRED", description = "Product category (e.g., Summer Clothing Line)" },
    { name = "sale_date",      type = "DATE",   mode = "REQUIRED", description = "Date of transaction" },
    { name = "store_region",   type = "STRING", mode = "NULLABLE", description = "Geographic retail region" },
    { name = "amount_usd",     type = "FLOAT",  mode = "REQUIRED", description = "Aggregated revenue in USD" }
  ])
}
