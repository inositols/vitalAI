import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/ai_service.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/bloc/settings_state.dart';

/// Interactive chat screen with the Gemini AI health education assistant.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<Map<String, String>> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _chips = [
    "What is normal blood pressure?",
    "What does systolic mean?",
    "Why is fasting glucose high?",
    "Summarize my history context.",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Hi, I am your VitalAI educational assistant. You can ask me questions about your readings, terminology, or trends. How can I help you today?'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, String? patientContext) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final aiService = locator<AiService>();
    final response = await aiService.askAssistant(text, patientContext: patientContext);

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<PatientBloc, PatientState>(
          builder: (context, patientState) {
            final activePatient =
                patientState is PatientLoadSuccess ? patientState.activePatient : null;

            final String patientContext = activePatient != null
                ? "Patient name: ${activePatient.name}, Gender: ${activePatient.gender}, DOB: ${activePatient.dateOfBirth.year}, Notes: ${activePatient.notes}"
                : "No patient context available.";

            // 1. Consent Gate check
            if (!settings.aiConsent) {
              return Scaffold(
                appBar: AppBar(title: const Text('AI Assistant')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI Analysis Consent',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To explain readings, detect health trends, and provide summaries, VitalAI utilizes Gemini to process your records. No records are shared without your consent. Your keys remain secure. We never diagnose or prescribe medication.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Grant AI Consent'),
                          onPressed: () {
                            context.read<SettingsBloc>().add(const AiConsentToggled(true));
                            locator<AiService>().setConsent(true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(title: const Text('AI Health Assistant')),
              body: Column(
                children: [
                  // Quick Action prompt chips
                  if (_messages.length == 1) _buildChipsStrip(patientContext),

                  // Chat list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: Text(
                              msg['text']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),

                  // Message Input Box
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Ask about BP, glucose, or terminology...',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (v) => _sendMessage(v, patientContext),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send, size: 28),
                          onPressed: () => _sendMessage(_controller.text, patientContext),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56), // Large tap target
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChipsStrip(String? patientContext) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _chips.length,
          itemBuilder: (context, index) {
            final prompt = _chips[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text(prompt),
                onPressed: () => _sendMessage(prompt, patientContext),
              ),
            );
          },
        ),
      ),
    );
  }
}
