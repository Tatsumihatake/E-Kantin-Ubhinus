import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/app_session.dart';

class ApiClient {
  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AppSession.token;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  late final Dio dio;

  static ApiException toApiException(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] as String? ?? 'Permintaan gagal diproses.';
      final rawErrors = data['errors'];
      final errors = <String, List<String>>{};

      if (rawErrors is Map<String, dynamic>) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            errors[key] = value.map((item) => item.toString()).toList();
          }
        });
      }

      return ApiException(message, errors: errors);
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }

    return ApiException(error.message ?? 'Terjadi kesalahan pada aplikasi.');
  }
}
