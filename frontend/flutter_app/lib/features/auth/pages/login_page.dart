import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await ref.read(authProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );

      if (mounted) {
        final path = user.isAdmin ? '/admin/sellers' : user.isSeller ? '/seller' : '/customer/home';
        context.go(path);
      }
    } on ApiException catch (error) {
      setState(() => _error = error.firstError);
    } catch (_) {
      setState(() => _error = 'Tidak dapat masuk. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _fill(String email, String password) {
    setState(() {
      _email.text = email;
      _password.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  'E-Kantin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesan makanan kantin kampus tanpa antre.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate600),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.slate200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Masuk ke akun', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('login_email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@kampus.ac.id',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi.';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('login_password'),
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Kata sandi wajib diisi.' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            key: const Key('login_submit'),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(fontSize: 13, color: AppColors.slate600),
                    ),
                    TextButton(
                      key: const Key('login_to_register'),
                      onPressed: _loading ? null : () => context.go('/register'),
                      child: const Text('Daftar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun demo (password: password)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Customer'),
                      onPressed: () => _fill('customer@ekantin.test', 'password'),
                    ),
                    ActionChip(
                      label: const Text('Seller'),
                      onPressed: () => _fill('seller2@ekantin.test', 'password'),
                    ),
                    ActionChip(
                      label: const Text('Admin'),
                      onPressed: () => _fill('admin@ekantin.test', 'password'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
