import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/favorite_repository.dart';

class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite')),
      body: favoritesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorState(
          message: error is ApiException ? error.firstError : 'Gagal memuat Favorite.',
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return EmptyState(
              title: 'Belum ada Favorite',
              message: 'Simpan menu favorit agar mudah dipesan kembali.',
              icon: Icons.favorite_border,
              action: FilledButton(
                onPressed: () => context.go('/customer/home'),
                child: const Text('Jelajahi Menu'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];

                return ProductCard(
                  product: favorite.product,
                  isFavorite: true,
                  onFavorite: () async {
                    try {
                      await ref.read(favoriteRepositoryProvider).remove(favorite.product.id);
                      ref.invalidate(favoritesProvider);
                    } on ApiException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
                      }
                    }
                  },
                  onTap: () => context.push('/customer/product/${favorite.product.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
