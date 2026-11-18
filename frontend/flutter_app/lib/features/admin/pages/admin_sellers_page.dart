import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/seller_account.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_repository.dart';

class AdminSellersPage extends ConsumerStatefulWidget {
  const AdminSellersPage({super.key});

  @override
  ConsumerState<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends ConsumerState<AdminSellersPage> {
  final _search = TextEditingController();
  List<SellerAccount> _sellers = const [];
  String _status = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sellers = await ref.read(adminRepositoryProvider).sellers(
            q: _search.text.trim(),
            status: _status,
          );

      if (mounted) {
        setState(() => _sellers = sellers);
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

  Future<void> _openForm({SellerAccount? seller}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SellerFormDialog(seller: seller),
    );

    if (payload == null) {
      return;
    }

    try {
      final repo = ref.read(adminRepositoryProvider);

      if (seller == null) {
        await repo.create(payload);
      } else {
        await repo.update(seller.id, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(seller == null ? 'Akun Seller dibuat.' : 'Akun Seller diperbarui.')),
        );
      }

      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  Future<void> _toggleActivation(SellerAccount seller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(seller.isActive ? 'Nonaktifkan akun?' : 'Aktifkan akun?'),
        content: Text(
          seller.isActive
              ? '${seller.name} tidak akan dapat mengakses area Seller.'
              : '${seller.name} akan kembali dapat mengakses area Seller.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: seller.isActive ? AppColors.danger : AppColors.success,
            ),
            child: Text(seller.isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).setActivation(seller.id, !seller.isActive);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Manajemen Seller'),
                  actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
                ),
          drawer: isDesktop ? null : Drawer(child: _sidebar(context)),
          body: Row(
            children: [
              if (isDesktop) SizedBox(width: 250, child: _sidebar(context)),
              Expanded(child: _content(isDesktop)),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebar(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('E-Kantin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              selected: true,
              selectedTileColor: AppColors.primaryContainer,
              leading: const Icon(Icons.group_outlined, color: AppColors.primary),
              title: const Text('Manajemen Seller', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              onTap: () {},
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDesktop) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Seller',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kelola akun dan akses Seller. Admin tidak mengubah menu atau pesanan.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate600),
                      ),
                    ],
                  ),
                ),
                if (isDesktop)
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Tambah Seller'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, email, atau kantin...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _load),
                      ),
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('Semua')),
                      ButtonSegment(value: 'active', label: Text('Aktif')),
                      ButtonSegment(value: 'inactive', label: Text('Nonaktif')),
                    ],
                    selected: {_status},
                    onSelectionChanged: (value) {
                      setState(() => _status = value.first);
                      _load();
                    },
                  ),
                  if (!isDesktop)
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Tambah'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ErrorState(message: _error!, onRetry: _load)
            else if (_sellers.isEmpty)
              const EmptyState(
                title: 'Seller tidak ditemukan',
                message: 'Ubah kata kunci atau filter status.',
                icon: Icons.group_off_outlined,
              )
            else
              ..._sellers.map((seller) => _sellerCard(seller)),
          ],
        ),
      ),
    );
  }

  Widget _sellerCard(SellerAccount seller) {
    final canteen = seller.canteen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final info = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  seller.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(seller.email, style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
                    const SizedBox(height: 2),
                    Text(
                      canteen == null ? 'Belum ada kantin' : '${canteen.name}${canteen.isOpen ? ' • Buka' : ' • Tutup'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ],
          );

          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: seller.isActive ? AppColors.successSoft : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              seller.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: seller.isActive ? AppColors.success : AppColors.danger,
              ),
            ),
          );

          final actions = Wrap(
            spacing: 6,
            children: [
              OutlinedButton(
                onPressed: () => _openForm(seller: seller),
                child: const Text('Edit'),
              ),
              OutlinedButton(
                onPressed: () => _toggleActivation(seller),
                style: OutlinedButton.styleFrom(
                  foregroundColor: seller.isActive ? AppColors.danger : AppColors.success,
                ),
                child: Text(seller.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: info), badge]),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              badge,
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SellerFormDialog extends StatefulWidget {
  const _SellerFormDialog({this.seller});

  final SellerAccount? seller;

  @override
  State<_SellerFormDialog> createState() => _SellerFormDialogState();
}

class _SellerFormDialogState extends State<_SellerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _canteenName;
  late final TextEditingController _canteenDescription;
  bool _isOpen = false;

  bool get _isEdit => widget.seller != null;

  @override
  void initState() {
    super.initState();
    final seller = widget.seller;
    _name = TextEditingController(text: seller?.name ?? '');
    _email = TextEditingController(text: seller?.email ?? '');
    _phone = TextEditingController(text: seller?.phone ?? '');
    _password = TextEditingController();
    _canteenName = TextEditingController(text: seller?.canteen?.name ?? '');
    _canteenDescription = TextEditingController(text: seller?.canteen?.description ?? '');
    _isOpen = seller?.canteen?.isOpen ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _canteenName.dispose();
    _canteenDescription.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(context, {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
      'canteen_name': _canteenName.text.trim(),
      'canteen_description': _canteenDescription.text.trim().isEmpty ? null : _canteenDescription.text.trim(),
      'is_open': _isOpen,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Seller' : 'Tambah Seller'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama penanggung jawab *'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *'),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Nomor telepon'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Kata sandi baru (opsional)' : 'Kata sandi *',
                    hintText: 'Minimal 8 karakter',
                  ),
                  validator: (value) {
                    if (!_isEdit && (value == null || value.length < 8)) {
                      return 'Kata sandi minimal 8 karakter.';
                    }
                    if (_isEdit && value != null && value.isNotEmpty && value.length < 8) {
                      return 'Kata sandi minimal 8 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _canteenName,
                  decoration: const InputDecoration(labelText: 'Nama kantin *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Nama kantin wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _canteenDescription,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi kantin'),
                ),
                SwitchListTile(
                  value: _isOpen,
                  onChanged: (value) => setState(() => _isOpen = value),
                  title: const Text('Stan buka', style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: Text(_isEdit ? 'Simpan' : 'Buat Akun')),
      ],
    );
  }
}
