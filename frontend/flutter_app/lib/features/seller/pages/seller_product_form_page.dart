import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/food_image.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/seller_repository.dart';

class SellerProductFormPage extends ConsumerStatefulWidget {
  const SellerProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<SellerProductFormPage> createState() => _SellerProductFormPageState();
}

class _SellerProductFormPageState extends ConsumerState<SellerProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  String? _categoryId;
  bool _isAvailable = true;
  bool _saving = false;
  late final List<Addon> _addons;
  XFile? _image;
  Uint8List? _imageBytes;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _price = TextEditingController(text: product == null ? '' : product.price.toStringAsFixed(0));
    _description = TextEditingController(text: product?.description ?? '');
    _categoryId = product?.categoryId;
    _isAvailable = product?.isAvailable ?? true;
    _addons = List<Addon>.of(product?.addons ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();

    setState(() {
      _image = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _openAddonDialog({Addon? addon}) async {
    final product = widget.product;

    if (product == null) {
      return;
    }

    final result = await showDialog<_AddonDraft>(
      context: context,
      builder: (context) => _AddonDialog(addon: addon),
    );

    if (result == null) {
      return;
    }

    try {
      final repo = ref.read(sellerRepositoryProvider);
      final saved = addon == null
          ? await repo.createAddon(
              product.id,
              name: result.name,
              price: result.price,
              selectionRule: result.selectionRule,
              isAvailable: result.isAvailable,
            )
          : await repo.updateAddon(
              addon.id,
              name: result.name,
              price: result.price,
              selectionRule: result.selectionRule,
              isAvailable: result.isAvailable,
            );

      setState(() {
        final index = _addons.indexWhere((item) => item.id == saved.id);

        if (index >= 0) {
          _addons[index] = saved;
        } else {
          _addons.add(saved);
        }
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  Future<void> _deleteAddon(Addon addon) async {
    try {
      await ref.read(sellerRepositoryProvider).deleteAddon(addon.id);
      setState(() => _addons.removeWhere((item) => item.id == addon.id));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.firstError)));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(sellerRepositoryProvider).saveProduct(
            productId: widget.product?.id,
            name: _name.text.trim(),
            price: double.parse(_price.text.replaceAll('.', '').replaceAll(',', '.')),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            categoryId: _categoryId,
            isAvailable: _isAvailable,
            image: _image,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Produk berhasil diperbarui.' : 'Produk berhasil ditambahkan.')),
        );
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover),
                    )
                  : FoodImage(url: widget.product?.imageUrl, height: 160, icon: Icons.add_a_photo_outlined),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_image == null ? 'Pilih foto produk (maks 2MB)' : 'Ganti foto'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama produk *', hintText: 'Contoh: Nasi Goreng Spesial'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Nama produk wajib diisi.' : null,
            ),
            const SizedBox(height: 14),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories
                    .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga jual *', prefixText: 'Rp '),
              validator: (value) {
                final price = double.tryParse(value?.replaceAll('.', '').replaceAll(',', '.') ?? '');

                if (price == null) {
                  return 'Harga wajib berupa angka.';
                }

                if (price < 0) {
                  return 'Harga tidak boleh negatif.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Deskripsi produk', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Add-on produk', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_isEdit)
                  TextButton.icon(
                    onPressed: () => _openAddonDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
              ],
            ),
            if (!_isEdit)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Simpan produk terlebih dahulu untuk menambahkan add-on.',
                  style: TextStyle(fontSize: 11, color: AppColors.slate600),
                ),
              )
            else if (_addons.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  'Belum ada add-on. Tambahkan pilihan seperti telur atau level pedas.',
                  style: TextStyle(fontSize: 11, color: AppColors.slate600),
                ),
              )
            else
              ..._addons.map(
                (addon) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addon.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              '${addon.isRequired ? 'Wajib' : 'Opsional'} • ${rupiah(addon.price)}${addon.isAvailable ? '' : ' • Tidak tersedia'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openAddonDialog(addon: addon),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        onPressed: () => _deleteAddon(addon),
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
              title: const Text('Status ketersediaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(_isAvailable ? 'Tersedia untuk dipesan' : 'Habis / tidak dapat dipesan'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.success,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => context.pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddonDraft {
  const _AddonDraft({
    required this.name,
    required this.price,
    required this.selectionRule,
    required this.isAvailable,
  });

  final String name;
  final double price;
  final String selectionRule;
  final bool isAvailable;
}

class _AddonDialog extends StatefulWidget {
  const _AddonDialog({this.addon});

  final Addon? addon;

  @override
  State<_AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<_AddonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  String _selectionRule = 'OPTIONAL';
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.addon?.name ?? '');
    _price = TextEditingController(
      text: widget.addon == null ? '' : widget.addon!.price.toStringAsFixed(0),
    );
    _selectionRule = widget.addon?.selectionRule ?? 'OPTIONAL';
    _isAvailable = widget.addon?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      _AddonDraft(
        name: _name.text.trim(),
        price: double.parse(_price.text.replaceAll('.', '').replaceAll(',', '.')),
        selectionRule: _selectionRule,
        isAvailable: _isAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.addon == null ? 'Tambah Add-on' : 'Edit Add-on'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama add-on *'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Nama add-on wajib diisi.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '),
              validator: (value) {
                final price = double.tryParse(value?.replaceAll('.', '').replaceAll(',', '.') ?? '');
                return price == null || price < 0 ? 'Harga tidak valid.' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectionRule,
              decoration: const InputDecoration(labelText: 'Aturan pilihan'),
              items: const [
                DropdownMenuItem(value: 'OPTIONAL', child: Text('Opsional')),
                DropdownMenuItem(value: 'REQUIRED', child: Text('Wajib dipilih')),
              ],
              onChanged: (value) => setState(() => _selectionRule = value ?? 'OPTIONAL'),
            ),
            SwitchListTile(
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
              title: const Text('Tersedia', style: TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.success,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
