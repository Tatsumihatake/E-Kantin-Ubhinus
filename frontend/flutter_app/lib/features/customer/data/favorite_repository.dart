import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/catalog.dart';

class FavoriteRepository {
  FavoriteRepository(this._client);

  final ApiClient _client;

  Future<List<FavoriteItem>> list() async {
    try {
      final response = await _client.dio.get('/favorites');
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(FavoriteItem.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<void> add(String productId) async {
    try {
      await _client.dio.post('/favorites', data: {'product_id': productId});
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<void> remove(String productId) async {
    try {
      await _client.dio.delete('/favorites/$productId');
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepository(ref.watch(apiClientProvider)),
);

final favoritesProvider = FutureProvider<List<FavoriteItem>>(
  (ref) => ref.watch(favoriteRepositoryProvider).list(),
);
