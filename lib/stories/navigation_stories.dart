import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/widgets/app_section_header.dart';
import '../features/ai_assistant/presentation/widgets/smart_suggestions_bar.dart';

WidgetbookFolder get navigationStories {
  return WidgetbookFolder(
    name: 'Navigation & Headers',
    children: [
      WidgetbookComponent(
        name: 'AppSectionHeader',
        useCases: [
          WidgetbookUseCase(
            name: 'Section Header with Subtitle & Action',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppSectionHeader(
                    title: 'Clinical Vitals',
                    subtitle: 'Real-time blood pressure, glucose & pulse rate',
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'SmartSuggestionsBar',
        useCases: [
          WidgetbookUseCase(
            name: 'AI Quick Prompt Chips Bar',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SmartSuggestionsBar(
                    suggestions: const [
                      'What does SpO₂ mean?',
                      'Is my blood pressure high?',
                      'Summarise my week',
                    ],
                    onSelectSuggestion: (_) {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
