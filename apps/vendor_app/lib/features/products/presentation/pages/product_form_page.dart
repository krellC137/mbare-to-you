import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/mbare_data.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Page for adding or editing a product
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({
    super.key,
    this.productId,
  });

  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isLoadingProduct = false;

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploadingImage = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProduct();
    } else {
      _categoryController.text = 'General';
      _unitController.text = 'piece';
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoadingProduct = true);

    final productRepo = ref.read(productRepositoryProvider);
    final result = await productRepo.getProductById(widget.productId!);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading product: ${failure.message}')),
          );
          Navigator.of(context).pop();
        }
      },
      (product) {
        if (mounted) {
          _nameController.text = product.name;
          _descriptionController.text = product.description ?? '';
          _priceController.text = product.price.toString();
          _stockController.text = product.stockQuantity.toString();
          _categoryController.text = product.category;
          _unitController.text = product.unit ?? 'piece';
          setState(() {
            _isAvailable = product.isAvailable;
            _existingImageUrl = product.primaryImage;
            _isLoadingProduct = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String vendorId) async {
    if (_selectedImage == null) return _existingImageUrl;

    setState(() => _isUploadingImage = true);

    try {
      final storageService = ref.read(storageServiceProvider);
      final filePath = 'products/${vendorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await storageService.uploadFile(
        path: filePath,
        file: _selectedImage!,
      );

      if (!mounted) return null;
      setState(() => _isUploadingImage = false);

      return result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return null;
        },
        (url) => url,
      );
    } catch (e) {
      if (!mounted) return null;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Upload image if selected (optional - continue even if upload fails)
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(currentUser.uid);
      // If upload fails, show warning but continue without image
      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload skipped. You can add it later.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      imageUrl = _existingImageUrl;
    }

    final productRepo = ref.read(productRepositoryProvider);

    bool success = false;
    String? errorMessage;

    if (_isEditing) {
      final updateData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'price': double.parse(_priceController.text),
        'stockQuantity': int.parse(_stockController.text),
        'unit': _unitController.text.trim(),
        'isAvailable': _isAvailable,
        'updatedAt': DateTime.now().toIso8601String(),
        if (imageUrl != null) 'images': [imageUrl],
      };
      final result = await productRepo.updateProduct(widget.productId!, updateData);
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => success = true,
      );
    } else {
      final product = ProductModel(
        id: '',
        vendorId: currentUser.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        unit: _unitController.text.trim(),
        isAvailable: _isAvailable,
        isActive: true,
        images: imageUrl != null ? [imageUrl] : [],
        createdAt: DateTime.now(),
      );
      final result = await productRepo.createProduct(product);
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => success = true,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Product updated!' : 'Product added!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.border),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_existingImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to add image (optional)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_isUploadingImage)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),

              // Price and Unit
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        prefixIcon: Icon(Icons.straighten),
                        hintText: 'kg, piece, etc.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Stock
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Availability toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Available for sale'),
                  subtitle: Text(
                    _isAvailable
                        ? 'Product is visible to customers'
                        : 'Product is hidden from customers',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save button
              ElevatedButton(
                onPressed: _isLoading || _isUploadingImage ? null : _saveProduct,
                child: _isLoading || _isUploadingImage
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isEditing ? 'Update Product' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
