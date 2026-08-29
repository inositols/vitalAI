import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';

/// Dynamic GenUI action button allowing inline interactions like navigation, setting reminders, or logging vitals.
class GenUiActionButtonWidget extends StatelessWidget {
  final GenUiActionButtonModel model;

  const GenUiActionButtonWidget({
    super.key,
    required this.model,
  });

  void _handleTap(BuildContext context) {
    final act = model.action.toLowerCase();
    final route = (model.route ?? '').toLowerCase();

    if (act.contains('reminder') || route.contains('reminder')) {
      GenUiActionHandler.setReminder(context, title: model.label);
      return;
    }

    if (act.contains('pdf') || route.contains('pdf') || act.contains('report')) {
      GenUiActionHandler.generatePdfReport(
        context,
        patientName: 'Active Patient',
        summaryText: 'Clinical vital signs summary requested via AI assistant action.',
      );
      return;
    }

    if (act.contains('add') || act.contains('log') || act.contains('record') || route.contains('add-vital')) {
      GenUiActionHandler.logVital(context);
      return;
    }

    // Default route navigation using verified route mapping
    final targetRoute = model.verifiedRoute;
    if (targetRoute == '/add-vital' || targetRoute == '/patients') {
      context.push(targetRoute);
    } else {
      context.go(targetRoute);
    }
  }

  IconData _getIcon() {
    final act = model.action.toLowerCase();
    final route = (model.route ?? '').toLowerCase();

    if (act.contains('reminder') || route.contains('reminder')) return Icons.alarm_add_rounded;
    if (act.contains('pdf') || route.contains('pdf') || act.contains('report')) return Icons.picture_as_pdf_rounded;
    if (act.contains('add') || act.contains('log') || act.contains('record')) return Icons.add_chart_rounded;
    return Icons.arrow_forward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => _handleTap(context),
        icon: Icon(_getIcon(), size: 18),
        label: Text(
          model.label,
          style: AppTypography.labelMedium(color: AppColors.primary),
        ),
      ),
    );
  }
}
