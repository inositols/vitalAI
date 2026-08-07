import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../vitals/data/models/vital_record.dart';

class RecentHistoryCard extends StatelessWidget {
  final List<VitalRecord> records;
  final VoidCallback onViewHistory;

  const RecentHistoryCard({
    super.key,
    required this.records,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final displayRecords = records.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent History',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: onViewHistory,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View History',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      AppIcons.chevronRight,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (displayRecords.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Center(
              child: Text(
                'No recent health vitals logged yet',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          ...displayRecords.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _HistoryItemTile(record: r),
              )),
      ],
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  final VitalRecord record;

  const _HistoryItemTile({required this.record});

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day} • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final summaries = <String>[];

    if (record.systolic != null && record.diastolic != null) {
      summaries.add('BP ${record.systolic!.toInt()}/${record.diastolic!.toInt()}');
    }
    if (record.glucoseValue != null) {
      summaries.add('Glucose ${record.glucoseValue!.toInt()}');
    }
    if (record.pulseRate != null) {
      summaries.add('Pulse ${record.pulseRate!.toInt()}');
    }

    final summaryText = summaries.isEmpty ? 'Logged Reading' : summaries.join('  •  ');

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          const Icon(
            AppIcons.vitals,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summaryText,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(record.dateTime),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
