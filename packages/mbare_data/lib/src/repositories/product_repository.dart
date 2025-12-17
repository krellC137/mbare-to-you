import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_data/src/repositories/auth_repository.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_repository.g.dart';

/// Repository for product operations
class ProductRepository {
  ProductRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService;

  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static const String _collectionPath = 'products';

  /// Create new product
  Future<Result<String>> createProduct(ProductModel product) async {
    return _firestoreService.addDocument(_collectionPath, product.toJson());
  }

  /// Get product by ID
  Future<Result<ProductModel>> getProductById(String productId) async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$productId',
    );

    return result.fold((Failure failure) => Left(failure), (
      Map<String, dynamic>? data,
    ) {
      if (data == null) {
        return const Left(NotFoundFailure(message: 'Product not found'));
      }
      return Right(ProductModel.fromJson(data));
    });
  }

  /// Stream product by ID
  Stream<Result<ProductModel?>> streamProductById(String productId) {
    return _firestoreService.streamDocument('$_collectionPath/$productId').map((
      Result<Map<String, dynamic>?> result,
    ) {
      return result.fold((Failure failure) => Left(failure), (
        Map<String, dynamic>? data,
      ) {
        if (data == null) {
          return const Right(null);
        }
        return Right(ProductModel.fromJson(data));
      });
    });
  }

  /// Update product
  Future<Result<void>> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    // Add updatedAt timestamp
    final updateData = {...data, 'updatedAt': DateTime.now().toIso8601String()};

    return _firestoreService.updateDocument(
      '$_collectionPath/$productId',
      updateData,
    );
  }

  /// Upload product image
  Future<Result<String>> uploadProductImage({
    required String vendorId,
    required String productId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    return _storageService.uploadProductImage(
      vendorId: vendorId,
      productId: productId,
      file: file,
      onProgress: onProgress,
    );
  }

  /// Delete product image
  Future<Result<void>> deleteProductImage(String imageUrl) async {
    return _storageService.deleteFileByUrl(imageUrl);
  }

  /// Get all products
  Future<Result<List<ProductModel>>> getAllProducts({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final products =
          docs
              .map((Map<String, dynamic> doc) => ProductModel.fromJson(doc))
              .toList();
      return Right(products);
    });
  }

  /// Get products by vendor ID
  Future<Result<List<ProductModel>>> getProductsByVendorId(
    String vendorId, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query.where('vendorId', isEqualTo: vendorId),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final products =
          docs
              .map((Map<String, dynamic> doc) => ProductModel.fromJson(doc))
              .toList();
      return Right(products);
    });
  }

  /// Stream products by vendor ID
  Stream<Result<List<ProductModel>>> streamProductsByVendorId(
    String vendorId, {
    int? limit,
  }) {
    return _firestoreService
        .streamCollection(
          _collectionPath,
          queryBuilder: (query) => query.where('vendorId', isEqualTo: vendorId),
          limit: limit,
        )
        .map((Result<List<Map<String, dynamic>>> result) {
          return result.fold((Failure failure) => Left(failure), (
            List<Map<String, dynamic>> docs,
          ) {
            final products =
                docs
                    .map(
                      (Map<String, dynamic> doc) => ProductModel.fromJson(doc),
                    )
                    .toList();
            return Right(products);
          });
        });
  }

  /// Get available products (in stock and active)
  Future<Result<List<ProductModel>>> getAvailableProducts({int? limit}) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('isAvailable', isEqualTo: true),
      // Note: stockQuantity filter removed to avoid composite index requirement
      // Filter in memory if needed
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final products =
          docs
              .map((Map<String, dynamic> doc) => ProductModel.fromJson(doc))
              .toList()
              // Filter out products with no stock in memory
              .where((product) => product.stockQuantity > 0)
              .toList();
      return Right(products);
    });
  }

  /// Get products by category
  Future<Result<List<ProductModel>>> getProductsByCategory(
    String category, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('category', isEqualTo: category)
              .where('isAvailable', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final products =
          docs
              .map((Map<String, dynamic> doc) => ProductModel.fromJson(doc))
              .toList();
      return Right(products);
    });
  }

  /// Search products by name
  Future<Result<List<ProductModel>>> searchProductsByName(
    String name, {
    int? limit,
  }) async {
    final result = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder:
          (query) => query
              .where('name', isGreaterThanOrEqualTo: name)
              .where('name', isLessThanOrEqualTo: '$name\uf8ff')
              .where('isAvailable', isEqualTo: true),
      limit: limit,
    );

    return result.fold((Failure failure) => Left(failure), (
      List<Map<String, dynamic>> docs,
    ) {
      final products =
          docs
              .map((Map<String, dynamic> doc) => ProductModel.fromJson(doc))
              .toList();
      return Right(products);
    });
  }

  /// Update product stock
  Future<Result<void>> updateProductStock(
    String productId,
    int quantity,
  ) async {
    return updateProduct(productId, {'stockQuantity': quantity});
  }

  /// Update product availability
  Future<Result<void>> updateProductAvailability(
    String productId, {
    required bool isAvailable,
  }) async {
    return updateProduct(productId, {'isAvailable': isAvailable});
  }

  /// Update product price
  Future<Result<void>> updateProductPrice(
    String productId,
    double price,
  ) async {
    return updateProduct(productId, {'price': price});
  }

  /// Delete product
  Future<Result<void>> deleteProduct(String productId) async {
    return _firestoreService.deleteDocument('$_collectionPath/$productId');
  }
}

/// Provider for ProductRepository
@Riverpod(keepAlive: true)
ProductRepository productRepository(ProductRepositoryRef ref) {
  // Create storage service instance directly
  final storageService = StorageService(FirebaseStorage.instance);
  return ProductRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: storageService,
  );
}

/// Provider for a specific product by ID
@riverpod
Future<ProductModel?> productById(ProductByIdRef ref, String productId) async {
  final productRepository = ref.watch(productRepositoryProvider);
  final result = await productRepository.getProductById(productId);

  return result.fold((Failure _) => null, (ProductModel product) => product);
}

/// Provider to stream a product by ID
@riverpod
Stream<ProductModel?> streamProductById(
  StreamProductByIdRef ref,
  String productId,
) {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository
      .streamProductById(productId)
      .map(
        (Result<ProductModel?> result) => result.fold(
          (Failure _) => null,
          (ProductModel? product) => product,
        ),
      );
}

/// Provider for products by vendor ID
@riverpod
Future<List<ProductModel>> productsByVendorId(
  ProductsByVendorIdRef ref,
  String vendorId, {
  int? limit,
}) async {
  final productRepository = ref.watch(productRepositoryProvider);
  final result = await productRepository.getProductsByVendorId(
    vendorId,
    limit: limit,
  );

  return result.fold(
    (Failure _) => <ProductModel>[],
    (List<ProductModel> products) => products,
  );
}

/// Provider to stream products by vendor ID
@riverpod
Stream<List<ProductModel>> streamProductsByVendorId(
  StreamProductsByVendorIdRef ref,
  String vendorId, {
  int? limit,
}) {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository
      .streamProductsByVendorId(vendorId, limit: limit)
      .map(
        (Result<List<ProductModel>> result) => result.fold(
          (Failure _) => <ProductModel>[],
          (List<ProductModel> products) => products,
        ),
      );
}

/// Provider for available products
@riverpod
Future<List<ProductModel>> availableProducts(
  AvailableProductsRef ref, {
  int? limit,
}) async {
  final productRepository = ref.watch(productRepositoryProvider);
  final result = await productRepository.getAvailableProducts(limit: limit);

  return result.fold(
    (Failure _) => <ProductModel>[],
    (List<ProductModel> products) => products,
  );
}

/// Provider for products by category
@riverpod
Future<List<ProductModel>> productsByCategory(
  ProductsByCategoryRef ref,
  String category, {
  int? limit,
}) async {
  final productRepository = ref.watch(productRepositoryProvider);
  final result = await productRepository.getProductsByCategory(
    category,
    limit: limit,
  );

  return result.fold(
    (Failure _) => <ProductModel>[],
    (List<ProductModel> products) => products,
  );
}
