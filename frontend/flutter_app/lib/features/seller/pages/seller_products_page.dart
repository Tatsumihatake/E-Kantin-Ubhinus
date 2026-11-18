import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/food_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/seller_repository.dart';

class SellerProductsPage extends ConsumerStatefulWidget {
  const SellerProductsPage({super.key});

  @override
  ConsumerState<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends ConsumerState<SellerProductsPage> {
  List<Product> _products = const [];
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
      final products = await ref.read(sellerRepositoryProvider).products();

      if (mounted) {
        setState(() => _products = products);
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

  Future<void> _toggleAvailability(Product product, bool value) async {
    try {
      await ref.read(sellerRepositoryProvider).saveProduct(
            productId: product.id,
            name: product.name,
            price: product.price,
            description: product.description,
            categoryId: product.categoryId,
            isAvailable: value,
          );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan produk?'),
        content: Text('${product.name} tidak akan tampil sebagai menu yang dapat dipesan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Nonaktifkan')),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await ref.read(sellerRepositoryProvider).deleteProduct(product.id);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/seller/products/new');
          _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _products.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada produk',
                      message: 'Tambahkan menu pertama untuk kantin Anda.',
                      icon: Icons.lunch_dining_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FoodImage(url: product.imageUrl, width: 70, height: 70, radius: 12),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${product.category?.name ?? 'Tanpa kategori'} • ${rupiah(product.price)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SwitchListTile(
                                              value: product.isAvailable,
                                              onChanged: (value) => _toggleAvailability(product, value),
                                              title: Text(
                                                product.isAvailable ? 'Tersedia' : 'Habis',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Edit',
                                            onPressed: () async {
                                              await context.push('/seller/products/${product.id}/edit', extra: product);
                                              _load();
                                            },
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                          ),
                                          IconButton(
                                            tooltip: 'Nonaktifkan',
                                            onPressed: () => _delete(product),
                                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
