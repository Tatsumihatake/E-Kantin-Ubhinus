import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/seller_repository.dart';

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> {
  Canteen? _canteen;
  List<OrderModel> _orders = const [];
  bool _loading = true;
  bool _updating = false;
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
      final repo = ref.read(sellerRepositoryProvider);
      final canteen = await repo.canteen();
      final orders = await repo.orders(tab: 'active');

      if (mounted) {
        setState(() {
          _canteen = canteen;
          _orders = orders;
        });
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

  Future<void> _toggleOpen(bool value) async {
    setState(() => _updating = true);

    try {
      final canteen = await ref.read(sellerRepositoryProvider).updateCanteen({'is_open': value});

      if (mounted) {
        setState(() => _canteen = canteen);
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final canteen = _canteen!;
    final newOrders = _orders.where((order) => order.status == 'PAID').length;
    final preparing = _orders.where((order) => order.status == 'PREPARING' || order.status == 'CONFIRMED').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Seller'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Halo, ${user?.name ?? 'Seller'}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(canteen.name, style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canteen.isOpen ? 'Stan Buka' : 'Stan Tutup',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: canteen.isOpen ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canteen.isOpen
                              ? 'Customer dapat membuat pesanan baru.'
                              : 'Pesanan baru dihentikan sementara.',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: canteen.isOpen,
                    onChanged: _updating ? null : _toggleOpen,
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metric('Pesanan baru', '$newOrders', Icons.notifications_active_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metric('Sedang diproses', '$preparing', Icons.soup_kitchen_outlined),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Pesanan aktif', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (_orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'Belum ada pesanan aktif.',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
              )
            else
              ..._orders.take(5).map(
                (order) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.items.isEmpty ? '-' : order.items.first.name} × ${order.items.isEmpty ? 0 : order.items.first.quantity}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: order.status, label: order.statusLabel),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/seller/products'),
                    icon: const Icon(Icons.lunch_dining_outlined),
                    label: const Text('Kelola Produk'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/seller/orders'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Lihat Pesanan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
        ],
      ),
    );
  }
}
