import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../models/catalog.dart';
import 'food_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
  });

  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodImage(url: product.imageUrl, height: double.infinity),
                    if (!product.isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Tidak tersedia',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (onFavorite != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          tooltip: isFavorite ? 'Hapus dari Favorite' : 'Tambah ke Favorite',
                          onPressed: onFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.canteen?.name ?? 'Kantin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rupiah(product.price),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
