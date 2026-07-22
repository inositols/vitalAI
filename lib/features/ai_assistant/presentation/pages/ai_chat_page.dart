import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../widgets/ai_chat_hero_header.dart';
import '../widgets/ai_consent_view.dart';
import '../widgets/attachment_menu_bottom_sheet.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/smart_suggestions_bar.dart';
import '../widgets/sync_status_badge.dart';
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
    if (text.isNotEmpty) {
      _controller.clear();
      context.read<AiAssistantBloc>().add(AiAssistantSendMessage(text));
    }
  }

  void _replyToMessage(String text) {
    setState(() {
      _controller.text = 'Regarding: "${text.length > 55 ? '${text.substring(0, 52)}...' : text}"\n';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _openVoiceDictationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceDictationModal(
        onTextRecognized: (text) {
          setState(() {
            _controller.text = text;
            _controller.selection = TextSelection.collapsed(offset: text.length);
          });
        },
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttachmentMenuBottomSheet(
        onSelectAttachment: (attachmentText) {
          Navigator.pop(ctx);
          setState(() => _controller.text = attachmentText);
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
        heightFactor: 0.75,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    appBar: AppBar(title: const Text('AI Health Companion')),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (aiState is AiAssistantError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('AI Health Companion')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 12),
                          Text(aiState.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_activePatientId != null) {
                                context.read<AiAssistantBloc>().add(AiAssistantInit(_activePatientId!));
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final loadedState = aiState as AiAssistantLoaded;
                final messages = loadedState.activeConversation.messages;

                return Scaffold(
                  appBar: AppBar(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('AI Health Companion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            SyncStatusBadge(status: loadedState.syncStatus),
                          ],
                        ),
                        Text(activePatient != null ? 'Patient: ${activePatient.name}' : 'No Patient Selected', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    actions: [
                      IconButton(icon: const Icon(Icons.history), tooltip: 'Chat History', onPressed: () => _openConversationHistory(context, loadedState)),
                      IconButton(icon: const Icon(Icons.add), tooltip: 'New Conversation', onPressed: () => context.read<AiAssistantBloc>().add(const AiAssistantNewChat())),
                    ],
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: messages.length + (messages.length <= 1 ? 1 : 0) + (loadedState.isGenerating ? 1 : 0),
                            itemBuilder: (ctx, index) {
                              if (messages.length <= 1 && index == 0) {
                                return AiChatHeroHeader(
                                  patientName: activePatient?.name ?? '',
                                  onSelectPrompt: (prompt) => context.read<AiAssistantBloc>().add(AiAssistantSendMessage(prompt)),
                                );
                              }

                              final msgIndex = messages.length <= 1 ? index - 1 : index;

                              if (msgIndex < messages.length) {
                                final message = messages[msgIndex];
                                return ChatMessageBubble(
                                  message: message,
                                  onQuoteReply: _replyToMessage,
                                  onRetry: () => context.read<AiAssistantBloc>().add(AiAssistantRetryMessage(message.id)),
                                  onRegenerate: () {
                                    if (msgIndex > 0) {
                                      final userPrompt = messages[msgIndex - 1].content;
                                      context.read<AiAssistantBloc>().add(AiAssistantSendMessage(userPrompt));
                                    }
                                  },
                                );
                              }

                              return const ChatTypingIndicator();
                            },
                          ),
                        ),
                        SmartSuggestionsBar(
                          suggestions: loadedState.smartSuggestions,
                          onSelectSuggestion: (query) => context.read<AiAssistantBloc>().add(AiAssistantSendMessage(query)),
                        ),
                        ChatInputBar(
                          controller: _controller,
                          hasInputText: _hasInputText,
                          isGenerating: loadedState.isGenerating,
                          onAttachContext: () => _showAttachmentMenu(context),
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
