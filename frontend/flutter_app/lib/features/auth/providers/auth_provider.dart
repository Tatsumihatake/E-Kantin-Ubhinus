import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../../core/storage/app_session.dart';
import '../../../shared/models/user.dart';
import '../data/auth_repository.dart';

class AuthState {
  const AuthState({this.user, this.token});

  final AppUser? user;
  final String? token;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get isCustomer => user?.role == 'CUSTOMER';
  bool get isSeller => user?.role == 'SELLER';
  bool get isAdmin => user?.role == 'ADMIN';

  String get homePath {
    if (isAdmin) {
      return '/admin/sellers';
    }

    if (isSeller) {
      return '/seller';
    }

    return '/customer/home';
  }

  AuthState copyWith({AppUser? user, String? token, bool clear = false}) {
    if (clear) {
      return const AuthState();
    }

    return AuthState(user: user ?? this.user, token: token ?? this.token);
  }
}

final initialAuthProvider = Provider<AuthState>((ref) => const AuthState());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => ref.read(initialAuthProvider);

  Future<AppUser> login({required String email, required String password}) async {
    final result = await ref.read(authRepositoryProvider).login(email: email, password: password);

    AppSession.token = result.token;
    await ref.read(tokenStorageProvider).save(
          token: result.token,
          userJson: AuthRepository.encodeUser(result.user),
        );

    state = AuthState(user: result.user, token: result.token);

    return result.user;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          password: password,
        );

    AppSession.token = result.token;
    await ref.read(tokenStorageProvider).save(
          token: result.token,
          userJson: AuthRepository.encodeUser(result.user),
        );

    state = AuthState(user: result.user, token: result.token);

    return result.user;
  }

  Future<AppUser> updateProfile({required String name, String? phone}) async {
    final user = await ref.read(authRepositoryProvider).updateProfile(name: name, phone: phone);
    final token = state.token;

    if (token != null) {
      await ref.read(tokenStorageProvider).save(
            token: token,
            userJson: AuthRepository.encodeUser(user),
          );
    }

    state = state.copyWith(user: user);

    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(tokenStorageProvider).clear();
    AppSession.token = null;
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
