import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
      await ref.read(authProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );

      if (mounted) {
        context.go('/customer/home');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.firstError);
    } catch (_) {
      setState(() => _error = 'Tidak dapat mendaftar. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
                  'Buat akun E-Kantin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daftar sebagai Customer dan mulai pesan makanan kantin.',
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
                          Text('Daftar akun baru', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('register_name'),
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              hintText: 'Nama kamu',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama wajib diisi.';
                              }
                              if (value.trim().length > 100) {
                                return 'Nama maksimal 100 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('register_email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
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
                            key: const Key('register_password'),
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              helperText: 'Minimal 8 karakter.',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi.';
                              }
                              if (value.length < 8) {
                                return 'Kata sandi minimal 8 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('register_confirm'),
                            controller: _confirm,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loading ? null : _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi kata sandi',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi.';
                              }
                              if (value != _password.text) {
                                return 'Konfirmasi kata sandi tidak sama.';
                              }
                              return null;
                            },
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
                            key: const Key('register_submit'),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Daftar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(fontSize: 13, color: AppColors.slate600),
                    ),
                    TextButton(
                      key: const Key('register_to_login'),
                      onPressed: _loading ? null : () => context.go('/login'),
                      child: const Text('Masuk'),
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
