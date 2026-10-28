import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/design_tokens.dart';
import '../models/genui_component_model.dart';

/// GenUI component rendering a clinical risk score gauge with contributing factors and guidance.
class RiskGaugeCardWidget extends StatelessWidget {
  final GenUiRiskGaugeModel model;

  const RiskGaugeCardWidget({
    super.key,
    required this.model,
  });

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;
      case 'moderate':
      case 'medium':
      case 'elevated':
        return AppColors.warning;
      case 'low':
      case 'optimal':
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _riskColor(model.riskLevel);
    final clampedPercent = (model.scorePercentage / 100.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shield Icon, Title, Risk Level Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                    ),
                    if (model.categoryDescription.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        model.categoryDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Text(
                  '${model.riskLevel.toUpperCase()} RISK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Visual Gauge Progress Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Probability',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${model.scorePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: clampedPercent,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0% (Low)', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    Text('20% (Moderate)', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    Text('50%+ (High)', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),

          // Contributing Factors
          if (model.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Key Risk Contributors:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            ...model.contributingFactors.map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 6),
                      child: Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
                    ),
                    Expanded(
                      child: Text(
                        factor,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Recommendation Callout
          if (model.recommendation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.recommendation,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Wrap(
            spacing: 8,
            children: [
              InkWell(
                onTap: () => context.push('/charts'),
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
                      Icon(Icons.insights_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'View Trend Analytics',
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
