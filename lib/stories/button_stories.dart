import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../core/widgets/app_button.dart';

WidgetbookFolder get buttonStories {
  return WidgetbookFolder(
    name: 'Buttons',
    children: [
      WidgetbookComponent(
        name: 'AppButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Primary Button',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppButton(
                    label: 'Save Vital Record',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Outlined Secondary Button',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppButton(
                    label: 'Export PDF Summary',
                    isOutlined: true,
                    onPressed: () {},
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
