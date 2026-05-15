import 'package:flutter/material.dart';
import '../providers/app_state.dart';

class StatusBanner extends StatelessWidget {
  final AppStatus status;
  final String message;
  const StatusBanner({super.key, required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case AppStatus.success:
        bg = cs.tertiary.withOpacity(0.12);
        fg = cs.tertiary;
        icon = Icons.check_circle_rounded;
        break;
      case AppStatus.error:
        bg = cs.error.withOpacity(0.12);
        fg = cs.error;
        icon = Icons.error_rounded;
        break;
      case AppStatus.scanning:
      case AppStatus.syncing:
      case AppStatus.reconnecting:
        bg = cs.primary.withOpacity(0.10);
        fg = cs.primary;
        icon = Icons.sync_rounded;
        break;
      default:
        bg = cs.surfaceVariant;
        fg = Colors.white54;
        icon = Icons.info_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (status == AppStatus.scanning ||
              status == AppStatus.syncing ||
              status == AppStatus.reconnecting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: fg,
                strokeWidth: 2,
              ),
            )
          else
            Icon(icon, color: fg, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: fg, fontSize: 13))),
        ],
      ),
    );
  }
}
