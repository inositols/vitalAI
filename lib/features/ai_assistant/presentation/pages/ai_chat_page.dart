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
import '../widgets/chat_message_bubble.dart';
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
      if (isNotEmpty != _hasInputText) {
        setState(() => _hasInputText = isNotEmpty);
      }
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

  void _replyToMessage(String text) {
    setState(() {
      _controller.text =
          'Regarding: "${text.length > 55 ? '${text.substring(0, 52)}...' : text}"\n';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
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
            _controller.selection =
                TextSelection.collapsed(offset: text.length);
          });
        },
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach Context Snippet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.favorite, color: Colors.white, size: 20),
                ),
                title: const Text('Attach Blood Pressure Reading'),
                subtitle: const Text('Latest: 124/82 mmHg (Normal)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.text = 'Attached BP Log: 124/82 mmHg. Can you evaluate this reading?';
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.water_drop, color: Colors.white, size: 20),
                ),
                title: const Text('Attach Fasting Glucose Log'),
                subtitle: const Text('Latest: 105 mg/dL'),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.text = 'Attached Glucose Log: 105 mg/dL fasting. Is this within target range?';
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.medication, color: Colors.white, size: 20),
                ),
                title: const Text('Attach Active Prescription'),
                subtitle: const Text('Lisinopril 10mg daily'),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.text = 'Attached Rx: Lisinopril 10mg daily. Are there specific side effects to monitor?';
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openConversationHistory(
    BuildContext context,
    AiAssistantLoaded state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: ConversationDrawer(
          conversations: state.conversations,
          activeConversationId: state.activeConversation.id,
          onSelectConversation: (id) {
            context.read<AiAssistantBloc>().add(
                  AiAssistantSelectConversation(id),
                );
          },
          onDeleteConversation: (id) {
            context.read<AiAssistantBloc>().add(
                  AiAssistantDeleteConversation(id),
                );
          },
          onNewChat: () {
            context.read<AiAssistantBloc>().add(const AiAssistantNewChat());
          },
          onClearAll: () {
            context.read<AiAssistantBloc>().add(const AiAssistantClearAll());
          },
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
            final activePatient = patientState is PatientLoadSuccess
                ? patientState.activePatient
                : null;

            if (activePatient != null && _activePatientId != activePatient.id) {
              _activePatientId = activePatient.id;
              context
                  .read<AiAssistantBloc>()
                  .add(AiAssistantInit(activePatient.id));
            }

            // Consent Gate check
            if (!settings.aiConsent) {
              return Scaffold(
                appBar: AppBar(title: const Text('AI Health Companion')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI Analysis Consent',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To explain readings, detect health trends, and provide summaries, VitalAI uses context-aware models to process your records securely. We never diagnose or prescribe medication without professional consultation.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Grant AI Consent'),
                          onPressed: () {
                            context.read<SettingsBloc>().add(
                                  const AiConsentToggled(true),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return BlocConsumer<AiAssistantBloc, AiAssistantState>(
              listener: (context, aiState) {
                if (aiState is AiAssistantLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, aiState) {
                if (aiState is AiAssistantLoading || aiState is AiAssistantInitial) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('AI Health Companion')),
                    body: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (aiState is AiAssistantError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('AI Health Companion')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 12),
                          Text(aiState.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_activePatientId != null) {
                                context
                                    .read<AiAssistantBloc>()
                                    .add(AiAssistantInit(_activePatientId!));
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
                            Text(
                              'AI Health Companion',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SyncStatusBadge(status: loadedState.syncStatus),
                          ],
                        ),
                        Text(
                          activePatient != null
                              ? 'Patient: ${activePatient.name}'
                              : 'No Patient Selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.history),
                        tooltip: 'Chat History',
                        onPressed: () =>
                            _openConversationHistory(context, loadedState),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'New Conversation',
                        onPressed: () {
                          context
                              .read<AiAssistantBloc>()
                              .add(const AiAssistantNewChat());
                        },
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: messages.length +
                                (messages.length <= 1 ? 1 : 0) +
                                (loadedState.isGenerating ? 1 : 0),
                            itemBuilder: (ctx, index) {
                              if (messages.length <= 1 && index == 0) {
                                return AiChatHeroHeader(
                                  patientName: activePatient?.name ?? '',
                                  onSelectPrompt: (prompt) {
                                    context.read<AiAssistantBloc>().add(
                                          AiAssistantSendMessage(prompt),
                                        );
                                  },
                                );
                              }

                              final msgIndex =
                                  messages.length <= 1 ? index - 1 : index;

                              if (msgIndex < messages.length) {
                                final message = messages[msgIndex];
                                return ChatMessageBubble(
                                  message: message,
                                  onQuoteReply: _replyToMessage,
                                  onRetry: () {
                                    context.read<AiAssistantBloc>().add(
                                          AiAssistantRetryMessage(message.id),
                                        );
                                  },
                                  onRegenerate: () {
                                    if (msgIndex > 0) {
                                      final userPrompt = messages[msgIndex - 1].content;
                                      context.read<AiAssistantBloc>().add(
                                            AiAssistantSendMessage(userPrompt),
                                          );
                                    }
                                  },
                                );
                              }

                              // Gemini Typing Indicator Loader
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.tertiaryContainer,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerHigh,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Analyzing health records...',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Dynamic Suggestions Bar
                        SmartSuggestionsBar(
                          suggestions: loadedState.smartSuggestions,
                          onSelectSuggestion: (query) {
                            context
                                .read<AiAssistantBloc>()
                                .add(AiAssistantSendMessage(query));
                          },
                        ),

                        // Gemini / ChatGPT Floating Glassmorphic Input Bar
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                tooltip: 'Attach Context',
                                onPressed: () => _showAttachmentMenu(context),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 4,
                                  minLines: 1,
                                  decoration: InputDecoration(
                                    hintText: 'Ask Gemini health assistant...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      final text = val.trim();
                                      _controller.clear();
                                      context.read<AiAssistantBloc>().add(
                                            AiAssistantSendMessage(text),
                                          );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (!_hasInputText)
                                IconButton(
                                  icon: Icon(
                                    Icons.mic,
                                    color: theme.colorScheme.primary,
                                  ),
                                  tooltip: 'Voice Input',
                                  onPressed: () =>
                                      _openVoiceDictationModal(context),
                                )
                              else
                                IconButton.filled(
                                  icon: loadedState.isGenerating
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_upward, size: 20),
                                  onPressed: loadedState.isGenerating
                                      ? null
                                      : () {
                                          final text = _controller.text.trim();
                                          if (text.isNotEmpty) {
                                            _controller.clear();
                                            context
                                                .read<AiAssistantBloc>()
                                                .add(
                                                  AiAssistantSendMessage(text),
                                                );
                                          }
                                        },
                                ),
                            ],
                          ),
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
