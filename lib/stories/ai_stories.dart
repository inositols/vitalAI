import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/genui/models/genui_component_model.dart';
import '../core/genui/widgets/genui_educational_tip.dart';
import '../core/genui/widgets/genui_metric_summary_card.dart';
import '../features/ai_assistant/data/models/chat_message.dart';
import '../features/ai_assistant/presentation/widgets/chat_message_bubble.dart';

WidgetbookFolder get aiStories {
  return WidgetbookFolder(
    name: 'AI Components',
    children: [
      WidgetbookComponent(
        name: 'ChatMessageBubble',
        useCases: [
          WidgetbookUseCase(
            name: 'AI Response Bubble',
            builder: (context) {
              final msg = ChatMessage(
                id: '1',
                conversationId: 'conv_1',
                sender: 'assistant',
                content: 'Your average blood pressure over the past 14 days is 120/80 mmHg.',
                timestamp: DateTime.now(),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChatMessageBubble(message: msg),
                ],
              );
            },
          ),
          WidgetbookUseCase(
            name: 'User Message Bubble',
            builder: (context) {
              final msg = ChatMessage(
                id: '2',
                conversationId: 'conv_1',
                sender: 'user',
                content: 'What does SpO2 mean?',
                timestamp: DateTime.now(),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ChatMessageBubble(message: msg),
                ],
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'GenUI Cards',
        useCases: [
          WidgetbookUseCase(
            name: 'Metric Summary Card',
            builder: (context) {
              const model = GenUiMetricSummaryModel(
                type: 'metric_summary',
                title: 'Fasting Blood Glucose',
                value: '95',
                unit: 'mg/dL',
                status: 'Optimal',
                subtitle: 'Measured 8 hours post-meal',
              );

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GenUiMetricSummaryCard(model: model),
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Educational Tip Card',
            builder: (context) {
              const model = GenUiEducationalTipModel(
                type: 'education_card',
                title: 'Hydration & Blood Pressure',
                definition: 'Staying properly hydrated helps maintain optimal blood volume and vessel pressure.',
              );

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GenUiEducationalTipWidget(model: model),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
