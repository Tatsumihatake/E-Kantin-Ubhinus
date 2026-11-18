import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/food_image.dart';
import '../data/order_repository.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  const OrderConfirmationPage({super.key, required this.preview});

  final OrderPreview preview;

  @override
  ConsumerState<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage> {
  bool _submitting = false;
  late final String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = 'ui-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _continue() async {
    setState(() => _submitting = true);

    try {
      final order = await ref.read(orderRepositoryProvider).create(
            productId: widget.preview.product.id,
            quantity: widget.preview.quantity,
            addonIds: widget.preview.addons.map((addon) => addon.id).toList(),
            request: widget.preview.request,
            idempotencyKey: _idempotencyKey,
          );

      if (mounted) {
        context.pushReplacement('/customer/payment/${order.id}');
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: ListView(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FoodImage(url: preview.product.imageUrl, width: 76, height: 76, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview.product.canteen?.name ?? 'Kantin',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${rupiah(preview.unitPrice)} × ${preview.quantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (preview.addons.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Add-on', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...preview.addons.map(
                    (addon) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('• ${addon.name}', style: const TextStyle(fontSize: 13))),
                          Text(rupiah(addon.price), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (preview.request != null && preview.request!.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Catatan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(preview.request!, style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
                ],
                const Divider(height: 24),
                _row('Subtotal menu', rupiah(preview.unitPrice * preview.quantity)),
                const SizedBox(height: 6),
                _row('Total add-on', rupiah(preview.addonsTotal * preview.quantity)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      rupiah(preview.total),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Periksa kembali pesanan. Anda dapat kembali mengubah pilihan sebelum membayar.',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => context.pop(),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submitting ? null : _continue,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lanjutkan Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
