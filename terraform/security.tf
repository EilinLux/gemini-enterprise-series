# ============================================================================
# Security, Secret Manager & Document-Level ACL Configuration (`security.tf`)
#
# 📌 Introduced in: Article 5 (Part 5 — 🛡️ Integration & Security)
#
# Purpose:
#   1. Provisions a Google Cloud Secret Manager vault (`google_secret_manager_secret`)
#      for storing the OAuth 2.0 Client Secret used by our Jira / ServiceNow
#      Per-User Action integration.
#   2. Grants resource-scoped `roles/secretmanager.secretAccessor` to our ADK
#      Agent Engine Service Account (`google_secret_manager_secret_iam_member`)
#      following strict least-privilege security (only this secret, not all
#      project secrets!).
#   3. Optionally provisions the Discovery Engine ACL Configuration
#      (`google_discovery_engine_acl_config`) when `enable_workforce_identity = true`.
# ============================================================================

# 📌 Added since Article 5: Secret Manager Vault for Action OAuth 2.0 Client Secret (Jira / Salesforce)
resource "google_secret_manager_secret" "action_oauth_client_secret" {
  secret_id = var.oauth_action_secret_id

  replication {
    auto {}
  }

  labels = {
    app     = var.app_name
    company = "double-click-enterprise"
    article = "part-5-integration-and-security"
  }

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 5: Initial Secret Version (JSON OAuth 2.0 Client configuration template)
resource "google_secret_manager_secret_version" "action_oauth_client_secret_placeholder" {
  secret = google_secret_manager_secret.action_oauth_client_secret.id

  secret_data = jsonencode({
    provider      = "atlassian-jira-cloud"
    auth_type     = "PER_USER_OAUTH_2_0"
    client_id     = "double-click-jira-oauth-client-id"
    client_secret = "REPLACE_WITH_YOUR_JIRA_OAUTH_CLIENT_SECRET"
    auth_uri      = "https://auth.atlassian.com/authorize"
    token_uri     = "https://auth.atlassian.com/oauth/token"
    scopes        = ["read:jira-work", "write:jira-work", "offline_access"]
  })
}

# 📌 Added since Article 5: Resource-scoped Least-Privilege Secret Access for the ADK Agent Service Account
resource "google_secret_manager_secret_iam_member" "adk_sa_secret_accessor" {
  count     = var.grant_project_iam_roles ? 1 : 0
  secret_id = google_secret_manager_secret.action_oauth_client_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

# 📌 Added since Article 5: Optional Discovery Engine Identity & ACL Config (when Workforce Identity is enabled)
resource "google_discovery_engine_acl_config" "double_click_acl_config" {
  count    = var.enable_workforce_identity ? 1 : 0
  location = var.discovery_engine_location

  idp_config {
    idp_type = "GSUITE"
  }

  depends_on = [google_project_service.enabled_apis]
}
