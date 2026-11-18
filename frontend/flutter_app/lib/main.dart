import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/storage/app_session.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  const storage = TokenStorage();
  final token = await storage.readToken();
  final user = AuthRepository.decodeUser(await storage.readUser());

  AppSession.token = token;

  runApp(
    ProviderScope(
      overrides: [
        initialAuthProvider.overrideWithValue(
          AuthState(user: user, token: token),
        ),
      ],
      child: const EKantinApp(),
    ),
  );
}
