import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../catalog/data/catalog_repository.dart';

class CanteenDetailPage extends ConsumerStatefulWidget {
  const CanteenDetailPage({super.key, required this.canteenId});

  final String canteenId;

  @override
  ConsumerState<CanteenDetailPage> createState() => _CanteenDetailPageState();
}

class _CanteenDetailPageState extends ConsumerState<CanteenDetailPage> {
  Canteen? _canteen;
  String? _categoryId;
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
      final canteen = await ref.read(catalogRepositoryProvider).canteen(widget.canteenId);

      if (mounted) {
        setState(() => _canteen = canteen);
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
      appBar: AppBar(title: Text(_canteen?.name ?? 'Detail Kantin')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final canteen = _canteen!;
    final categories = <String, FoodCategory>{
      for (final product in canteen.products)
        if (product.category != null) product.category!.id: product.category!,
    };
    final products = _categoryId == null
        ? canteen.products
        : canteen.products.where((product) => product.categoryId == _categoryId).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
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
                        canteen.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: canteen.isOpen ? AppColors.successSoft : AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        canteen.isOpen ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          color: canteen.isOpen ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canteen.description != null && canteen.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(canteen.description!, style: const TextStyle(color: AppColors.slate600, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.slate600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        canteen.openingHours.isEmpty
                            ? 'Jam operasional belum diatur'
                            : canteen.openingHours.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                        style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Menu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _categoryId == null,
                onSelected: (_) => setState(() => _categoryId = null),
              ),
              ...categories.values.map(
                (category) => ChoiceChip(
                  label: Text(category.name),
                  selected: _categoryId == category.id,
                  onSelected: (selected) => setState(() => _categoryId = selected ? category.id : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const EmptyState(
              title: 'Belum ada menu',
              message: 'Kantin ini belum memiliki menu pada kategori tersebut.',
              icon: Icons.restaurant_outlined,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  product: product,
                  onTap: () => context.push('/customer/product/${product.id}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
