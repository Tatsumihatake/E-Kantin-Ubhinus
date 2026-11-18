import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/favorite_repository.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _canteenId;
  String? _categoryId;
  List<Product> _products = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await ref.read(catalogRepositoryProvider).products(
            q: _search.text.trim(),
            canteenId: _canteenId,
            categoryId: _categoryId,
          );

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

  Future<void> _refreshAll() async {
    ref.invalidate(canteensProvider);
    ref.invalidate(categoriesProvider);
    await _loadProducts();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadProducts);
  }

  Future<void> _toggleFavorite(Product product, Set<String> favorites) async {
    HapticFeedback.selectionClick();

    try {
      final repo = ref.read(favoriteRepositoryProvider);

      if (favorites.contains(product.id)) {
        await repo.remove(product.id);
      } else {
        await repo.add(product.id);
      }

      ref.invalidate(favoritesProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canteensAsync = ref.watch(canteensProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final favorites = favoritesAsync.maybeWhen(
      data: (items) => items.map((item) => item.product.id).toSet(),
      orElse: () => <String>{},
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Halo, selamat datang',
                                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  auth.user?.name ?? 'Customer',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              (auth.user?.name ?? 'C').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _loadProducts(),
                        decoration: InputDecoration(
                          hintText: 'Cari menu atau kantin...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              _loadProducts();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kantin kampus', style: Theme.of(context).textTheme.titleMedium),
                          if (_canteenId != null)
                            TextButton(
                              onPressed: () {
                                setState(() => _canteenId = null);
                                _loadProducts();
                              },
                              child: const Text('Reset'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 104,
                  child: canteensAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('$error', style: const TextStyle(fontSize: 12))),
                    data: (canteens) => ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: canteens.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final canteen = canteens[index];

                        return InkWell(
                          onTap: () => context.push('/customer/canteen/${canteen.id}'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.storefront, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        canteen.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  canteen.isOpen ? 'Buka • Siap pesan' : 'Tutup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: canteen.isOpen ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${canteen.productsCount} menu',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(minHeight: 2),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (categories) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: _categoryId == null,
                              onSelected: (_) {
                                setState(() => _categoryId = null);
                                _loadProducts();
                              },
                            ),
                            ...categories.map(
                              (category) => ChoiceChip(
                                label: Text(category.name),
                                selected: _categoryId == category.id,
                                onSelected: (selected) {
                                  setState(() => _categoryId = selected ? category.id : null);
                                  _loadProducts();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Menu pilihan', style: Theme.of(context).textTheme.titleMedium),
                          Text('${_products.length} item', style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(hasScrollBody: false, child: LoadingView())
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(message: _error!, onRetry: _loadProducts),
                )
              else if (_products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'Menu tidak ditemukan',
                    message: 'Coba kata kunci atau filter lain.',
                    icon: Icons.search_off,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];

                        return ProductCard(
                          product: product,
                          isFavorite: favorites.contains(product.id),
                          onFavorite: () => _toggleFavorite(product, favorites),
                          onTap: () => context.push('/customer/product/${product.id}'),
                        );
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
