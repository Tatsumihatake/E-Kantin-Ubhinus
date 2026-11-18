import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      'PAID' || 'CONFIRMED' || 'PREPARING' || 'PENDING' => (
          AppColors.warningSoft,
          AppColors.warning,
          Icons.schedule,
        ),
      'READY' => (AppColors.infoSoft, AppColors.info, Icons.notifications_active_outlined),
      'COMPLETED' || 'SUCCESS' => (AppColors.successSoft, AppColors.success, Icons.check_circle_outline),
      'REJECTED' || 'CANCELLED' || 'FAILED' || 'EXPIRED' => (
          AppColors.dangerSoft,
          AppColors.danger,
          Icons.cancel_outlined,
        ),
      _ => (AppColors.slate100, AppColors.slate600, Icons.hourglass_empty),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
