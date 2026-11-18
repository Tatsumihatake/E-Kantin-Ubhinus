import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/order_repository.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await ref.read(orderRepositoryProvider).show(widget.orderId);

      if (mounted) {
        setState(() => _order = order);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.firstError);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Muat ulang'),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final order = _order!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  StatusBadge(status: order.status, label: order.statusLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.canteen?.name ?? 'Kantin'} • ${dateTimeLabel(order.createdAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const Divider(height: 24),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Text(rupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      ...item.addons.map(
                        (addon) => Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '+ ${addon.name}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                                ),
                              ),
                              Text(rupiah(addon.price), style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.request != null && order.request!.isNotEmpty) ...[
                const Divider(height: 16),
                Text('Catatan: ${order.request}', style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    rupiah(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
              if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Alasan penolakan: ${order.rejectionReason}',
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
        if (order.status == 'WAITING_PAYMENT') ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/customer/payment/${order.id}');
              _load();
            },
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Bayar Sekarang'),
          ),
        ],
        const SizedBox(height: 20),
        Text('Perjalanan pesanan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (order.statusHistory.isEmpty)
          const Text('Belum ada riwayat status.', style: TextStyle(fontSize: 12, color: AppColors.slate600))
        else
          ...order.statusHistory.asMap().entries.map((entry) {
            final history = entry.value;
            final isLatest = entry.key == order.statusHistory.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isLatest ? AppColors.primary : AppColors.slate200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLatest)
                          Expanded(child: Container(width: 2, color: AppColors.slate200)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18, left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isLatest ? AppColors.slate900 : AppColors.slate600,
                            ),
                          ),
                          if (history.note != null && history.note!.isNotEmpty)
                            Text(
                              history.note!,
                              style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                            ),
                          Text(
                            dateTimeLabel(history.createdAt),
                            style: const TextStyle(fontSize: 10, color: AppColors.slate400),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
