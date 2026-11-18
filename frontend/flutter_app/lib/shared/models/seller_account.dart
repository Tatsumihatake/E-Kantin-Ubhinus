import 'catalog.dart';

class SellerAccount {
  const SellerAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    this.phone,
    this.canteens = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final List<Canteen> canteens;
  final DateTime? createdAt;

  Canteen? get canteen => canteens.isEmpty ? null : canteens.first;

  factory SellerAccount.fromJson(Map<String, dynamic> json) {
    final rawCanteens = json['canteens'];

    return SellerAccount(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      canteens: rawCanteens is List
          ? rawCanteens.whereType<Map<String, dynamic>>().map(Canteen.fromJson).toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
