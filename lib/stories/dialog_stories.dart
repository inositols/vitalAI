import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import '../features/patients/presentation/widgets/patient_form_modal.dart';
import '../features/settings/presentation/widgets/api_key_dialog.dart';

WidgetbookFolder get dialogStories {
  return WidgetbookFolder(
    name: 'Dialogs & Modals',
    children: [
      WidgetbookComponent(
        name: 'ApiKeyDialog',
        useCases: [
          WidgetbookUseCase(
            name: 'Gemini API Key Dialog',
            builder: (context) {
              return Center(
                child: ApiKeyDialog(
                  currentApiKey: 'AIzaSyDemoKey12345',
                  onSave: (_) {},
                ),
              );
            },
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'PatientFormModal',
        useCases: [
          WidgetbookUseCase(
            name: 'Add Patient Modal Sheet',
            builder: (context) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PatientFormModal(
                    onSave: (_) {},
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
