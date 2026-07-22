import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';

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
    return AlertDialog(
      title: const Text('Gemini API Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your custom Gemini API Key for live AI responses.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              hintText: 'AIzaSy...',
              labelText: 'API Key',
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
