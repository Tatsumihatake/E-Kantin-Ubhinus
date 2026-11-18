import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/order.dart';

class PaymentRepository {
  PaymentRepository(this._client);

  final ApiClient _client;

  Future<PaymentModel> start(String orderId) async {
    try {
      final response = await _client.dio.post('/orders/$orderId/payments');

      return PaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<PaymentModel> simulate(String paymentId, {required bool success}) async {
    try {
      final response = await _client.dio.post(
        '/payments/$paymentId/simulate-result',
        data: {'result': success ? 'success' : 'failed'},
      );

      return PaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
