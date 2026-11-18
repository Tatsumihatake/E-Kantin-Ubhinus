import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/order.dart';

class SellerRepository {
  SellerRepository(this._client);

  final ApiClient _client;

  Future<Canteen> canteen() async {
    try {
      final response = await _client.dio.get('/seller/canteen');

      return Canteen.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Canteen> updateCanteen(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.patch('/seller/canteen', data: payload);

      return Canteen.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<List<Product>> products() async {
    try {
      final response = await _client.dio.get('/seller/products', queryParameters: {'per_page': 50});
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Product> saveProduct({
    String? productId,
    required String name,
    required double price,
    String? description,
    String? categoryId,
    required bool isAvailable,
    XFile? image,
  }) async {
    try {
      final form = FormData.fromMap({
        'name': name,
        'price': price,
        'description': description,
        'category_id': ?categoryId,
        'is_available': isAvailable ? 1 : 0,
        if (image != null)
          'image': MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: image.name,
          ),
      });

      final response = productId == null
          ? await _client.dio.post('/seller/products', data: form)
          : await _client.dio.post('/seller/products/$productId', data: form..fields.add(const MapEntry('_method', 'PATCH')));

      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Addon> createAddon(
    String productId, {
    required String name,
    required double price,
    required String selectionRule,
    required bool isAvailable,
  }) async {
    try {
      final response = await _client.dio.post('/seller/products/$productId/addons', data: {
        'name': name,
        'price': price,
        'selection_rule': selectionRule,
        'is_available': isAvailable,
      });

      return Addon.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Addon> updateAddon(
    String addonId, {
    required String name,
    required double price,
    required String selectionRule,
    required bool isAvailable,
  }) async {
    try {
      final response = await _client.dio.patch('/seller/addons/$addonId', data: {
        'name': name,
        'price': price,
        'selection_rule': selectionRule,
        'is_available': isAvailable,
      });

      return Addon.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<void> deleteAddon(String addonId) async {
    try {
      await _client.dio.delete('/seller/addons/$addonId');
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _client.dio.delete('/seller/products/$productId');
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<List<OrderModel>> orders({String? tab}) async {
    try {
      final response = await _client.dio.get('/seller/orders', queryParameters: {
        'tab': ?tab,
        'per_page': 50,
      });
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<OrderModel> acceptOrder(String orderId) async {
    return _orderAction('/seller/orders/$orderId/accept');
  }

  Future<OrderModel> rejectOrder(String orderId, String? reason) async {
    return _orderAction('/seller/orders/$orderId/reject', data: {'reason': reason});
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    return _orderAction('/seller/orders/$orderId/status', method: 'PATCH', data: {'status': status});
  }

  Future<OrderModel> _orderAction(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = method == 'PATCH'
          ? await _client.dio.patch(path, data: data)
          : await _client.dio.post(path, data: data);

      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final sellerRepositoryProvider = Provider<SellerRepository>(
  (ref) => SellerRepository(ref.watch(apiClientProvider)),
);
