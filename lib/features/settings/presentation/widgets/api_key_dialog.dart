import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ApiKeyDialog extends StatefulWidget {
  final String currentApiKey;
  final Function(String newKey) onSave;

  const ApiKeyDialog({
    super.key,
    required this.currentApiKey,
    required this.onSave,
  });

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.tertiary, size: 24),
          SizedBox(width: 10),
          Text('Gemini API Key'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your custom Gemini API Key for live AI responses and recommendations.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              hintText: 'AIzaSy...',
              labelText: 'API Key',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_apiKeyController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Key'),
        ),
      ],
    );
  }
}
