import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_loading_indicator.dart';
import '../core/widgets/app_shimmer.dart';
import '../features/ai_assistant/presentation/widgets/sync_status_badge.dart';

WidgetbookFolder get feedbackStories {
  return WidgetbookFolder(
    name: 'Feedback & States',
    children: [
      WidgetbookComponent(
        name: 'AppEmptyState',
        useCases: [
          WidgetbookUseCase(
            name: 'No Vitals Logged Empty State',
            builder: (context) {
              return AppEmptyState(
                icon: Icons.monitor_heart_outlined,
                title: 'No Vitals Recorded',
                message: 'Start tracking your blood pressure, glucose, and heart rate to see AI insights.',
                buttonText: 'Log First Vital',
                onAction: () {},
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppLoadingIndicator',
        useCases: [
          WidgetbookUseCase(
            name: 'Circular Progress Indicator with Label',
            builder: (context) {
              return const Center(
                child: AppLoadingIndicator(
                  label: 'Analyzing health records with Gemini AI...',
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppShimmer',
        useCases: [
          WidgetbookUseCase(
            name: 'Skeleton Shimmer Loading Container',
            builder: (context) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: AppShimmer(
                    width: double.infinity,
                    height: 120,
                    borderRadius: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'SyncStatusBadge',
        useCases: [
          WidgetbookUseCase(
            name: 'Cloud Sync Status Indicators',
            builder: (context) {
              return const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SyncStatusBadge(status: 'Synced'),
                    SizedBox(width: 12),
                    SyncStatusBadge(status: 'Pending'),
                    SizedBox(width: 12),
                    SyncStatusBadge(status: 'Offline'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
