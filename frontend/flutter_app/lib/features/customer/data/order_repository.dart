import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/order.dart';

class OrderRepository {
  OrderRepository(this._client);

  final ApiClient _client;

  Future<OrderPreview> preview({
    required String productId,
    required int quantity,
    required List<String> addonIds,
    String? request,
  }) async {
    try {
      final response = await _client.dio.post('/orders/preview', data: {
        'product_id': productId,
        'quantity': quantity,
        'addon_ids': addonIds,
        'request': request,
      });

      return OrderPreview.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<OrderModel> create({
    required String productId,
    required int quantity,
    required List<String> addonIds,
    String? request,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.dio.post('/orders', data: {
        'product_id': productId,
        'quantity': quantity,
        'addon_ids': addonIds,
        'request': request,
        'idempotency_key': idempotencyKey,
      });

      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<List<OrderModel>> list({String? tab}) async {
    try {
      final response = await _client.dio.get('/orders', queryParameters: {
        'tab': ?tab,
        'per_page': 50,
      });
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<OrderModel> show(String id) async {
    try {
      final response = await _client.dio.get('/orders/$id');

      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);
