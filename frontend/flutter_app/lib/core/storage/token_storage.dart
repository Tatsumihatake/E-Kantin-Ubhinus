import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readUser() => _storage.read(key: _userKey);

  Future<void> save({required String token, required String userJson}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
