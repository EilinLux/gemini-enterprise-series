# ============================================================================
# Gemini Enterprise Widget, Branding & UI Configuration (`widget_ui.tf`)
#
# 📌 Introduced in: Article 3 (Part 3 — 🎨 UX/UI and Accessibility)
#    Configures the Gemini Enterprise Web App & Embedded Search Widget
#    (`google_discovery_engine_widget_config`), including:
#    - Custom company logo (`ui_branding.logo`)
#    - Multi-turn conversational follow-ups (`SEARCH_WITH_FOLLOW_UPS`)
#    - Autocomplete, People Search, End-User Quality Feedback, and Agent Builder button
#    - Generative Answer Grounding Settings (`generative_answer_config`)
#    - Web App & Allowlisted Domain Access Settings (`access_settings`)
# ============================================================================

# 📌 Added since Article 3: Gemini Enterprise Widget & Web App UI Configuration
resource "google_discovery_engine_widget_config" "double_click_widget_config" {
  location         = google_discovery_engine_search_engine.gemini_enterprise_app.location
  collection_id    = google_discovery_engine_search_engine.gemini_enterprise_app.collection_id
  engine_id        = google_discovery_engine_search_engine.gemini_enterprise_app.engine_id
  widget_config_id = "default_search_widget_config"

  # 📌 Added since Article 3: Web App & Domain Allowlist Access Settings
  access_settings {
    enable_web_app      = true
    allow_public_access = false
    language_code       = "en-US"
    allowlisted_domains = split(",", var.allowlisted_domains)
  }

  # 📌 Added since Article 3: Custom DoubleClick Enterprise Branding Logo
  ui_branding {
    logo {
      url = var.company_logo_url
    }
  }

  # 📌 Added since Article 3: Search & Assistant Experience Settings
  ui_settings {
    interaction_type                  = "SEARCH_WITH_FOLLOW_UPS"
    enable_autocomplete               = true
    enable_quality_feedback           = true
    enable_people_search              = true
    enable_create_agent_button        = true
    enable_safe_search                = true
    result_description_type           = "EXTRACTIVE_ANSWER"
    source_admin_display_name_enabled = true

    # 📌 Added since Article 3: Generative Grounded Answer Configuration
    generative_answer_config {
      result_count                  = 5
      max_rephrase_steps            = 3
      ignore_adversarial_query      = true
      ignore_low_relevant_content   = true
      ignore_non_answer_seeking_query = false
      language_code                 = "en"
      model_prompt_preamble         = "You are the official ${var.company_name} ('Double-click') Search & Knowledge Assistant. Format answers clearly with bullet points and always cite the underlying policy document or BigQuery record."
    }
  }
}
