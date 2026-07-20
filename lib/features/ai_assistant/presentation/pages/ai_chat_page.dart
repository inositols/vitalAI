import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/ai_service.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/bloc/settings_state.dart';

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
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString('ai_chat_history');
      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        setState(() {
          _messages.clear();
          for (var item in decoded) {
            _messages.add({
              'role': item['role']?.toString() ?? '',
              'text': item['text']?.toString() ?? '',
            });
          }
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.clear();
          _messages.add({
            'role': 'ai',
            'text':
                'Hi, I am your VitalAI educational assistant. You can ask me questions about your readings, terminology, or trends. How can I help you today?',
          });
        });
      }
    } catch (e) {
      debugPrint("Error loading chat history: $e");
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messagesJson = jsonEncode(_messages);
      await prefs.setString('ai_chat_history', messagesJson);
    } catch (e) {
      debugPrint("Error saving chat history: $e");
    }
  }

  Future<void> _clearHistory() async {
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'ai',
        'text':
            'Hi, I am your VitalAI educational assistant. You can ask me questions about your readings, terminology, or trends. How can I help you today?',
      });
    });
    await _saveMessages();
  }

  Future<void> _deleteMessage(int index) async {
    setState(() {
      if (index >= 0 && index < _messages.length) {
        final role = _messages[index]['role'];
        if (role == 'user' && index + 1 < _messages.length && _messages[index + 1]['role'] == 'ai') {
          _messages.removeAt(index + 1);
          _messages.removeAt(index);
        } else {
          _messages.removeAt(index);
        }

        if (_messages.isEmpty) {
          _messages.add({
            'role': 'ai',
            'text':
                'Hi, I am your VitalAI educational assistant. You can ask me questions about your readings, terminology, or trends. How can I help you today?',
          });
        }
      }
    });
    await _saveMessages();
  }

  void _replyToMessage(String text) {
    setState(() {
      _controller.text = "Regarding: \"${text.length > 55 ? '${text.substring(0, 52)}...' : text}\"\n";
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _showMessageOptions(BuildContext context, int index, String text, String role) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Message Options',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(modalCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (role == 'ai')
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply (Quote)'),
                onTap: () {
                  _replyToMessage(text);
                  Navigator.pop(modalCtx);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Delete Message', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(modalCtx);
                _deleteMessage(index);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text, String? patientContext) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    await _saveMessages();

    final aiService = locator<AiService>();
    final response = await aiService.askAssistant(
      text,
      patientContext: patientContext,
    );

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
    _scrollToBottom();
    await _saveMessages();
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
            final activePatient = patientState is PatientLoadSuccess
                ? patientState.activePatient
                : null;

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
                            context.read<SettingsBloc>().add(
                              const AiConsentToggled(true),
                            );
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
              appBar: AppBar(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'AI Health Assistant',
                      style: theme.appBarTheme.titleTextStyle?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF39D391), // Emerald green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF39D391),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'VitalAI Online',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  if (activePatient != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withOpacity(0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              activePatient.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_messages.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear Chat History',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Clear Chat History?'),
                            content: const Text(
                              'This will permanently delete all messages in this conversation.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  _clearHistory();
                                },
                                child: Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: _messages.length == 1
                        ? _buildWelcomeScreen(context, theme, patientContext)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isUser = msg['role'] == 'user';
                              final text = msg['text']!;
                              final role = msg['role']!;

                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: _AnimatedChatBubble(
                                  isUser: isUser,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Row(
                                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isUser) ...[
                                          Container(
                                            width: 32,
                                            height: 32,
                                            margin: const EdgeInsets.only(right: 10, top: 4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.tertiary,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                        Flexible(
                                          child: GestureDetector(
                                            onLongPress: () => _showMessageOptions(
                                              context,
                                              index,
                                              text,
                                              role,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 14,
                                              ),
                                              decoration: isUser
                                                  ? BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          theme.colorScheme.primary,
                                                          theme.colorScheme.tertiary,
                                                        ],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(20),
                                                        topRight: Radius.circular(20),
                                                        bottomLeft: Radius.circular(20),
                                                        bottomRight: Radius.circular(4),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme.colorScheme.primary.withOpacity(0.12),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                      ],
                                                    )
                                                  : BoxDecoration(
                                                      color: theme.brightness == Brightness.light
                                                          ? Colors.white
                                                          : theme.colorScheme.surfaceVariant.withOpacity(0.25),
                                                      border: Border.all(
                                                        color: theme.colorScheme.outline.withOpacity(0.12),
                                                        width: 1,
                                                      ),
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(20),
                                                        topRight: Radius.circular(20),
                                                        bottomLeft: Radius.circular(4),
                                                        bottomRight: Radius.circular(20),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.01),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.72,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (!isUser) ...[
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'VitalAI',
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: theme.colorScheme.primary,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          width: 3,
                                                          height: 3,
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'Assistant',
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                  ],
                                                  Text(
                                                    text,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: isUser
                                                          ? Colors.white
                                                          : theme.colorScheme.onSurfaceVariant,
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                  if (!isUser) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        _buildBubbleActionIcon(
                                                          icon: Icons.copy_rounded,
                                                          onTap: () {
                                                            Clipboard.setData(ClipboardData(text: text));
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Copied to clipboard'),
                                                                behavior: SnackBarBehavior.floating,
                                                                duration: Duration(seconds: 1),
                                                              ),
                                                            );
                                                          },
                                                          tooltip: 'Copy',
                                                          theme: theme,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _buildBubbleActionIcon(
                                                          icon: Icons.reply_rounded,
                                                          onTap: () => _replyToMessage(text),
                                                          tooltip: 'Quote',
                                                          theme: theme,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _buildBubbleActionIcon(
                                                          icon: Icons.delete_outline_rounded,
                                                          onTap: () => _deleteMessage(index),
                                                          tooltip: 'Delete',
                                                          theme: theme,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isUser) ...[
                                          Container(
                                            width: 32,
                                            height: 32,
                                            margin: const EdgeInsets.only(left: 10, top: 4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.secondary,
                                                  theme.colorScheme.primary,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_isLoading) _buildThinkingIndicator(theme),
                  _buildMessageInput(context, theme, patientContext),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBubbleActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 58, bottom: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.white
              : theme.colorScheme.surfaceVariant.withOpacity(0.25),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _JumpingDotsIndicator(),
            const SizedBox(width: 10),
            Text(
              "VitalAI is thinking...",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, ThemeData theme, String? patientContext) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing AI Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.tertiary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Greeting Title
          Text(
            'How can I assist with your health today?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hi! I am VitalAI, your health assistant. Ask me questions about blood pressure, glucose trends, medical terms, or request a summary of your active record context.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),

          // Quick Action Cards
          Column(
            children: [
              _buildQuickActionCard(
                context,
                theme,
                icon: Icons.favorite_rounded,
                iconColor: theme.colorScheme.primary,
                title: 'Normal Blood Pressure',
                subtitle: 'Learn systolic & diastolic ranges.',
                prompt: 'What is normal blood pressure?',
                patientContext: patientContext,
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                theme,
                icon: Icons.info_outline_rounded,
                iconColor: theme.colorScheme.secondary,
                title: 'What is Systolic?',
                subtitle: 'Understand what blood pressure terms mean.',
                prompt: 'What does systolic mean?',
                patientContext: patientContext,
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                theme,
                icon: Icons.water_drop_rounded,
                iconColor: Colors.orange,
                title: 'Fasting Glucose Ranges',
                subtitle: 'See what causes elevated numbers.',
                prompt: 'Why is fasting glucose high?',
                patientContext: patientContext,
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                theme,
                icon: Icons.history_edu_rounded,
                iconColor: theme.colorScheme.tertiary,
                title: 'Summarize Active Patient',
                subtitle: 'Synthesize logs and trends instantly.',
                prompt: 'Summarize my history context.',
                patientContext: patientContext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String prompt,
    required String? patientContext,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () => _sendMessage(prompt, patientContext),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceVariant.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    String? patientContext,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0, top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.white
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Attach Files Button (Simulated)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              tooltip: 'Attach logs or readings',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Select patient health readings or lab logs to attach (Simulated)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Microphone Button (Simulated Voice input)
            IconButton(
              icon: Icon(
                Icons.mic_none_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              tooltip: 'Voice Input',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listening... Voice synthesis active (Simulated)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const SizedBox(width: 4),

            // Input TextField
            Expanded(
              child: TextFormField(
                controller: _controller,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Ask about BP, glucose, or history...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _sendMessage(v, patientContext);
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            // Gradient Send Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    _sendMessage(_controller.text, patientContext);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Staggered chat bubble entry scale and slide transitions
class _AnimatedChatBubble extends StatefulWidget {
  final Widget child;
  final bool isUser;

  const _AnimatedChatBubble({required this.child, required this.isUser});

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.08 : -0.08, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// Jumping dots thinking state indicator
class _JumpingDotsIndicator extends StatefulWidget {
  const _JumpingDotsIndicator();

  @override
  State<_JumpingDotsIndicator> createState() => _JumpingDotsIndicatorState();
}

class _JumpingDotsIndicatorState extends State<_JumpingDotsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: _controllers[index], curve: Curves.easeInOut),
      );
    });

    _startSequence();
  }

  Future<void> _startSequence() async {
    if (!mounted) return;
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward().then((_) {
          if (mounted) {
            _controllers[i].reverse();
          }
        });
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
