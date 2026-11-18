import '../../core/utils/formatters.dart';

class FoodCategory {
  const FoodCategory({required this.id, required this.name, this.isActive = true});

  final String id;
  final String name;
  final bool isActive;

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class Canteen {
  const Canteen({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isOpen = false,
    this.openingHours = const {},
    this.products = const [],
    this.productsCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isOpen;
  final Map<String, dynamic> openingHours;
  final List<Product> products;
  final int productsCount;

  factory Canteen.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];

    return Canteen(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isOpen: json['is_open'] as bool? ?? false,
      openingHours: json['opening_hours'] is Map<String, dynamic>
          ? json['opening_hours'] as Map<String, dynamic>
          : const {},
      productsCount: json['products_count'] as int? ?? 0,
      products: rawProducts is List
          ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList()
          : const [],
    );
  }
}

class Addon {
  const Addon({
    required this.id,
    required this.name,
    required this.price,
    this.productId,
    this.selectionRule = 'OPTIONAL',
    this.isAvailable = true,
  });

  final String id;
  final String? productId;
  final String name;
  final double price;
  final String selectionRule;
  final bool isAvailable;

  bool get isRequired => selectionRule == 'REQUIRED';

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id'] as String,
      productId: json['product_id'] as String?,
      name: json['name'] as String? ?? '',
      price: parseMoney(json['price']),
      selectionRule: json['selection_rule'] as String? ?? 'OPTIONAL',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.canteenId = '',
    this.categoryId,
    this.canteen,
    this.category,
    this.addons = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final bool isAvailable;
  final String canteenId;
  final String? categoryId;
  final Canteen? canteen;
  final FoodCategory? category;
  final List<Addon> addons;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawCanteen = json['canteen'];
    final rawCategory = json['category'];
    final rawAddons = json['addons'];

    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: parseMoney(json['price']),
      isAvailable: json['is_available'] as bool? ?? true,
      canteenId: json['canteen_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      canteen: rawCanteen is Map<String, dynamic> ? Canteen.fromJson(rawCanteen) : null,
      category: rawCategory is Map<String, dynamic> ? FoodCategory.fromJson(rawCategory) : null,
      addons: rawAddons is List
          ? rawAddons.whereType<Map<String, dynamic>>().map(Addon.fromJson).toList()
          : const [],
    );
  }
}

class FavoriteItem {
  const FavoriteItem({required this.id, required this.product});

  final String id;
  final Product product;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}
