import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../data/models/health_context.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../widgets/ai_consent_view.dart';
import '../widgets/attachment_menu_bottom_sheet.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/smart_suggestions_bar.dart';
import '../widgets/voice_dictation_modal.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int? _activePatientId;
  bool _hasInputText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (isNotEmpty != _hasInputText) setState(() => _hasInputText = isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AiAssistantBloc>().add(AiAssistantSendMessage(text));
  }

  void _replyToMessage(String content) {
    setState(() {
      _controller.text = '> $content\n\n';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _openVoiceDictationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceDictationModal(
        onTextRecognized: (spokenText) {
          Navigator.pop(ctx);
          if (spokenText.trim().isNotEmpty) {
            setState(() {
              _controller.text = spokenText;
              _controller.selection = TextSelection.collapsed(offset: spokenText.length);
            });
          }
        },
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, HealthContext? healthContext) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttachmentMenuBottomSheet(
        healthContext: healthContext,
        onSelectAttachment: (attachmentText) {
          Navigator.pop(ctx);
          setState(() {
            _controller.text = attachmentText;
            _controller.selection = TextSelection.collapsed(offset: attachmentText.length);
          });
        },
      ),
    );
  }

  void _openConversationHistory(BuildContext context, AiAssistantLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: ConversationDrawer(
          conversations: state.conversations,
          activeConversationId: state.activeConversation.id,
          onSelectConversation: (id) => context.read<AiAssistantBloc>().add(AiAssistantSelectConversation(id)),
          onDeleteConversation: (id) => context.read<AiAssistantBloc>().add(AiAssistantDeleteConversation(id)),
          onNewChat: () => context.read<AiAssistantBloc>().add(const AiAssistantNewChat()),
          onClearAll: () => context.read<AiAssistantBloc>().add(const AiAssistantClearAll()),
        ),
      ),
    );
  }

  void _openApiKeyDialog(BuildContext context, String currentKey) {
    final textController = TextEditingController(text: currentKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Gemini API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key to enable live AI responses from Gemini 1.5 Flash.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'API Key (AIzaSy...)',
                hintText: 'Paste your Gemini API key here',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newKey = textController.text.trim();
              context.read<SettingsBloc>().add(ApiKeyUpdated(newKey));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Gemini API Key updated successfully! Live AI active.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<PatientBloc, PatientState>(
          builder: (context, patientState) {
            final activePatient = patientState is PatientLoadSuccess ? patientState.activePatient : null;

            if (activePatient != null && _activePatientId != activePatient.id) {
              _activePatientId = activePatient.id;
              context.read<AiAssistantBloc>().add(AiAssistantInit(activePatient.id));
            }

            if (!settings.aiConsent) {
              return AiConsentView(
                onGrantConsent: () => context.read<SettingsBloc>().add(const AiConsentToggled(true)),
              );
            }

            return BlocConsumer<AiAssistantBloc, AiAssistantState>(
              listener: (context, aiState) {
                if (aiState is AiAssistantLoaded) _scrollToBottom();
              },
              builder: (context, aiState) {
                if (aiState is AiAssistantLoading || aiState is AiAssistantInitial) {
                  return Scaffold(
                    backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                    appBar: AppTopBar(
                      title: 'VitalAI',
                      initials: activePatient?.name ?? 'A',
                      onAvatarTap: () => context.go('/settings'),
                    ),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (aiState is AiAssistantError) {
                  return Scaffold(
                    backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                    appBar: AppTopBar(
                      title: 'VitalAI',
                      initials: activePatient?.name ?? 'A',
                      onAvatarTap: () => context.go('/settings'),
                    ),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              aiState.message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry Connection'),
                              onPressed: () {
                                if (_activePatientId != null) {
                                  context.read<AiAssistantBloc>().add(AiAssistantInit(_activePatientId!));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final loadedState = aiState as AiAssistantLoaded;
                final messages = loadedState.activeConversation.messages;

                return Scaffold(
                  backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFE8ECEF),
                  appBar: AppTopBar(
                    title: 'VitalAI',
                    initials: activePatient?.name ?? 'A',
                    onAvatarTap: () => context.go('/settings'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
                          tooltip: 'Chat Sessions',
                          onPressed: () => _openConversationHistory(context, loadedState),
                        ),
                        IconButton(
                          icon: const Icon(Icons.key_rounded, color: Color(0xFF64748B)),
                          tooltip: 'Gemini API Key',
                          onPressed: () => _openApiKeyDialog(context, settings.apiKey),
                        ),
                      ],
                    ),
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            itemCount: messages.length + (loadedState.isGenerating ? 1 : 0),
                            itemBuilder: (ctx, index) {
                              if (index < messages.length) {
                                final message = messages[index];
                                return ChatMessageBubble(
                                  message: message,
                                  onQuoteReply: _replyToMessage,
                                  onRetry: () => context.read<AiAssistantBloc>().add(AiAssistantRetryMessage(message.id)),
                                  onRegenerate: () {
                                    if (index > 0) {
                                      final userPrompt = messages[index - 1].content;
                                      context.read<AiAssistantBloc>().add(AiAssistantSendMessage(userPrompt));
                                    }
                                  },
                                );
                              }

                              return const ChatTypingIndicator();
                            },
                          ),
                        ),
                        // 1. Horizontal Scrollable Suggestion Chips
                        SmartSuggestionsBar(
                          suggestions: loadedState.smartSuggestions,
                          onSelectSuggestion: (query) => context.read<AiAssistantBloc>().add(AiAssistantSendMessage(query)),
                        ),
                        // 2. Pill Input Bar with (+) and Mic
                        ChatInputBar(
                          controller: _controller,
                          hasInputText: _hasInputText,
                          isGenerating: loadedState.isGenerating,
                          onAttachContext: () => _showAttachmentMenu(context, loadedState.healthContext),
                          onVoiceInput: () => _openVoiceDictationModal(context),
                          onSend: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
