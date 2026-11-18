class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleLabel = '',
    this.phone,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String roleLabel;
  final String? phone;
  final bool isActive;

  bool get isCustomer => role == 'CUSTOMER';
  bool get isSeller => role == 'SELLER';
  bool get isAdmin => role == 'ADMIN';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
      roleLabel: json['role_label'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'role_label': roleLabel,
        'phone': phone,
        'is_active': isActive,
      };
}
