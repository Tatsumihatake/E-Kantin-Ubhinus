import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/catalog.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final ApiClient _client;

  Future<List<Canteen>> canteens() async {
    try {
      final response = await _client.dio.get('/canteens');
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(Canteen.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Canteen> canteen(String id) async {
    try {
      final response = await _client.dio.get('/canteens/$id');

      return Canteen.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<List<FoodCategory>> categories() async {
    try {
      final response = await _client.dio.get('/categories');
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(FoodCategory.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<List<Product>> products({String? q, String? canteenId, String? categoryId}) async {
    try {
      final response = await _client.dio.get('/products', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (canteenId != null && canteenId.isNotEmpty) 'canteen_id': canteenId,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        'per_page': 50,
      });
      final data = response.data['data'] as List<dynamic>;

      return data.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<Product> product(String id) async {
    try {
      final response = await _client.dio.get('/products/$id');

      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

final canteensProvider = FutureProvider<List<Canteen>>(
  (ref) => ref.watch(catalogRepositoryProvider).canteens(),
);

final categoriesProvider = FutureProvider<List<FoodCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);
