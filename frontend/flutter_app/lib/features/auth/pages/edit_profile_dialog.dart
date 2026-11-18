import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/user.dart';
import '../providers/auth_provider.dart';

Future<AppUser?> showEditProfileDialog(
  BuildContext context, {
  required String initialName,
  String? initialPhone,
}) {
  return showDialog<AppUser>(
    context: context,
    builder: (context) => EditProfileDialog(
      initialName: initialName,
      initialPhone: initialPhone,
    ),
  );
}

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.initialName,
    this.initialPhone,
  });

  final String initialName;
  final String? initialPhone;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = await ref.read(authProvider.notifier).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(user);
      }
    } on ApiException catch (error) {
      setState(() => _error = error.firstError);
    } catch (_) {
      setState(() => _error = 'Profil gagal disimpan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama lengkap *'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon',
                  hintText: 'Contoh: 081234567890',
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 20) {
                    return 'Nomor telepon maksimal 20 karakter.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
