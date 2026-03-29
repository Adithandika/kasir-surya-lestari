import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';

class ProductEditorScreen extends StatefulWidget {
  final Product? productToEdit;

  const ProductEditorScreen({super.key, this.productToEdit});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _stockCtrl;

  late String _selectedCategory;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _costPriceCtrl = TextEditingController(text: p?.costPrice.toInt().toString() ?? '');
    _sellingPriceCtrl = TextEditingController(text: p?.price.toInt().toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '');
    _selectedCategory = p?.category ?? 'Sembako';
    _imagePath = p?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _costPriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final inventory = context.read<InventoryProvider>();
      final name = _nameCtrl.text.trim();
      final barcode = _barcodeCtrl.text.trim();
      final costPrice = double.tryParse(_costPriceCtrl.text.trim()) ?? 0;
      final price = double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

      if (widget.productToEdit == null) {
        final newProduct = Product(
          remoteId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: _selectedCategory,
          price: price,
          costPrice: costPrice,
          stock: stock,
          barcode: barcode,
          imagePath: _imagePath,
        );
        inventory.addProduct(newProduct);
      } else {
        final updatedProduct = widget.productToEdit!.copyWith(
          name: name,
          category: _selectedCategory,
          price: price,
          costPrice: costPrice,
          stock: stock,
          barcode: barcode,
          imagePath: _imagePath,
        );
        inventory.updateProduct(updatedProduct);
      }
      Navigator.of(context).pop();
      ShadToaster.of(context).show(
        ShadToast(
          title: Text(
            widget.productToEdit == null ? 'Produk berhasil ditambah' : 'Perubahan disimpan',
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = p.basename(image.path);
        final String newPath = p.join(directory.path, fileName);
        await File(image.path).copy(newPath);
        setState(() => _imagePath = newPath);
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Pilih Sumber Foto",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSourceCard(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        final directory = await getApplicationDocumentsDirectory();
                        final String fileName = p.basename(image.path);
                        final String newPath = p.join(directory.path, fileName);
                        await File(image.path).copy(newPath);
                        setState(() => _imagePath = newPath);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildSourceCard(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        final directory = await getApplicationDocumentsDirectory();
                        final String fileName = p.basename(image.path);
                        final String newPath = p.join(directory.path, fileName);
                        await File(image.path).copy(newPath);
                        setState(() => _imagePath = newPath);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() => _imagePath = null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                label: const Text("Hapus Foto", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w800)),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final categories = inventory.categories.where((c) => c != 'All').toList();
    if (!categories.contains(_selectedCategory)) {
      categories.add(_selectedCategory);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              badgeLabel: "MANAJEMEN STOK",
              title: widget.productToEdit == null ? "Tambah Produk" : "Edit Produk",
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              actions: [
                _buildSaveButton(),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 80),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: constraintsBasedLayout(categories),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget constraintsBasedLayout(List<String> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _buildPhotoSection().animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
              const SizedBox(height: 32),
              _buildDetailsSection(categories).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildPhotoSection().animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 6,
              child: _buildDetailsSection(categories).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _pickImage,
            child: _imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 56,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Foto Produk Utama",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ketuk untuk mengunggah gambar",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 16),
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03)),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(List<String> categories) {
    return AppCard(
      padding: const EdgeInsets.all(32),
      radius: AppTheme.radiusMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: "Informasi Dasar"),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameCtrl,
            label: 'Nama Produk',
            icon: Icons.inventory_2_rounded,
            validator: (val) =>
                val == null || val.isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: _buildTextField(
                  controller: _barcodeCtrl,
                  label: 'Barcode / SKU',
                  icon: Icons.qr_code_scanner_rounded,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Barcode wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: _buildDropdown(
                  value: _selectedCategory,
                  label: 'Kategori',
                  icon: Icons.category_rounded,
                  items: categories,
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const AppSectionTitle(title: "Harga & Persediaan"),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _costPriceCtrl,
                  label: 'Harga Modal',
                  prefix: 'Rp ',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  controller: _sellingPriceCtrl,
                  label: 'Harga Jual',
                  prefix: 'Rp ',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: _buildTextField(
              controller: _stockCtrl,
              label: 'Stok Saat Ini',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ShadButton(
      onPressed: _save,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 20),
          SizedBox(width: 8),
          Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? prefix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInputLabel(label: label),
        const SizedBox(height: 10),
        ShadInputFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          leading: icon != null ? Icon(icon, size: 18) : (prefix != null ? Text(prefix!, style: TextStyle(color: ShadTheme.of(context).colorScheme.mutedForeground, fontWeight: FontWeight.w700)) : null),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInputLabel(label: label),
        const SizedBox(height: 10),
        ShadSelect<String>(
          initialValue: value,
          onChanged: onChanged,
          options: items.map((c) => ShadOption(value: c, child: Text(c))).toList(),
          selectedOptionBuilder: (ctx, v) => Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }


}
