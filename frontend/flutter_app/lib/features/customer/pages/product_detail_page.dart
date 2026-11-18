import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/food_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/favorite_repository.dart';
import '../data/order_repository.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  final _note = TextEditingController();
  final Set<String> _selectedAddons = {};
  Product? _product;
  int _quantity = 1;
  bool _loading = true;
  bool _submitting = false;
  bool _favorite = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFavorite();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final product = await ref.read(catalogRepositoryProvider).product(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          for (final addon in product.addons.where((addon) => addon.isRequired)) {
            _selectedAddons.add(addon.id);
          }
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

  Future<void> _loadFavorite() async {
    try {
      final favorites = await ref.read(favoriteRepositoryProvider).list();
      final isFavorite = favorites.any((item) => item.product.id == widget.productId);

      if (mounted) {
        setState(() => _favorite = isFavorite);
      }
    } on ApiException {
      // Favorite state is non-blocking for the ordering flow.
    }
  }

  double get _addonTotal {
    final product = _product;

    if (product == null) {
      return 0;
    }

    return product.addons
        .where((addon) => _selectedAddons.contains(addon.id))
        .fold(0, (total, addon) => total + addon.price);
  }

  double get _total => ((_product?.price ?? 0) + _addonTotal) * _quantity;

  Future<void> _toggleFavorite() async {
    HapticFeedback.selectionClick();

    try {
      final repo = ref.read(favoriteRepositoryProvider);

      if (_favorite) {
        await repo.remove(widget.productId);
      } else {
        await repo.add(widget.productId);
      }

      setState(() => _favorite = !_favorite);
      ref.invalidate(favoritesProvider);
    } on ApiException catch (error) {
      _showMessage(error.firstError);
    }
  }

  Future<void> _orderNow() async {
    final product = _product;

    if (product == null) {
      return;
    }

    final missingRequired = product.addons
        .where((addon) => addon.isRequired && !_selectedAddons.contains(addon.id))
        .toList();

    if (missingRequired.isNotEmpty) {
      _showMessage('Lengkapi add-on wajib: ${missingRequired.map((addon) => addon.name).join(', ')}');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    try {
      final preview = await ref.read(orderRepositoryProvider).preview(
            productId: product.id,
            quantity: _quantity,
            addonIds: _selectedAddons.toList(),
            request: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );

      if (mounted) {
        context.push('/customer/confirm', extra: preview);
      }
    } on ApiException catch (error) {
      _showMessage(error.firstError);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Menu'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.primary),
            tooltip: 'Favorite',
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildBody(),
      bottomNavigationBar: _product == null || _loading ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final product = _product!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        FoodImage(url: product.imageUrl, height: 210, radius: 18),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => context.push('/customer/canteen/${product.canteenId}'),
                    child: Text(
                      product.canteen?.name ?? 'Kantin',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              rupiah(product.price),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ],
        ),
        if (product.description != null && product.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(product.description!, style: const TextStyle(color: AppColors.slate600, height: 1.5)),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: product.isAvailable ? AppColors.successSoft : AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.isAvailable ? 'Tersedia dan dapat dipesan' : 'Menu sedang tidak tersedia',
            style: TextStyle(
              color: product.isAvailable ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Jumlah', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);
              },
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            IconButton.filledTonal(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _quantity += 1);
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (product.addons.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Add-on', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...product.addons.map(
            (addon) => CheckboxListTile(
              value: _selectedAddons.contains(addon.id),
              onChanged: addon.isRequired
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedAddons.add(addon.id);
                        } else {
                          _selectedAddons.remove(addon.id);
                        }
                      });
                    },
              title: Text(addon.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${addon.isRequired ? 'Wajib • ' : ''}${rupiah(addon.price)}',
                style: const TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Catatan untuk dapur', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Contoh: jangan terlalu pedas, sambal dipisah',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final product = _product!;
    final disabled = !product.isAvailable || _submitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                  Text(
                    rupiah(_total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: disabled ? null : _orderNow,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(product.isAvailable ? 'Pesan Sekarang' : 'Menu Habis'),
            ),
          ],
        ),
      ),
    );
  }
}
