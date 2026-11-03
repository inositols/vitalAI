import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';
import '../services/genui_action_handler.dart';

/// GenUI component rendering structured lab analyte test results with reference ranges and PDF export.
class LabResultsCardWidget extends StatelessWidget {
  final GenUiLabResultsModel model;

  const LabResultsCardWidget({
    super.key,
    required this.model,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'critical':
      case 'severe':
        return AppColors.error;
      case 'borderline':
      case 'elevated':
      case 'warning':
        return AppColors.warning;
      case 'low':
        return const Color(0xFF0284C7);
      case 'normal':
      case 'optimal':
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Lab Tube Icon, Panel Name, Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.panelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${model.collectionDate}${model.labProvider != null ? " • ${model.labProvider}" : ""}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Analytes List / Table
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 4,
                        child: Text(
                          'TEST / ANALYTE',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'VALUE',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'REFERENCE',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.8),

                // Analyte Rows
                ...model.analytes.map((analyte) {
                  final statusCol = _statusColor(analyte.status);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFEDF2F7),
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                analyte.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Text(
                                analyte.value,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: analyte.status.toLowerCase() != 'normal' ? statusCol : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                analyte.unit,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  analyte.referenceRange.isNotEmpty ? analyte.referenceRange : analyte.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          if (model.clinicalNote != null && model.clinicalNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              model.clinicalNote!,
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Wrap(
            spacing: 8,
            children: [
              InkWell(
                onTap: () => GenUiActionHandler.exportLabResultsPdf(
                  context,
                  panelName: model.panelName,
                  collectionDate: model.collectionDate,
                  analytes: model.analytes
                      .map((a) => {
                            'name': a.name,
                            'value': '${a.value} ${a.unit}'.trim(),
                            'reference': a.referenceRange,
                            'status': a.status,
                          })
                      .toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Export Lab PDF',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
