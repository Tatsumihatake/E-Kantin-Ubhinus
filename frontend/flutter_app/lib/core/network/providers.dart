import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final tokenStorageProvider = Provider<TokenStorage>((ref) => const TokenStorage());
