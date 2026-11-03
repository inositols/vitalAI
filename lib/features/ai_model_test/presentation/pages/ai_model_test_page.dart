import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/models/clinical_test_scenario.dart';
import '../../domain/models/model_eval_result.dart';
import '../bloc/model_eval_bloc.dart';
import '../bloc/model_eval_event.dart';
import '../bloc/model_eval_state.dart';
import '../widgets/genui_card_preview_widget.dart';

/// Interactive AI Model Evaluation Workbench Page for VitalAI.
/// Allows benchmarking River AI (zai-org/GLM-5.3-Flash) and comparing with Gemini.
class AiModelTestPage extends StatefulWidget {
  const AiModelTestPage({super.key});

  @override
  State<AiModelTestPage> createState() => _AiModelTestPageState();
}

class _AiModelTestPageState extends State<AiModelTestPage> {
  late final TextEditingController _promptController;
  late final TextEditingController _systemPromptController;
  bool _isSystemPromptExpanded = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _systemPromptController = TextEditingController();

    final state = context.read<ModelEvalBloc>().state;
    _promptController.text = state.prompt;
    _systemPromptController.text = state.systemPrompt;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ModelEvalBloc, ModelEvalState>(
      listenWhen: (prev, curr) =>
          prev.prompt != curr.prompt || prev.systemPrompt != curr.systemPrompt,
      listener: (context, state) {
        if (_promptController.text != state.prompt) {
          _promptController.text = state.prompt;
        }
        if (_systemPromptController.text != state.systemPrompt) {
          _systemPromptController.text = state.systemPrompt;
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.biotech_rounded, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 8),
                Text(
                  'AI Model Evaluation',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Configure River AI Connection',
                onPressed: () => _openConfigBottomSheet(context, state),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Prominent Clinical Disclaimer Banner
                _buildDisclaimerBanner(isDark),

                const SizedBox(height: AppSpacing.md),

                // 2. Provider Selector (River AI vs Google Gemini)
                _buildProviderSelector(context, state, isDark),

                const SizedBox(height: AppSpacing.md),

                // 3. Clinical Scenario Preset Chips
                _buildScenarioChips(context, state, isDark),

                const SizedBox(height: AppSpacing.md),

                // 4. Target Objectives Checklist for Active Scenario
                if (state.selectedScenario != null)
                  _buildObjectivesCard(state.selectedScenario!, isDark),

                const SizedBox(height: AppSpacing.md),

                // 5. Prompt & System Prompt Editor
                _buildPromptEditor(context, state, isDark),

                const SizedBox(height: AppSpacing.md),

                // 6. Action Execution Bar
                _buildExecutionControls(context, state),

                const SizedBox(height: AppSpacing.lg),

                // 7. Loading / Error / Results Section
                if (state.isLoading)
                  _buildLoadingCard(isDark)
                else if (state.errorMessage != null && state.result == null)
                  _buildErrorCard(state.errorMessage!, isDark)
                else if (state.result != null)
                  _buildResultView(context, state.result!, isDark),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Disclaimer banner highlighting experimental, non-diagnostic fictional benchmark
  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glucoseVital.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glucoseVital.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.glucoseVital, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'EXPERIMENTAL HEALTH BENCHMARK • FICTIONAL TEST DATA • NOT A DIAGNOSTIC DEVICE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppColors.glucoseVital,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Provider Selector Tabs (River AI vs Gemini)
  Widget _buildProviderSelector(BuildContext context, ModelEvalState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildProviderTab(
              context: context,
              label: 'River AI',
              subtitle: 'zai-org/GLM-5.3-Flash',
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFF06B6D4),
              isSelected: state.activeProviderKey == 'river',
              onTap: () => context.read<ModelEvalBloc>().add(const ModelEvalProviderChanged('river')),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildProviderTab(
              context: context,
              label: 'Google Gemini',
              subtitle: 'gemini-3.8-flash',
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.primaryLight,
              isSelected: state.activeProviderKey == 'gemini',
              onTap: () => context.read<ModelEvalBloc>().add(const ModelEvalProviderChanged('gemini')),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTab({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCard : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? iconColor : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted), size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Scenario Chips horizontal scroll
  Widget _buildScenarioChips(BuildContext context, ModelEvalState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TEST SCENARIOS (FICTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            Text(
              '${ClinicalTestScenario.scenarios.length} scenarios',
              style: const TextStyle(fontSize: 11, color: AppColors.primaryLight),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ClinicalTestScenario.scenarios.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final scenario = ClinicalTestScenario.scenarios[index];
              final isSelected = state.selectedScenario?.id == scenario.id;

              return ChoiceChip(
                label: Text(scenario.category),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryLight
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                onSelected: (_) {
                  context.read<ModelEvalBloc>().add(ModelEvalScenarioSelected(scenario));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Target clinical objectives box for active scenario
  Widget _buildObjectivesCard(ClinicalTestScenario scenario, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 16, color: AppColors.tertiaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scenario.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              if (scenario.requestJson)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '{ JSON }',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            scenario.patientContext,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            'Target Clinical Evaluation Criteria:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ...scenario.evaluationObjectives.map(
            (obj) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ ', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      obj,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Prompt & System Prompt Editor
  Widget _buildPromptEditor(BuildContext context, ModelEvalState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible System Prompt Toggle
          InkWell(
            onTap: () => setState(() => _isSystemPromptExpanded = !_isSystemPromptExpanded),
            child: Row(
              children: [
                Icon(
                  _isSystemPromptExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 4),
                const Text(
                  'System Instruction & Clinical Guardrails',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Text(
                  'VitalAI Base',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                ),
              ],
            ),
          ),

          if (_isSystemPromptExpanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _systemPromptController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              onChanged: (val) {
                context.read<ModelEvalBloc>().add(ModelEvalFormUpdated(systemPrompt: val));
              },
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // User Prompt Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Test Health Prompt / Telemetry',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear Prompt',
                onPressed: () {
                  _promptController.clear();
                  context.read<ModelEvalBloc>().add(const ModelEvalFormUpdated(prompt: ''));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promptController,
            maxLines: 6,
            style: const TextStyle(fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Enter clinical question or fictional user telemetry...',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            onChanged: (val) {
              context.read<ModelEvalBloc>().add(ModelEvalFormUpdated(prompt: val));
            },
          ),
        ],
      ),
    );
  }

  /// Execution Buttons
  Widget _buildExecutionControls(BuildContext context, ModelEvalState state) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    context.read<ModelEvalBloc>().add(const ModelEvalExecuteRequested());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  const Icon(Icons.play_arrow_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Evaluate with ${state.activeProviderKey == 'river' ? 'GLM-5.3-Flash' : 'Gemini'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Loading state animation
  Widget _buildLoadingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Querying Model & Measuring Inference...',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Evaluating clinical accuracy, latency, and token stream.',
            style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
          ),
        ],
      ),
    );
  }

  /// Error card with troubleshooting hint
  Widget _buildErrorCard(String error, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Evaluation Error',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  /// Result section displaying metrics, reasoning stream, text response, and GenUI card
  Widget _buildResultView(BuildContext context, ModelEvalResult result, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Summary Bar
        _buildMetricsBar(result, isDark),

        const SizedBox(height: AppSpacing.md),

        // Optional Model Clinical Reasoning Stream (Thinking Process)
        if (result.reasoningContent != null && result.reasoningContent!.isNotEmpty)
          _buildReasoningCard(result.reasoningContent!, isDark),

        const SizedBox(height: AppSpacing.md),

        // If JSON output, render interactive GenUI Card Preview
        if (result.isJson && result.parsedJson != null) ...[
          Text(
            'GENUI CARD PREVIEW (FLUTTER MOCK)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          GenUiCardPreviewWidget(json: result.parsedJson!),
          const SizedBox(height: AppSpacing.md),
        ],

        // Response Body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Model Response',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.model,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                result.content.isNotEmpty ? result.content : '*(No final text generated - review reasoning stream)*',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Raw Response Accordion
        ExpansionTile(
          title: const Text('Raw API Payload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: isDark ? AppColors.darkCard : AppColors.lightContainer,
              child: SelectableText(
                jsonEncode(result.rawResponse ?? {'content': result.content}),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Metrics Bar
  Widget _buildMetricsBar(ModelEvalResult result, bool isDark) {
    Color latencyColor = AppColors.secondary;
    if (result.latencyMs > 4000) {
      latencyColor = AppColors.error;
    } else if (result.latencyMs > 2000) {
      latencyColor = AppColors.glucoseVital;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricPill('LATENCY', '${result.latencyMs} ms', latencyColor),
          _buildMetricPill(
            'TOKENS',
            result.totalTokens != null ? '${result.totalTokens}' : 'N/A',
            AppColors.primaryLight,
          ),
          _buildMetricPill(
            'FORMAT',
            result.isJson ? 'Valid JSON' : 'Text',
            result.isJson ? AppColors.secondary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.lightTextMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }

  /// Expandable clinical reasoning thinking stream
  Widget _buildReasoningCard(String reasoning, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.psychology_outlined, color: Color(0xFFA78BFA), size: 20),
        title: const Text(
          'Model Clinical Reasoning Chain',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFA78BFA)),
        ),
        subtitle: const Text(
          'Internal differential diagnosis & thinking stream',
          style: TextStyle(fontSize: 10.5, color: AppColors.lightTextMuted),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(
              reasoning,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF6B21A8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Connection configuration modal
  void _openConfigBottomSheet(BuildContext context, ModelEvalState state) {
    final proxyController = TextEditingController(text: state.proxyUrl);
    final keyController = TextEditingController(text: state.riverApiKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool localUseProxy = state.useProxy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'River AI Configuration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Use Local Dev Proxy (Recommended)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Routes calls to river-eval proxy. Keeps API key completely outside client app.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: localUseProxy,
                  activeTrackColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setModalState(() => localUseProxy = val),
                ),
                const SizedBox(height: 10),
                if (localUseProxy) ...[
                  const Text('Proxy Server Endpoint URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: proxyController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'http://localhost:3001/api/chat',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ] else ...[
                  const Text('River API Key (Saved in Encrypted Storage)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: keyController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'riv-...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ModelEvalBloc>().add(
                            ModelEvalConfigUpdated(
                              useProxy: localUseProxy,
                              proxyUrl: proxyController.text.trim(),
                              apiKey: keyController.text.trim(),
                            ),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('River AI configuration updated.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Configuration'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
