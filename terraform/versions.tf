# ============================================================================
# Terraform Providers & Versions (`versions.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
#    Configures the Google and Google-Beta providers with `user_project_override`
#    and `billing_project` so Discovery Engine / Dialogflow CX API calls always
#    use the target project from `.env` as the ADC quota project.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.10.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.10.0"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}
