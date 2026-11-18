import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    this.url,
    this.height = 140,
    this.width = double.infinity,
    this.radius = 14,
    this.icon = Icons.restaurant_outlined,
  });

  final String? url;
  final double height;
  final double width;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width,
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(icon, size: 36, color: AppColors.primary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? SizedBox(height: height, width: width, child: placeholder)
          : CachedNetworkImage(
              imageUrl: url!,
              height: height,
              width: width,
              fit: BoxFit.cover,
              placeholder: (context, _) => SizedBox(height: height, width: width, child: placeholder),
              errorWidget: (context, _, _) => SizedBox(height: height, width: width, child: placeholder),
            ),
    );
  }
}
