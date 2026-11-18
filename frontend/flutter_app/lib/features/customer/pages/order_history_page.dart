import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/order_repository.dart';
import '../widgets/order_card.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  int _tab = 0;
  List<OrderModel> _orders = const [];
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
      final orders = await ref.read(orderRepositoryProvider).list(tab: _tab == 0 ? 'active' : 'finished');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Sedang Berjalan'), icon: Icon(Icons.schedule, size: 16)),
                ButtonSegment(value: 1, label: Text('Selesai'), icon: Icon(Icons.check_circle_outline, size: 16)),
              ],
              selected: {_tab},
              onSelectionChanged: (value) {
                setState(() => _tab = value.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _load)
                      : _orders.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  title: 'Belum ada pesanan',
                                  message: 'Pesanan Anda akan muncul di sini.',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];

                                return OrderCard(
                                  order: order,
                                  onTap: () async {
                                    await context.push('/customer/orders/${order.id}');
                                    _load();
                                  },
                                );
                              },
                            ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Status pesanan diperbarui oleh Seller.',
              style: TextStyle(fontSize: 11, color: AppColors.slate400),
            ),
          ),
        ],
      ),
    );
  }
}
