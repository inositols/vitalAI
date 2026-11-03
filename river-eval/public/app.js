/**
 * VitalAI • River AI Evaluation Workbench Client Logic
 */

// Application State
const state = {
  presets: [],
  activePresetId: null,
  currentResponse: null,
  isExecuting: false,
  timerInterval: null,
  startTime: null,
};

// DOM Elements
const elements = {
  // Status & Alerts
  apiStatusBadge: document.getElementById('api-status-badge'),
  statusDot: document.getElementById('status-dot'),
  statusLabel: document.getElementById('status-label'),
  keyAlertBanner: document.getElementById('key-alert-banner'),
  btnCloseKeyAlert: document.getElementById('btn-close-key-alert'),
  presetCount: document.getElementById('preset-count'),
  presetList: document.getElementById('preset-list'),
  criteriaItemsList: document.getElementById('criteria-items-list'),

  // Form Inputs
  evalForm: document.getElementById('eval-form'),
  modelInput: document.getElementById('model-input'),
  responseFormatSelect: document.getElementById('response-format-select'),
  tempSlider: document.getElementById('temperature-slider'),
  tempVal: document.getElementById('temp-val'),
  maxTokensInput: document.getElementById('max-tokens-input'),
  tokensVal: document.getElementById('tokens-val'),
  systemPromptInput: document.getElementById('system-prompt-input'),
  systemPromptToggle: document.getElementById('system-prompt-toggle'),
  systemPromptWrapper: document.getElementById('system-prompt-wrapper'),
  sysChevron: document.getElementById('sys-chevron'),
  userPromptInput: document.getElementById('user-prompt-input'),
  charCount: document.getElementById('char-count'),
  btnSubmitEval: document.getElementById('btn-submit-eval'),
  submitBtnLabel: document.getElementById('submit-btn-label'),
  btnClearPrompt: document.getElementById('btn-clear-prompt'),
  btnResetParams: document.getElementById('btn-reset-params'),

  // Metrics
  metricModel: document.getElementById('metric-model'),
  metricLatency: document.getElementById('metric-latency'),
  metricPromptTokens: document.getElementById('metric-prompt-tokens'),
  metricCompTokens: document.getElementById('metric-comp-tokens'),
  metricTotalTokens: document.getElementById('metric-total-tokens'),
  metricJsonStatus: document.getElementById('metric-json-status'),

  // Output Views & Tabs
  tabButtons: document.querySelectorAll('.tab-btn'),
  tabContents: document.querySelectorAll('.tab-content'),
  viewIdle: document.getElementById('view-idle'),
  viewLoading: document.getElementById('view-loading'),
  viewError: document.getElementById('view-error'),
  liveTimer: document.getElementById('live-timer'),
  errorTitle: document.getElementById('error-title'),
  errorMessage: document.getElementById('error-message'),
  errorHintText: document.getElementById('error-hint-text'),

  // Tab Viewports
  responseFormattedBody: document.getElementById('response-formatted-body'),
  genuiPreviewWrapper: document.getElementById('genui-preview-wrapper'),
  genuiEmptyState: document.getElementById('genui-empty-state'),
  genuiCardFrame: document.getElementById('genui-card-frame'),
  genuiBadgeActive: document.getElementById('genui-badge-active'),
  rawCodeContent: document.getElementById('raw-code-content'),

  // Buttons & Actions
  btnCopyResponse: document.getElementById('btn-copy-response'),
  btnCopyRaw: document.getElementById('btn-copy-raw'),
  btnExportLog: document.getElementById('btn-export-log'),
  btnCopyScorecard: document.getElementById('btn-copy-scorecard'),
  btnSaveEvaluation: document.getElementById('btn-save-evaluation'),
  scoreSelects: document.querySelectorAll('.score-select'),
  evalNotesInput: document.getElementById('eval-notes-input'),
  overallScoreDisplay: document.getElementById('overall-score-display'),
  toastContainer: document.getElementById('toast-container'),
};

/* ==========================================================================
   Initialization
   ========================================================================== */
document.addEventListener('DOMContentLoaded', async () => {
  setupEventListeners();
  await checkHealth();
  await loadPresets();
});

/* ==========================================================================
   Event Listeners Setup
   ========================================================================== */
function setupEventListeners() {
  // Slider displays
  elements.tempSlider.addEventListener('input', (e) => {
    elements.tempVal.textContent = parseFloat(e.target.value).toFixed(2);
  });

  elements.maxTokensInput.addEventListener('input', (e) => {
    elements.tokensVal.textContent = e.target.value;
  });

  // Prompt character count
  elements.userPromptInput.addEventListener('input', () => {
    const len = elements.userPromptInput.value.length;
    elements.charCount.textContent = `${len.toLocaleString()} chars`;
  });

  // System prompt accordion toggle
  elements.systemPromptToggle.addEventListener('click', () => {
    const isCollapsed = elements.systemPromptWrapper.classList.toggle('collapsed');
    elements.sysChevron.classList.toggle('open', !isCollapsed);
  });

  // Form submit & shortcuts
  elements.evalForm.addEventListener('submit', handleFormSubmit);

  // Ctrl + Enter shortcut
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      if (!state.isExecuting) {
        e.preventDefault();
        elements.evalForm.requestSubmit();
      }
    }
  });

  // Clear button
  elements.btnClearPrompt.addEventListener('click', () => {
    elements.userPromptInput.value = '';
    elements.charCount.textContent = '0 chars';
    elements.userPromptInput.focus();
  });

  // Reset parameters
  elements.btnResetParams.addEventListener('click', () => {
    elements.modelInput.value = 'zai-org/GLM-5.3-Flash';
    elements.responseFormatSelect.value = 'text';
    elements.tempSlider.value = '0.20';
    elements.tempVal.textContent = '0.20';
    elements.maxTokensInput.value = '1024';
    elements.tokensVal.textContent = '1024';
    showToast('Parameters reset to defaults', 'info');
  });

  // Tab switching
  elements.tabButtons.forEach((btn) => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  });

  // Copy actions
  elements.btnCopyResponse.addEventListener('click', copyResponseContent);
  elements.btnCopyRaw.addEventListener('click', copyRawJson);
  elements.btnCopyScorecard.addEventListener('click', copyScorecardMarkdown);
  elements.btnExportLog.addEventListener('click', exportFullRun);
  elements.btnSaveEvaluation.addEventListener('click', saveEvaluationNotes);

  // Scorecard live calculation
  elements.scoreSelects.forEach((sel) => {
    sel.addEventListener('change', calculateOverallScore);
  });

  // Close key banner
  elements.btnCloseKeyAlert.addEventListener('click', () => {
    elements.keyAlertBanner.classList.add('hidden');
  });

  // Quick chips in idle state
  document.querySelectorAll('.chip-btn').forEach((chip) => {
    chip.addEventListener('click', () => {
      const presetId = chip.dataset.presetId;
      selectPreset(presetId);
    });
  });
}

/* ==========================================================================
   Server Health & Configuration Check
   ========================================================================== */
async function checkHealth() {
  try {
    const res = await fetch('/api/health');
    if (!res.ok) throw new Error('Health check endpoint responded with error');
    const data = await res.json();

    if (data.hasApiKey) {
      elements.statusDot.className = 'status-dot success';
      elements.statusLabel.textContent = 'River API Ready';
      elements.keyAlertBanner.classList.add('hidden');
    } else {
      elements.statusDot.className = 'status-dot warning';
      elements.statusLabel.textContent = 'API Key Required (.env)';
      elements.keyAlertBanner.classList.remove('hidden');
    }

    if (data.defaultModel && !elements.modelInput.value) {
      elements.modelInput.value = data.defaultModel;
    }
  } catch (err) {
    elements.statusDot.className = 'status-dot error';
    elements.statusLabel.textContent = 'Server Offline';
    console.error('Health check failed:', err);
  }
}

/* ==========================================================================
   Load & Display Presets
   ========================================================================== */
async function loadPresets() {
  try {
    const res = await fetch('/api/presets');
    const data = await res.json();
    state.presets = data.presets || [];
    elements.presetCount.textContent = `${state.presets.length} Scenarios`;
    renderPresetList(state.presets);

    // Select first preset by default
    if (state.presets.length > 0) {
      selectPreset(state.presets[0].id);
    }
  } catch (err) {
    elements.presetList.innerHTML = `<div class="preset-loading" style="color: var(--accent-red);">Failed to load presets.</div>`;
    console.error('Failed to load presets:', err);
  }
}

function renderPresetList(presets) {
  elements.presetList.innerHTML = '';

  const badgeClassMap = {
    'Vitals': 'badge-vitals',
    'Metabolic': 'badge-metabolic',
    'Analytics': 'badge-analytics',
    'Pharmacology': 'badge-pharmacology',
    'Diagnostic Ambiguity': 'badge-ambiguity',
    'Triage & Safety': 'badge-triage',
    'Physiology': 'badge-physiology',
    'Structured Data': 'badge-structured',
  };

  presets.forEach((preset) => {
    const item = document.createElement('div');
    item.className = 'preset-item';
    item.dataset.presetId = preset.id;
    item.role = 'option';

    const badgeClass = badgeClassMap[preset.categoryBadge] || 'badge-vitals';

    item.innerHTML = `
      <div class="preset-meta-row">
        <span class="preset-badge ${badgeClass}">${preset.categoryBadge}</span>
        <span class="preset-format-indicator">${preset.responseFormat === 'json_object' ? '{ JSON }' : 'TEXT'}</span>
      </div>
      <div class="preset-title">${escapeHtml(preset.title)}</div>
      <div class="preset-desc">${escapeHtml(preset.description)}</div>
    `;

    item.addEventListener('click', () => selectPreset(preset.id));
    elements.presetList.appendChild(item);
  });
}

function selectPreset(presetId) {
  const preset = state.presets.find((p) => p.id === presetId);
  if (!preset) return;

  state.activePresetId = presetId;

  // Highlight active card in sidebar
  document.querySelectorAll('.preset-item').forEach((el) => {
    el.classList.toggle('active', el.dataset.presetId === presetId);
  });

  // Populate form fields
  elements.userPromptInput.value = preset.userPrompt;
  elements.systemPromptInput.value = preset.systemPrompt;
  elements.responseFormatSelect.value = preset.responseFormat;
  elements.tempSlider.value = preset.defaultTemperature.toFixed(2);
  elements.tempVal.textContent = preset.defaultTemperature.toFixed(2);
  elements.maxTokensInput.value = preset.defaultMaxTokens;
  elements.tokensVal.textContent = preset.defaultMaxTokens;

  // Character count
  elements.charCount.textContent = `${preset.userPrompt.length.toLocaleString()} chars`;

  // Render Target Evaluation Criteria
  elements.criteriaItemsList.innerHTML = '';
  preset.clinicalEvaluationCriteria.forEach((criterion) => {
    const li = document.createElement('li');
    li.textContent = criterion;
    elements.criteriaItemsList.appendChild(li);
  });

  showToast(`Loaded: ${preset.title}`, 'info');
}

/* ==========================================================================
   Form Submission & API Request
   ========================================================================== */
async function handleFormSubmit(e) {
  e.preventDefault();

  const prompt = elements.userPromptInput.value.trim();
  if (!prompt) {
    showToast('Please enter a test prompt.', 'error');
    elements.userPromptInput.focus();
    return;
  }

  const model = elements.modelInput.value.trim();
  const systemPrompt = elements.systemPromptInput.value.trim();
  const temperature = parseFloat(elements.tempSlider.value);
  const maxTokens = parseInt(elements.maxTokensInput.value, 10);
  const responseFormat = elements.responseFormatSelect.value;

  // Set loading state
  setExecutionState(true);

  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt,
        systemPrompt,
        model,
        temperature,
        maxTokens,
        responseFormat,
      }),
    });

    const data = await res.json();

    if (!res.ok || !data.success) {
      showErrorState(data);
    } else {
      showSuccessState(data);
    }
  } catch (err) {
    showErrorState({
      error: 'Network Error: Failed to reach the local test server.',
      errorDetails: {
        troubleshootingHint: 'Ensure the river-eval server is running on http://localhost:3001.',
      },
    });
  } finally {
    setExecutionState(false);
  }
}

/* ==========================================================================
   Execution State Management
   ========================================================================== */
function setExecutionState(isExecuting) {
  state.isExecuting = isExecuting;
  elements.btnSubmitEval.disabled = isExecuting;
  elements.submitBtnLabel.textContent = isExecuting ? 'Evaluating...' : 'Run Evaluation';

  if (isExecuting) {
    // Hide idle & error, show loading
    elements.viewIdle.classList.add('hidden');
    elements.viewError.classList.add('hidden');
    elements.tabContents.forEach((t) => t.classList.add('hidden'));
    elements.viewLoading.classList.remove('hidden');

    // Start live stopwatch timer
    state.startTime = performance.now();
    elements.liveTimer.textContent = '0.0 s';
    clearInterval(state.timerInterval);
    state.timerInterval = setInterval(() => {
      const elapsed = ((performance.now() - state.startTime) / 1000).toFixed(1);
      elements.liveTimer.textContent = `${elapsed} s`;
    }, 100);
  } else {
    clearInterval(state.timerInterval);
    elements.viewLoading.classList.add('hidden');
  }
}

function showErrorState(data) {
  elements.viewError.classList.remove('hidden');
  elements.tabContents.forEach((t) => t.classList.add('hidden'));

  elements.errorTitle.textContent = data.errorDetails?.code || 'Inference Error';
  elements.errorMessage.textContent = data.error || 'Failed to complete model evaluation.';
  elements.errorHintText.textContent = data.errorDetails?.troubleshootingHint || 'Check your River AI API key in .env and verify internet access.';

  // Metrics Bar reset
  elements.metricLatency.textContent = data.latencyMs ? `${data.latencyMs} ms` : 'Failed';
  elements.metricPromptTokens.textContent = '—';
  elements.metricCompTokens.textContent = '—';
  elements.metricTotalTokens.textContent = '—';
  elements.metricJsonStatus.textContent = 'Error';

  showToast('Evaluation failed. See error details.', 'error');
}

function showSuccessState(data) {
  state.currentResponse = data;

  // 1. Update Metrics Bar
  elements.metricModel.textContent = data.model;
  elements.metricLatency.textContent = `${data.latencyMs} ms`;
  if (data.usage) {
    elements.metricPromptTokens.textContent = data.usage.promptTokens.toLocaleString();
    elements.metricCompTokens.textContent = data.usage.completionTokens.toLocaleString();
    elements.metricTotalTokens.textContent = data.usage.totalTokens.toLocaleString();
  } else {
    elements.metricPromptTokens.textContent = 'N/A';
    elements.metricCompTokens.textContent = 'N/A';
    elements.metricTotalTokens.textContent = 'N/A';
  }

  // Latency styling
  elements.metricLatency.style.color = data.latencyMs < 2000 ? 'var(--accent-emerald)' : data.latencyMs < 4000 ? 'var(--accent-amber)' : 'var(--accent-red)';

  // JSON Status
  if (data.jsonValid) {
    elements.metricJsonStatus.textContent = 'Valid JSON';
    elements.metricJsonStatus.style.color = 'var(--accent-emerald)';
  } else if (elements.responseFormatSelect.value === 'json_object') {
    elements.metricJsonStatus.textContent = 'Invalid JSON';
    elements.metricJsonStatus.style.color = 'var(--accent-red)';
  } else {
    elements.metricJsonStatus.textContent = 'Plain Text';
    elements.metricJsonStatus.style.color = 'var(--text-secondary)';
  }

  // 2. Render Formatted Output (Tab 1)
  let formattedHtml = '';
  if (data.reasoningContent) {
    formattedHtml += `
      <div class="reasoning-accordion">
        <details class="reasoning-details" open>
          <summary class="reasoning-summary">
            <span>🧠 Model Clinical Reasoning Process</span>
            <span class="reasoning-tag">Thinking Stream</span>
          </summary>
          <div class="reasoning-body">${renderMarkdown(data.reasoningContent)}</div>
        </details>
      </div>
    `;
  }
  formattedHtml += renderMarkdown(data.content || '*(No final text output generated - review reasoning process above or inspect raw API payload)*');
  elements.responseFormattedBody.innerHTML = formattedHtml;

  // 3. Render Raw Inspector (Tab 3)
  elements.rawCodeContent.textContent = JSON.stringify(data.raw || data, null, 2);

  // 4. Render GenUI Card Preview (Tab 2) if JSON detected
  if (data.jsonValid && data.parsedJson) {
    elements.genuiBadgeActive.classList.remove('hidden');
    renderGenUiCard(data.parsedJson);
  } else {
    elements.genuiBadgeActive.classList.add('hidden');
    elements.genuiCardFrame.classList.add('hidden');
    elements.genuiEmptyState.classList.remove('hidden');
  }

  // Switch to GenUI tab if format is json_object, else Rendered Response tab
  if (elements.responseFormatSelect.value === 'json_object' && data.jsonValid) {
    switchTab('tab-genui');
  } else {
    switchTab('tab-formatted');
  }

  showToast('Evaluation completed successfully!', 'success');
}

/* ==========================================================================
   Tab Navigation
   ========================================================================== */
function switchTab(tabId) {
  elements.tabButtons.forEach((btn) => {
    const isActive = btn.dataset.tab === tabId;
    btn.classList.toggle('active', isActive);
    btn.setAttribute('aria-selected', isActive ? 'true' : 'false');
  });

  elements.tabContents.forEach((content) => {
    content.classList.toggle('hidden', content.id !== tabId);
  });
}

/* ==========================================================================
   GenUI Card Rendering (Flutter Mobile Card Mock)
   ========================================================================== */
function renderGenUiCard(json) {
  elements.genuiEmptyState.classList.add('hidden');
  elements.genuiCardFrame.classList.remove('hidden');

  const urgencyRaw = String(json.clinicalClassification?.urgencyLevel || 'moderate').toLowerCase();
  let urgencyClass = 'high';
  if (urgencyRaw.includes('emerg') || urgencyRaw.includes('crit')) urgencyClass = 'emergency';
  else if (urgencyRaw.includes('high') || urgencyRaw.includes('elev')) urgencyClass = 'high';
  else if (urgencyRaw.includes('low') || urgencyRaw.includes('norm')) urgencyClass = 'low';

  const metric = json.metric || {};
  const primaryVal = metric.primaryValue !== undefined ? metric.primaryValue : '—';
  const unit = metric.unit || '';
  const context = metric.context || '';
  const summary = json.summary || 'Clinical observation generated from user telemetry.';
  const guidance = Array.isArray(json.actionableGuidance) ? json.actionableGuidance : [];
  const discussionPoints = Array.isArray(json.doctorDiscussionPoints) ? json.doctorDiscussionPoints : [];
  const disclaimer = json.safetyDisclaimer || 'VitalAI is an experimental health aid, not a diagnostic system.';

  elements.genuiCardFrame.innerHTML = `
    <div class="card-top-bar">
      <span class="card-schema-badge">${escapeHtml(json['$schema'] || 'vitalai:genui:vitals_card')}</span>
      <span class="card-urgency-badge ${urgencyClass}">${escapeHtml(json.clinicalClassification?.urgencyLevel || 'Elevated')}</span>
    </div>

    <div class="card-metric-hero">
      <div class="primary-val">${primaryVal}</div>
      <div class="unit">${escapeHtml(unit)}</div>
      ${context ? `<span class="context-pill">${escapeHtml(context)}</span>` : ''}
    </div>

    <div class="card-section">
      <p style="font-size: 0.9rem; line-height: 1.5; color: #fff;">${escapeHtml(summary)}</p>
    </div>

    ${guidance.length > 0 ? `
      <div class="card-section">
        <h4>Actionable Guidance</h4>
        <ul class="card-guidance-list">
          ${guidance.map((g) => `<li>${escapeHtml(g)}</li>`).join('')}
        </ul>
      </div>
    ` : ''}

    ${discussionPoints.length > 0 ? `
      <div class="card-section">
        <h4>Discussion Points for Doctor</h4>
        <ul class="card-discussion-list">
          ${discussionPoints.map((d) => `<li>${escapeHtml(d)}</li>`).join('')}
        </ul>
      </div>
    ` : ''}

    <div class="card-disclaimer-box">
      🛡️ <strong>Clinical Safety Note:</strong> ${escapeHtml(disclaimer)}
    </div>
  `;
}

/* ==========================================================================
   Scorecard & Clinical Rubric Calculation
   ========================================================================== */
function calculateOverallScore() {
  let total = 0;
  let count = 0;
  elements.scoreSelects.forEach((sel) => {
    total += parseFloat(sel.value);
    count++;
  });

  const avg = count > 0 ? (total / count).toFixed(1) : '5.0';
  elements.overallScoreDisplay.textContent = `${avg} / 5.0`;

  if (avg >= 4.5) {
    elements.overallScoreDisplay.style.color = 'var(--accent-emerald)';
  } else if (avg >= 3.0) {
    elements.overallScoreDisplay.style.color = 'var(--accent-amber)';
  } else {
    elements.overallScoreDisplay.style.color = 'var(--accent-red)';
  }

  return avg;
}

function saveEvaluationNotes() {
  const avg = calculateOverallScore();
  showToast(`Evaluation saved with score ${avg}/5.0`, 'success');
}

function copyScorecardMarkdown() {
  const avg = calculateOverallScore();
  const activePreset = state.presets.find((p) => p.id === state.activePresetId);

  const scores = Array.from(elements.scoreSelects).map((sel) => {
    const dim = sel.dataset.dimension;
    return `- **${dim}**: ${sel.value}/5 (${sel.options[sel.selectedIndex].text})`;
  }).join('\n');

  const notes = elements.evalNotesInput.value.trim() || 'None recorded.';

  const md = `# VitalAI Clinical Model Evaluation Record
- **Date/Time**: ${new Date().toISOString()}
- **Model**: ${elements.modelInput.value}
- **Scenario**: ${activePreset ? activePreset.title : 'Custom Prompt'}
- **Latency**: ${elements.metricLatency.textContent}
- **Token Usage**: ${elements.metricTotalTokens.textContent} total
- **Aggregate Score**: ${avg} / 5.0

## Rubric Breakdown
${scores}

## Qualitative Clinical Notes
${notes}
`;

  navigator.clipboard.writeText(md).then(() => {
    showToast('Scorecard copied as Markdown!', 'success');
  });
}

function exportFullRun() {
  if (!state.currentResponse) {
    showToast('No active response to export.', 'error');
    return;
  }

  const exportPayload = {
    timestamp: new Date().toISOString(),
    scenarioId: state.activePresetId,
    model: elements.modelInput.value,
    temperature: parseFloat(elements.tempSlider.value),
    maxTokens: parseInt(elements.maxTokensInput.value, 10),
    systemPrompt: elements.systemPromptInput.value,
    userPrompt: elements.userPromptInput.value,
    response: state.currentResponse,
    scorecard: {
      scores: Array.from(elements.scoreSelects).reduce((acc, sel) => {
        acc[sel.dataset.dimension] = parseInt(sel.value, 10);
        return acc;
      }, {}),
      overallScore: calculateOverallScore(),
      notes: elements.evalNotesInput.value,
    },
  };

  const blob = new Blob([JSON.stringify(exportPayload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `vitalai-eval-${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);

  showToast('Evaluation export downloaded!', 'success');
}

/* ==========================================================================
   Utility Functions
   ========================================================================== */
function copyResponseContent() {
  if (!state.currentResponse?.content) {
    showToast('No response content to copy.', 'error');
    return;
  }
  navigator.clipboard.writeText(state.currentResponse.content).then(() => {
    showToast('Response copied to clipboard!', 'success');
  });
}

function copyRawJson() {
  if (!elements.rawCodeContent.textContent) return;
  navigator.clipboard.writeText(elements.rawCodeContent.textContent).then(() => {
    showToast('Raw JSON copied to clipboard!', 'success');
  });
}

function showToast(message, type = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${type === 'success' ? '✅' : type === 'error' ? '❌' : 'ℹ️'}</span> ${escapeHtml(message)}`;
  elements.toastContainer.appendChild(toast);
  setTimeout(() => {
    toast.remove();
  }, 3500);
}

function escapeHtml(str) {
  if (typeof str !== 'string') return String(str);
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Minimalist safe markdown renderer for clinical responses
 */
function renderMarkdown(md) {
  if (!md) return '';
  let html = escapeHtml(md);

  // Bold
  html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  // Italic
  html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
  // Inline code
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  // Headers
  html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
  html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
  html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
  // Blockquotes
  html = html.replace(/^\> (.*$)/gim, '<blockquote>$1</blockquote>');
  // Unordered list items
  html = html.replace(/^\s*[-*]\s+(.*$)/gim, '<li>$1</li>');
  html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');
  // Numbered list items
  html = html.replace(/^\s*(\d+)\.\s+(.*$)/gim, '<li>$2</li>');
  // Paragraphs
  html = html.split('\n\n').map((p) => {
    if (p.startsWith('<h') || p.startsWith('<ul>') || p.startsWith('<blockquote>') || p.startsWith('<pre>')) {
      return p;
    }
    return `<p>${p.replace(/\n/g, '<br/>')}</p>`;
  }).join('');

  return html;
}
