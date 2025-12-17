import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mbare_core/mbare_core.dart';

/// Firebase Storage service wrapper
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Upload a file to storage
  Future<Result<String>> uploadFile({
    required String path,
    required File file,
    Map<String, String>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref(path);
      final uploadTask = ref.putFile(
        file,
        metadata != null ? SettableMetadata(customMetadata: metadata) : null,
      );

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return success(downloadUrl);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to upload file',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Upload image file
  Future<Result<String>> uploadImage({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    return uploadFile(
      path: path,
      file: file,
      metadata: {'contentType': _getImageContentType(file.path)},
      onProgress: onProgress,
    );
  }

  /// Upload user profile photo
  Future<Result<String>> uploadUserPhoto({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      path: 'users/$userId/profile/$fileName',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Upload vendor logo
  Future<Result<String>> uploadVendorLogo({
    required String vendorId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      path: 'vendors/$vendorId/logo/$fileName',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Upload product image
  Future<Result<String>> uploadProductImage({
    required String vendorId,
    required String productId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      path: 'vendors/$vendorId/products/$productId/$fileName',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Delete a file from storage
  Future<Result<void>> deleteFile(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.delete();
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to delete file',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Delete file by URL
  Future<Result<void>> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to delete file',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get download URL for a file
  Future<Result<String>> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref(path);
      final url = await ref.getDownloadURL();
      return success(url);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to get download URL',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get file metadata
  Future<Result<FullMetadata>> getMetadata(String path) async {
    try {
      final ref = _storage.ref(path);
      final metadata = await ref.getMetadata();
      return success(metadata);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to get metadata',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// List files in a directory
  Future<Result<List<String>>> listFiles(String path) async {
    try {
      final ref = _storage.ref(path);
      final result = await ref.listAll();
      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );
      return success(urls);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to list files',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get content type from file path
  String _getImageContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
