import '../../core/utils/formatters.dart';
import 'catalog.dart';

class OrderItemAddon {
  const OrderItemAddon({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String name;
  final double price;
  final int quantity;

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) {
    return OrderItemAddon(
      name: json['name'] as String? ?? '',
      price: parseMoney(json['price']),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.addons = const [],
  });

  final String id;
  final String name;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final List<OrderItemAddon> addons;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawAddons = json['addons'];

    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      unitPrice: parseMoney(json['unit_price']),
      quantity: json['quantity'] as int? ?? 1,
      subtotal: parseMoney(json['subtotal']),
      addons: rawAddons is List
          ? rawAddons.whereType<Map<String, dynamic>>().map(OrderItemAddon.fromJson).toList()
          : const [],
    );
  }
}

class StatusHistory {
  const StatusHistory({
    required this.status,
    required this.label,
    this.note,
    this.createdAt,
  });

  final String status;
  final String label;
  final String? note;
  final DateTime? createdAt;

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['new_status'] as String? ?? '',
      label: json['new_status_label'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.total,
    this.subtotal = 0,
    this.isActive = true,
    this.request,
    this.rejectionReason,
    this.canteen,
    this.items = const [],
    this.statusHistory = const [],
    this.createdAt,
  });

  final String id;
  final String status;
  final String statusLabel;
  final double subtotal;
  final double total;
  final bool isActive;
  final String? request;
  final String? rejectionReason;
  final Canteen? canteen;
  final List<OrderItem> items;
  final List<StatusHistory> statusHistory;
  final DateTime? createdAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawCanteen = json['canteen'];
    final rawItems = json['items'];
    final rawHistory = json['status_history'];

    return OrderModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      subtotal: parseMoney(json['subtotal']),
      total: parseMoney(json['total']),
      isActive: json['is_active'] as bool? ?? true,
      request: json['request'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      canteen: rawCanteen is Map<String, dynamic> ? Canteen.fromJson(rawCanteen) : null,
      items: rawItems is List
          ? rawItems.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList()
          : const [],
      statusHistory: rawHistory is List
          ? rawHistory.whereType<Map<String, dynamic>>().map(StatusHistory.fromJson).toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class OrderPreview {
  const OrderPreview({
    required this.product,
    required this.quantity,
    required this.addons,
    required this.unitPrice,
    required this.addonsTotal,
    required this.unitTotal,
    required this.total,
    this.request,
  });

  final Product product;
  final int quantity;
  final List<Addon> addons;
  final double unitPrice;
  final double addonsTotal;
  final double unitTotal;
  final double total;
  final String? request;

  factory OrderPreview.fromJson(Map<String, dynamic> json) {
    final rawAddons = json['addons'];

    return OrderPreview(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      addons: rawAddons is List
          ? rawAddons.whereType<Map<String, dynamic>>().map(Addon.fromJson).toList()
          : const [],
      unitPrice: parseMoney(json['unit_price']),
      addonsTotal: parseMoney(json['addons_total']),
      unitTotal: parseMoney(json['unit_total']),
      total: parseMoney(json['total']),
      request: json['request'] as String?,
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.reference,
    this.qrisPayload,
    this.paidAt,
  });

  final String id;
  final String orderId;
  final String method;
  final double amount;
  final String status;
  final String statusLabel;
  final String? reference;
  final String? qrisPayload;
  final DateTime? paidAt;

  bool get isSuccess => status == 'SUCCESS';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      method: json['method'] as String? ?? 'QRIS',
      amount: parseMoney(json['amount']),
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      reference: json['reference'] as String?,
      qrisPayload: json['qris_payload'] as String?,
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? ''),
    );
  }
}
