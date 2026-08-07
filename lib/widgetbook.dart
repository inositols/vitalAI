import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'core/design_system/app_theme.dart';
import 'stories/ai_stories.dart';
import 'stories/button_stories.dart';
import 'stories/card_stories.dart';
import 'stories/chart_stories.dart';
import 'stories/dialog_stories.dart';
import 'stories/feedback_stories.dart';
import 'stories/navigation_stories.dart';
import 'stories/settings_stories.dart';

/// Centralized Widgetbook Storybook component catalog app.
class VitalAiWidgetbook extends StatelessWidget {
  const VitalAiWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      appBuilder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: child,
          ),
        );
      },
      directories: [
        buttonStories,
        cardStories,
        chartStories,
        aiStories,
        dialogStories,
        feedbackStories,
        settingsStories,
        navigationStories,
      ],
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light Theme', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Dark Theme', data: AppTheme.darkTheme),
          ],
        ),
      ],
    );
  }
}
