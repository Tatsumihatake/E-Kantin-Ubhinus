import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/pages/edit_profile_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (user?.name ?? 'C').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Customer',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user?.roleLabel ?? 'Customer',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => showEditProfileDialog(
              context,
              initialName: user?.name ?? '',
              initialPhone: user?.phone,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: 16),
          _tile(Icons.phone_outlined, 'Nomor telepon', user?.phone ?? 'Belum diisi'),
          _tile(Icons.badge_outlined, 'Status akun', user?.isActive == true ? 'Aktif' : 'Nonaktif'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email digunakan sebagai identitas login dan belum dapat diubah pada prototipe.',
                    style: TextStyle(fontSize: 11, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar Akun'),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.slate600),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate600))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
