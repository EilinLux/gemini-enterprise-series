# ============================================================================
# Conversational Agents, CX Agent Studio & Dialogflow CX (`dialogflow_cx.tf`)
#
# 📌 Introduced in: Article 2 (Part 2 — 🗣️ Conversational Modeling)
#    Provisions:
#    1. A Dialogflow CX Agent (`google_dialogflow_cx_agent`) + Generative Playbook
#       (`google_dialogflow_cx_playbook`) and sets `start_playbook` so it runs
#       in Generative Playbook mode.
#    2. A Next-Gen CX Agent Studio App & Root LLM Agent (`google_ces_app`,
#       `google_ces_agent`, `google_ces_app_root_agent_association`) via `ces.googleapis.com`
#       so the agent is also visible directly in CX Agent Studio!
#    3. Automated connection (`terraform_data.connect_agents_to_gemini_enterprise_app`)
#       that links our Dialogflow CX Agent and A2A Agent Card directly into the
#       Gemini Enterprise App (`double-click-enterprise-app`).
# ============================================================================

# 📌 Added since Article 2: Standalone Conversational Agent (Dialogflow CX) for Custom Agent Integration
resource "google_dialogflow_cx_agent" "double_click_cx_agent" {
  display_name            = "${var.app_name}_cx_custom_qa_agent"
  location                = var.discovery_engine_location
  default_language_code   = var.dialogflow_default_language
  time_zone               = var.dialogflow_time_zone
  description             = "Part 2 Example: DoubleClick Enterprise hybrid deterministic + generative Conversational Agent."
  enable_spell_correction = true

  advanced_settings {
    logging_settings {
      enable_stackdriver_logging = true
      enable_interaction_logging = true
    }
  }

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 2: Generative AI Playbook inside the Dialogflow CX Agent
resource "google_dialogflow_cx_playbook" "double_click_concierge_playbook" {
  parent        = google_dialogflow_cx_agent.double_click_cx_agent.id
  display_name  = "DoubleClick Enterprise Knowledge & Policy Concierge"
  goal          = "Help DoubleClick Enterprise employees answer questions about company policies (WFH stipend), client contracts (Acme Corp), and project statuses (Double-click, Phoenix, Alpha)."
  playbook_type = "TASK"

  instruction {
    steps {
      text = "1. Greet the DoubleClick Enterprise employee warmly and identify whether their question is about HR policies, client contracts, or operational project status."
    }
    steps {
      text = "2. Ground your response strictly in the connected DoubleClick Enterprise Data Stores and always cite the source document or BigQuery table."
    }
    steps {
      text = "3. If the user asks about a restricted Tier 3 project (such as Project Phoenix), remind them that Security Clearance Level 2 and Private Service Connect (PSC) are required."
    }
  }
}

# 📌 Added since Article 2: Optional Next-Gen CX Agent Studio App (`ces.googleapis.com`)
#    Requires `roles/ces.admin` (`ces.apps.create`). Note that for our Dialogflow CX Agent above,
#    we also set `startPlaybook` via REST API below so it opens directly in Generative Playbook
#    mode inside Conversational Agents Studio (`conversational-agents.cloud.google.com`)!
resource "google_ces_app" "double_click_ces_studio_app" {
  count        = var.enable_ces_studio_app ? 1 : 0
  location     = var.discovery_engine_location
  app_id       = "${var.app_name}-ces-studio-app"
  display_name = "${var.company_name} — CX Agent Studio App"
  description  = "Since Article 2: Next-gen Customer Engagement Suite (CX Agent Studio) application for ${var.company_name}"

  global_instruction = "You are the official ${var.company_name} ('Double-click') AI Concierge. Always provide accurate answers grounded in DoubleClick Enterprise policies, contracts, and project databases."

  language_settings {
    default_language_code       = var.dialogflow_default_language
    enable_multilingual_support = true
  }

  time_zone_settings {
    time_zone = var.dialogflow_time_zone
  }

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 2: Root Generative LLM Agent inside CX Agent Studio (`google_ces_agent`)
resource "google_ces_agent" "double_click_ces_root_agent" {
  count        = var.enable_ces_studio_app ? 1 : 0
  location     = google_ces_app.double_click_ces_studio_app[0].location
  app          = google_ces_app.double_click_ces_studio_app[0].app_id
  agent_id     = "${var.app_name}-ces-concierge"
  display_name = "${var.company_name} Policy & Project Concierge"
  description  = "Handles employee questions about WFH Policy V2, Acme Corp MSA 2026, and Project Double-click / Phoenix / Alpha status."
  instruction  = <<-EOT
    1. Greet the ${var.company_name} employee warmly and identify whether their question is about HR policies (WFH stipend), client contracts (Acme Corp), or operational project status.
    2. Ground your response in ${var.company_name} data stores and cite the source document or BigQuery table.
    3. If the user asks about Project Phoenix, remind them that Security Clearance Level 2 and Private Service Connect (PSC) are required.
  EOT

  llm_agent {}
}

# 📌 Added since Article 2: Associate the Root Agent with the CX Agent Studio App
resource "google_ces_app_root_agent_association" "double_click_ces_root_assoc" {
  count    = var.enable_ces_studio_app ? 1 : 0
  location = google_ces_app.double_click_ces_studio_app[0].location
  app_id   = google_ces_app.double_click_ces_studio_app[0].app_id
  agent_id = google_ces_agent.double_click_ces_root_agent[0].name
}

# 📌 Added since Article 2: Connect Created Agents (Dialogflow CX & A2A) to the Gemini Enterprise App
#    Uses the Discovery Engine v1alpha Assistant Agents API to register our Dialogflow CX Agent
#    and A2A Agent Card inside `double-click-enterprise-app/assistants/default_assistant/agents`.
resource "terraform_data" "connect_agents_to_gemini_enterprise_app" {
  triggers_replace = [
    google_discovery_engine_search_engine.gemini_enterprise_app.engine_id,
    google_dialogflow_cx_agent.double_click_cx_agent.id,
    google_dialogflow_cx_playbook.double_click_concierge_playbook.id,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      ACCESS_TOKEN="$(gcloud auth print-access-token)"
      API_HOST="discoveryengine.googleapis.com"
      if [ "${var.discovery_engine_location}" != "global" ]; then
        API_HOST="${var.discovery_engine_location}-discoveryengine.googleapis.com"
      fi

      # 1. Set startPlaybook on the Dialogflow CX Agent so it defaults to Generative Playbook mode
      #    (This makes it open directly in Playbook Studio mode inside Conversational Agents!)
      curl -s -X PATCH \
        -H "Authorization: Bearer $${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "X-Goog-User-Project: ${var.project_id}" \
        "https://dialogflow.googleapis.com/v3/${google_dialogflow_cx_agent.double_click_cx_agent.id}?updateMask=startPlaybook" \
        -d "{\"startPlaybook\": \"${google_dialogflow_cx_playbook.double_click_concierge_playbook.id}\"}" > /dev/null || true

      # 2. Check existing connected agents in the Gemini Enterprise App
      AGENTS_URL="https://$${API_HOST}/v1alpha/projects/${var.project_id}/locations/${var.discovery_engine_location}/collections/default_collection/engines/${google_discovery_engine_search_engine.gemini_enterprise_app.engine_id}/assistants/default_assistant/agents"
      EXISTING_AGENTS="$(curl -s -H "Authorization: Bearer $${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${var.project_id}" "$${AGENTS_URL}")"

      # 3. Connect the Dialogflow CX Agent to the Gemini Enterprise App if not already linked
      if ! echo "$${EXISTING_AGENTS}" | grep -q "${google_dialogflow_cx_agent.double_click_cx_agent.name}"; then
        echo "🔗 Connecting Dialogflow CX Agent (${google_dialogflow_cx_agent.double_click_cx_agent.display_name}) to Gemini Enterprise App..."
        DF_RESP="$(curl -s -X POST \
          -H "Authorization: Bearer $${ACCESS_TOKEN}" \
          -H "Content-Type: application/json" \
          -H "X-Goog-User-Project: ${var.project_id}" \
          "$${AGENTS_URL}" \
          -d "{
            \"displayName\": \"${var.company_name} — Dialogflow CX Concierge\",
            \"description\": \"Hybrid deterministic + generative Dialogflow CX agent for ${var.company_name} policies and project status.\",
            \"dialogflowAgentDefinition\": {
              \"dialogflowAgent\": \"${google_dialogflow_cx_agent.double_click_cx_agent.id}\"
            },
            \"sharingConfig\": {
              \"scope\": \"ALL_USERS\"
            }
          }")"
        if echo "$${DF_RESP}" | grep -q '"name":'; then
          echo "   ✅ Dialogflow CX Agent connected to ${google_discovery_engine_search_engine.gemini_enterprise_app.engine_id}!"
        else
          echo "   ℹ️  Dialogflow CX Agent API registration note: $${DF_RESP}"
        fi
      else
        echo "   ✅ Dialogflow CX Agent is already connected to ${google_discovery_engine_search_engine.gemini_enterprise_app.engine_id}."
      fi

      # 4. Connect the A2A Agent Card to the Gemini Enterprise App if not already linked
      if ! echo "$${EXISTING_AGENTS}" | grep -q "double_click_remote_a2a_agent"; then
        echo "🔗 Connecting Remote A2A Agent (double_click_remote_a2a_agent) to Gemini Enterprise App..."
        A2A_PAYLOAD="$(python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    card_str = f.read().strip()
print(json.dumps({
    "displayName": sys.argv[2] + " — Remote Supply Chain A2A Agent",
    "description": "Remote multi-agent collaborator speaking the Agent-to-Agent (A2A) protocol for supplier SLA checks.",
    "a2aAgentDefinition": {
        "jsonAgentCard": card_str
    },
    "sharingConfig": {
        "scope": "ALL_USERS"
    }
}))
' "${path.module}/../agents/a2a_agent_card/double_click_a2a_agent_card.json" "${var.company_name}")"
        A2A_RESP="$(curl -s -X POST \
          -H "Authorization: Bearer $${ACCESS_TOKEN}" \
          -H "Content-Type: application/json" \
          -H "X-Goog-User-Project: ${var.project_id}" \
          "$${AGENTS_URL}" \
          -d "$${A2A_PAYLOAD}")"
        if echo "$${A2A_RESP}" | grep -q '"name":'; then
          echo "   ✅ Remote A2A Agent connected to ${google_discovery_engine_search_engine.gemini_enterprise_app.engine_id}!"
        else
          echo "   ℹ️  Remote A2A Agent API registration note: $${A2A_RESP}"
        fi
      else
        echo "   ✅ Remote A2A Agent is already connected to ${google_discovery_engine_search_engine.gemini_enterprise_app.engine_id}."
      fi
    EOT
  }
}
