import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/pages/edit_profile_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/seller_repository.dart';

class SellerCanteenPage extends ConsumerStatefulWidget {
  const SellerCanteenPage({super.key});

  @override
  ConsumerState<SellerCanteenPage> createState() => _SellerCanteenPageState();
}

class _SellerCanteenPageState extends ConsumerState<SellerCanteenPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  Canteen? _canteen;
  bool _isOpen = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final canteen = await ref.read(sellerRepositoryProvider).canteen();

      if (mounted) {
        setState(() {
          _canteen = canteen;
          _name.text = canteen.name;
          _description.text = canteen.description ?? '';
          _isOpen = canteen.isOpen;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.firstError);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final canteen = await ref.read(sellerRepositoryProvider).updateCanteen({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'is_open': _isOpen,
      });

      if (mounted) {
        setState(() => _canteen = canteen);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informasi kantin disimpan.')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kantin')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primaryContainer,
                              child: const Icon(Icons.storefront, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Seller',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Text(
                                    user?.email ?? '-',
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => showEditProfileDialog(
                          context,
                          initialName: user?.name ?? '',
                          initialPhone: user?.phone,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profil Seller'),
                      ),
                      const SizedBox(height: 16),
                      Text('Informasi Kantin', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nama kantin *'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Nama kantin wajib diisi.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Deskripsi kantin'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _isOpen,
                        onChanged: (value) => setState(() => _isOpen = value),
                        title: const Text('Stan Buka', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _isOpen ? 'Customer dapat memesan.' : 'Customer tidak dapat memesan.',
                          style: const TextStyle(fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Simpan Informasi'),
                      ),
                      const SizedBox(height: 20),
                      if (_canteen != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Menutup stan menghentikan pesanan masuk, berbeda dengan menandai stok produk habis.',
                            style: TextStyle(fontSize: 11, color: AppColors.info),
                          ),
                        ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar Akun'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
