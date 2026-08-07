import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../features/settings/presentation/widgets/settings_section.dart';

WidgetbookFolder get settingsStories {
  return WidgetbookFolder(
    name: 'Settings',
    children: [
      WidgetbookComponent(
        name: 'SettingsSection',
        useCases: [
          WidgetbookUseCase(
            name: 'Grouped Settings Tile Section',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SettingsSection(
                    title: 'PREFERENCES & AI CONFIG',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.key_rounded),
                        title: const Text('Gemini API Key'),
                        subtitle: const Text('AIzaSyDemo...'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.auto_awesome_rounded),
                        title: const Text('AI Data Sharing Consent'),
                        subtitle: const Text('Share vitals to generate dynamic insights'),
                        value: true,
                        onChanged: (_) {},
                      ),
                    ],
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
