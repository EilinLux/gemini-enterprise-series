/**
 * DoubleClick Enterprise — Intranet Security, ACL & Per-User OAuth 2.0 Simulator (`app.js`)
 * 📌 Introduced in: Article 5 (Part 5 — 🛡️ Integration & Security)
 */

const PERSONAS = {
  vp: {
    email: "zelda-vp@doubleclick.example.com",
    roleLabel: "VP / Lead AI Architect",
    clearance: "Clearance Level 2 • group:exec-leadership",
    allowedSources: ["wfh-policy", "acme-msa", "it-security", "bq-projects"],
  },
  intern: {
    email: "zelda-intern@doubleclick.example.com",
    roleLabel: "Junior Business Intern",
    clearance: "Clearance Level 1 • group:general-staff",
    allowedSources: ["wfh-policy", "bq-projects-public"],
  },
};

const DATA_SOURCES = [
  {
    id: "wfh-policy",
    title: "📄 WFH_Policy_Update_V2.txt (GCS Unstructured)",
    aclTag: "ACL: group:all-employees",
    allowedFor: ["vp", "intern"],
  },
  {
    id: "acme-msa",
    title: "📄 Acme_Corp_Master_Services_Agreement_2026.txt (GCS Legal Archive)",
    aclTag: "ACL: group:exec-leadership, group:legal-counsel",
    allowedFor: ["vp"],
  },
  {
    id: "it-security",
    title: "📄 IT_Security_Onboarding_Playbook.txt (GCS Security Runbooks)",
    aclTag: "ACL: Clearance Level 2 (PSC & Network Architecture)",
    allowedFor: ["vp"],
  },
  {
    id: "bq-projects",
    title: "📊 double_click_kb.project_db — Project Phoenix (PRJ-002) & Alpha (PRJ-003)",
    aclTag: "ACL: Clearance Level 2 (Confidential Budget & Vendor SLA Notes)",
    allowedFor: ["vp"],
  },
];

const oauthTokensByPersona = {
  vp: false,
  intern: false,
};

let currentPersonaKey = "vp";

function appendAuditLog(message) {
  const logEl = document.getElementById("securityAuditLog");
  const ts = new Date().toISOString().split("T")[1].slice(0, 8);
  const entry = document.createElement("div");
  entry.textContent = `[${ts}] ${message}`;
  logEl.prepend(entry);
}

function renderAclMatrix() {
  const persona = PERSONAS[currentPersonaKey];
  document.getElementById("activeClearanceBadge").textContent = persona.clearance;

  const listEl = document.getElementById("aclDocumentList");
  listEl.innerHTML = "";

  DATA_SOURCES.forEach((src) => {
    const isAllowed = src.allowedFor.includes(currentPersonaKey);
    const row = document.createElement("div");
    row.className = `acl-item ${isAllowed ? "allowed" : "denied"}`;
    row.innerHTML = `
      <div>
        <div class="acl-title">${src.title}</div>
        <div class="acl-meta">${src.aclTag}</div>
      </div>
      <span class="status-tag ${isAllowed ? "allowed" : "denied"}">
        ${isAllowed ? "✅ RETRIEVED INTO CONTEXT" : "🛑 PRE-FILTERED BY ACL"}
      </span>
    `;
    listEl.appendChild(row);
  });

  updateOAuthBadge();
}

function updateOAuthBadge() {
  const badge = document.getElementById("oauthTokenBadge");
  const hasToken = oauthTokensByPersona[currentPersonaKey];
  const persona = PERSONAS[currentPersonaKey];

  if (hasToken) {
    badge.textContent = `✅ Jira OAuth Linked (${persona.email})`;
    badge.style.background = "rgba(16, 185, 129, 0.16)";
    badge.style.color = "#34d399";
    badge.style.borderColor = "rgba(16, 185, 129, 0.35)";
  } else {
    badge.textContent = "⚠️ Jira OAuth Not Linked";
    badge.style.background = "rgba(245, 158, 11, 0.16)";
    badge.style.color = "#fbbf24";
    badge.style.borderColor = "rgba(245, 158, 11, 0.35)";
  }
}

function renderIdleActionStage() {
  const stage = document.getElementById("oauthActionStage");
  const persona = PERSONAS[currentPersonaKey];
  stage.innerHTML = `
    <h3>Ready to Execute <code>/tools</code> Action as <code>${persona.email}</code></h3>
    <p style="font-size: 0.82rem; color: #94a3b8;">
      Click <strong>"Run Action: Create P1 Jira Ticket for Project Alpha Delay"</strong> above to trace how
      Gemini Enterprise enforces Per-User OAuth 2.0 consent and Human-in-the-Loop confirmation.
    </p>
  `;
}

function startJiraActionFlow() {
  const persona = PERSONAS[currentPersonaKey];
  const hasToken = oauthTokensByPersona[currentPersonaKey];
  const stage = document.getElementById("oauthActionStage");

  appendAuditLog(`Intent routed: /tools create_jira_issue requested by ${persona.email}`);

  if (!hasToken) {
    appendAuditLog(`No OAuth 2.0 token cached for ${persona.email}. Rendering Per-User Consent Card.`);
    stage.innerHTML = `
      <h3>🔐 Step 1 of 2: Per-User OAuth 2.0 Authorization Required</h3>
      <p style="font-size: 0.82rem; color: #94a3b8; margin-bottom: 0.75rem;">
        To create a Jira issue on your behalf, Gemini Enterprise needs your personal Atlassian OAuth 2.0 consent
        (configured via Secret Manager vault <code>double-click-jira-action-oauth-secret</code>):
      </p>
      <div class="kv-grid">
        <span class="kv-key">Identity:</span><span>${persona.email}</span>
        <span class="kv-key">OAuth Scopes:</span><span>read:jira-work, write:jira-work</span>
        <span class="kv-key">Target API:</span><span>https://api.atlassian.com/ex/jira/rest/api/3/issue</span>
      </div>
      <button type="button" class="btn btn-primary" id="approveOAuthConsentBtn">
        🔑 Authorize Jira Account (${persona.email})
      </button>
    `;
    document.getElementById("approveOAuthConsentBtn").addEventListener("click", () => {
      oauthTokensByPersona[currentPersonaKey] = true;
      updateOAuthBadge();
      appendAuditLog(`OAuth 2.0 Access Token issued & scoped strictly to ${persona.email}.`);
      renderHitlConfirmationCard();
    });
  } else {
    renderHitlConfirmationCard();
  }
}

function renderHitlConfirmationCard() {
  const persona = PERSONAS[currentPersonaKey];
  const stage = document.getElementById("oauthActionStage");

  appendAuditLog(`Rendering Human-in-the-Loop (HITL) Confirmation Card for ${persona.email}.`);
  stage.innerHTML = `
    <h3>🛡️ Step 2 of 2: Human-in-the-Loop (HITL) Action Confirmation</h3>
    <p style="font-size: 0.82rem; color: #94a3b8;">
      Review the grounded parameters extracted from <code>double_click_kb.project_db</code> and
      <code>Acme_Corp_Master_Services_Agreement_2026.txt</code> before executing the write operation:
    </p>
    <div class="kv-grid">
      <span class="kv-key">Project Key:</span><span>DC-INFRA (DoubleClick Operations)</span>
      <span class="kv-key">Issue Type:</span><span>Incident • Priority: P1 (Critical)</span>
      <span class="kv-key">Summary:</span><span>Project Alpha (PRJ-003) 14-day POS delay — CloudNet Hardware Ltd. SLA</span>
      <span class="kv-key">Reporter:</span><span>${persona.email} (Per-User OAuth 2.0 Bearer Token)</span>
    </div>
    <div style="display: flex; gap: 0.65rem; margin-top: 0.75rem;">
      <button type="button" class="btn btn-emerald" id="confirmHitlExecuteBtn">
        ✅ Confirm & Create Jira Ticket
      </button>
      <button type="button" class="btn btn-outline" id="cancelHitlExecuteBtn">
        Cancel
      </button>
    </div>
  `;

  document.getElementById("confirmHitlExecuteBtn").addEventListener("click", () => {
    const ticketId = `DC-INFRA-${Math.floor(400 + Math.random() * 90)}`;
    appendAuditLog(
      `POST /rest/api/3/issue (Bearer: ${persona.email}) -> 201 Created (${ticketId}, Reporter: ${persona.email})`
    );
    stage.innerHTML = `
      <h3 style="color: #34d399;">🎉 Action Executed: Jira Ticket <code>${ticketId}</code> Created!</h3>
      <p style="font-size: 0.83rem; color: #94a3b8; margin-top: 0.35rem;">
        Created strictly using <strong>${persona.email}</strong>'s delegated OAuth 2.0 token (not a shared service account)
        and logged to BigQuery dataset <code>double_click_agent_logs</code>.
      </p>
    `;
  });

  document.getElementById("cancelHitlExecuteBtn").addEventListener("click", () => {
    appendAuditLog(`HITL Action cancelled by ${persona.email}.`);
    renderIdleActionStage();
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const selectEl = document.getElementById("userIdentitySelect");
  selectEl.addEventListener("change", (e) => {
    currentPersonaKey = e.target.value;
    appendAuditLog(`Switched Workforce Identity session to ${PERSONAS[currentPersonaKey].email}`);
    renderAclMatrix();
    renderIdleActionStage();
  });

  document.getElementById("proposeJiraActionBtn").addEventListener("click", startJiraActionFlow);

  document.getElementById("resetOAuthFlowBtn").addEventListener("click", () => {
    oauthTokensByPersona[currentPersonaKey] = false;
    updateOAuthBadge();
    appendAuditLog(`Revoked cached Jira OAuth 2.0 token for ${PERSONAS[currentPersonaKey].email}`);
    renderIdleActionStage();
  });

  document.getElementById("applyConfigIdBtn").addEventListener("click", () => {
    const newId = document.getElementById("widgetConfigIdInput").value.trim();
    const widgetEl = document.getElementById("geminiEnterpriseWidget");
    if (newId && widgetEl) {
      widgetEl.setAttribute("configId", newId);
      appendAuditLog(`Updated <gen-search-widget> configId to ${newId}`);
    }
  });

  renderAclMatrix();
  renderIdleActionStage();
  appendAuditLog("DoubleClick Enterprise Intranet Portal initialized with Gemini Enterprise Widget.");
});
