import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isEmpty ? null : order.items.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.canteen?.name ?? 'Kantin',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  StatusBadge(status: order.status, label: order.statusLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '#${order.id.substring(0, 8).toUpperCase()} • ${dateTimeLabel(order.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.slate600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      firstItem == null ? '-' : '${firstItem.name} × ${firstItem.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    rupiah(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
              if (order.request != null && order.request!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Catatan: ${order.request}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate600, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
