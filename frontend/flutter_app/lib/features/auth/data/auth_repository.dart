import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../shared/models/user.dart';

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final AppUser user;
  final String token;
}

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data['data'] as Map<String, dynamic>;

      return AuthResult(
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
        token: data['token'] as String,
      );
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final data = response.data['data'] as Map<String, dynamic>;

      return AuthResult(
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
        token: data['token'] as String,
      );
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<AppUser> updateProfile({required String name, String? phone}) async {
    try {
      final response = await _client.dio.patch('/auth/profile', data: {
        'name': name,
        'phone': phone,
      });

      return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.toApiException(error);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException {
      // Token may already be revoked; local state is cleared regardless.
    }
  }

  static String encodeUser(AppUser user) => jsonEncode(user.toJson());

  static AppUser? decodeUser(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
