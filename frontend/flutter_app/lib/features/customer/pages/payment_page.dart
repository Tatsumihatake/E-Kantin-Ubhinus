import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/payment_repository.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentModel? _payment;
  bool _loading = true;
  bool _processing = false;
  String? _error;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _resultMessage = null;
    });

    try {
      final payment = await ref.read(paymentRepositoryProvider).start(widget.orderId);

      if (mounted) {
        setState(() => _payment = payment);
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

  Future<void> _simulate({required bool success}) async {
    final payment = _payment;

    if (payment == null) {
      return;
    }

    setState(() {
      _processing = true;
      _resultMessage = null;
    });

    try {
      final result = await ref.read(paymentRepositoryProvider).simulate(payment.id, success: success);

      if (!mounted) {
        return;
      }

      setState(() => _payment = result);

      if (result.isSuccess) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pembayaran berhasil'),
            content: const Text('Simulasi QRIS berhasil. Pesanan diteruskan ke Seller.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Lihat Pesanan'),
              ),
            ],
          ),
        );

        if (mounted) {
          context.pushReplacement('/customer/orders/${widget.orderId}');
        }
      } else {
        setState(() => _resultMessage = 'Pembayaran gagal. Silakan coba lagi.');
      }
    } on ApiException catch (error) {
      setState(() => _resultMessage = error.firstError);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _start, child: const Text('Coba lagi')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pushReplacement('/customer/orders/${widget.orderId}'),
              child: const Text('Lihat pesanan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final payment = _payment!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.science_outlined, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MODE SIMULASI — tidak ada transaksi uang nyata.',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total pembayaran', style: TextStyle(fontSize: 13, color: AppColors.slate600)),
                  StatusBadge(status: payment.status, label: payment.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rupiah(payment.amount),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, size: 130, color: AppColors.slate900),
                    Text(
                      payment.reference ?? 'QRIS',
                      style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Metode: QRIS (Mock)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                payment.qrisPayload ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (_resultMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(_resultMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 20),
        Text('Uji alur pembayaran', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Gunakan tombol simulasi untuk menentukan hasil pembayaran pada prototipe.',
          style: TextStyle(fontSize: 12, color: AppColors.slate600),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _processing || payment.isSuccess ? null : () => _simulate(success: true),
          icon: _processing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: const Text('Simulasi Pembayaran Berhasil'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _processing || payment.isSuccess ? null : () => _simulate(success: false),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Simulasi Pembayaran Gagal'),
        ),
      ],
    );
  }
}
