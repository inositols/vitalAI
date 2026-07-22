import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final String status; // 'Synced', 'Pending', 'Offline'

  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'synced':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        icon = Icons.sync;
        break;
      case 'offline':
      default:
        bg = theme.colorScheme.onSurface.withValues(alpha: 0.1);
        fg = theme.colorScheme.onSurfaceVariant;
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
