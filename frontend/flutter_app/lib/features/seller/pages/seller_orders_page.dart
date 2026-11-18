import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/seller_repository.dart';

class SellerOrdersPage extends ConsumerStatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  ConsumerState<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends ConsumerState<SellerOrdersPage> {
  int _tab = 0;
  List<OrderModel> _orders = const [];
  bool _loading = true;
  bool _processing = false;
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
      final orders = await ref.read(sellerRepositoryProvider).orders(tab: _tab == 0 ? 'active' : 'history');

      if (mounted) {
        setState(() => _orders = orders);
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

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _processing = true);

    try {
      await action();
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _reject(OrderModel order) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan penolakan agar Customer memahami.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Contoh: Bahan habis'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _run(() async {
      await ref.read(sellerRepositoryProvider).rejectOrder(
            order.id,
            controller.text.trim().isEmpty ? null : controller.text.trim(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Aktif')),
                ButtonSegment(value: 1, label: Text('Riwayat')),
              ],
              selected: {_tab},
              onSelectionChanged: (value) {
                setState(() => _tab = value.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _orders.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  title: 'Belum ada pesanan',
                                  message: 'Pesanan baru akan muncul di sini.',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) => _orderCard(_orders[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              Expanded(
                child: Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              StatusBadge(status: order.status, label: order.statusLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.canteen?.name ?? 'Kantin'} • ${dateTimeLabel(order.createdAt)}',
            style: const TextStyle(fontSize: 11, color: AppColors.slate600),
          ),
          const Divider(height: 18),
          ...order.items.map(
            (item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} × ${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Text(rupiah(item.subtotal), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                ...item.addons.map(
                  (addon) => Text(
                    '+ ${addon.name}',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                  ),
                ),
              ],
            ),
          ),
          if (order.request != null && order.request!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Catatan: ${order.request}',
                style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
              Text(
                rupiah(order.total),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          if (order.isActive) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _actions(order),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _actions(OrderModel order) {
    switch (order.status) {
      case 'PAID':
        return [
          FilledButton(
            onPressed: _processing ? null : () => _run(() async {
              await ref.read(sellerRepositoryProvider).acceptOrder(order.id);
            }),
            child: const Text('Terima & Masak'),
          ),
          OutlinedButton(
            onPressed: _processing ? null : () => _reject(order),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tolak'),
          ),
        ];
      case 'CONFIRMED':
        return [
          FilledButton(
            onPressed: _processing ? null : () => _run(() async {
              await ref.read(sellerRepositoryProvider).updateOrderStatus(order.id, 'PREPARING');
            }),
            child: const Text('Mulai Masak'),
          ),
        ];
      case 'PREPARING':
        return [
          FilledButton(
            onPressed: _processing ? null : () => _run(() async {
              await ref.read(sellerRepositoryProvider).updateOrderStatus(order.id, 'READY');
            }),
            child: const Text('Siap Diambil'),
          ),
        ];
      case 'READY':
        return [
          FilledButton(
            onPressed: _processing ? null : () => _run(() async {
              await ref.read(sellerRepositoryProvider).updateOrderStatus(order.id, 'COMPLETED');
            }),
            child: const Text('Selesaikan Pesanan'),
          ),
        ];
      default:
        return const [];
    }
  }
}
