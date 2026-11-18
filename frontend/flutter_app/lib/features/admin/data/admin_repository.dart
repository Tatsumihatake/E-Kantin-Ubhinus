import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/seller_account.dart';

class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  Future<List<SellerAccount>> sellers({String? q, String? status}) async {
    try {
      final response = await _client.dio.get('/admin/sellers', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (status != null && status != 'all') 'status': status,
        'per_page': 50,
      });
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(SellerAccount.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<SellerAccount> create(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/admin/sellers', data: payload);

      return SellerAccount.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<SellerAccount> update(String sellerId, Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.patch('/admin/sellers/$sellerId', data: payload);

      return SellerAccount.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<SellerAccount> setActivation(String sellerId, bool isActive) async {
    try {
      final response = await _client.dio.patch(
        '/admin/sellers/$sellerId/activation',
        data: {'is_active': isActive},
      );

      return SellerAccount.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(apiClientProvider)),
);
