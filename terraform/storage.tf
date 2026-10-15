# ============================================================================
# Google Cloud Storage Service Configuration (`storage.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
#    Provisions the GCS bucket and uploads DoubleClick Enterprise's unstructured
#    documents (HR Policy, Client MSA Contract, IT Security Runbook) for Graph RAG.
# ============================================================================

# 📌 Added since Article 1: GCS Bucket for Unstructured RAG Documents (and Part 2 ADK Staging)
resource "google_storage_bucket" "enterprise_docs_and_staging" {
  name                        = "${var.project_id}-${var.app_name}-${var.gcs_bucket_suffix}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 1: Sample Unstructured Doc 1 — Employee Hybrid Work & WFH Policy V2
resource "google_storage_bucket_object" "wfh_policy_doc" {
  name         = "unstructured/WFH_Policy_Update_V2.txt"
  bucket       = google_storage_bucket.enterprise_docs_and_staging.name
  source       = "${path.module}/../data/unstructured/WFH_Policy_Update_V2.txt"
  content_type = "text/plain"
}

# 📌 Added since Article 1: Sample Unstructured Doc 2 — Acme Corp Master Services Agreement (2026)
resource "google_storage_bucket_object" "acme_contract_doc" {
  name         = "unstructured/Acme_Corp_Master_Services_Agreement_2026.txt"
  bucket       = google_storage_bucket.enterprise_docs_and_staging.name
  source       = "${path.module}/../data/unstructured/Acme_Corp_Master_Services_Agreement_2026.txt"
  content_type = "text/plain"
}

# 📌 Added since Article 1: Sample Unstructured Doc 3 — IT & Security Onboarding Playbook (PSC Rules)
resource "google_storage_bucket_object" "security_runbook_doc" {
  name         = "unstructured/IT_Security_Onboarding_Playbook.txt"
  bucket       = google_storage_bucket.enterprise_docs_and_staging.name
  source       = "${path.module}/../data/unstructured/IT_Security_Onboarding_Playbook.txt"
  content_type = "text/plain"
}
