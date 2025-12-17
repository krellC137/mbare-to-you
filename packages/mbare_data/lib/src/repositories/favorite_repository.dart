import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_repository.g.dart';

@riverpod
FavoriteRepository favoriteRepository(FavoriteRepositoryRef ref) {
  return FavoriteRepository(FirebaseFirestore.instance);
}

/// Stream all favorites for a user
@riverpod
Stream<List<FavoriteModel>> userFavorites(
  UserFavoritesRef ref,
  String userId,
) {
  return ref.watch(favoriteRepositoryProvider).streamFavoritesByUserId(userId);
}

/// Stream favorites by type (product or vendor)
@riverpod
Stream<List<FavoriteModel>> userFavoritesByType(
  UserFavoritesByTypeRef ref,
  String userId,
  FavoriteType type,
) {
  return ref
      .watch(favoriteRepositoryProvider)
      .streamFavoritesByType(userId, type);
}

/// Check if an item is favorited
@riverpod
Stream<bool> isFavorite(
  IsFavoriteRef ref,
  String userId,
  String itemId,
  FavoriteType type,
) {
  return ref
      .watch(favoriteRepositoryProvider)
      .streamIsFavorite(userId, itemId, type);
}

class FavoriteRepository {
  final FirebaseFirestore _firestore;

  FavoriteRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestore.collection('favorites');

  /// Add item to favorites
  Future<Either<Failure, void>> addFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final favoriteRef = _favoritesCollection.doc();
      final favorite = FavoriteModel(
        id: favoriteRef.id,
        userId: userId,
        itemId: itemId,
        type: type,
        createdAt: DateTime.now(),
      );

      await favoriteRef.set(favorite.toJson());
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to add favorite'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Remove item from favorites
  Future<Either<Failure, void>> removeFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return left(const NotFoundFailure(message: 'Favorite not found'));
      }

      await querySnapshot.docs.first.reference.delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to remove favorite'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Toggle favorite status
  Future<Either<Failure, void>> toggleFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Not favorited, add it
        return await addFavorite(
          userId: userId,
          itemId: itemId,
          type: type,
        );
      } else {
        // Already favorited, remove it
        await querySnapshot.docs.first.reference.delete();
        return right(null);
      }
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to toggle favorite'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Check if item is favorited (one-time check)
  Future<bool> isFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Stream if item is favorited (real-time)
  Stream<bool> streamIsFavorite(
    String userId,
    String itemId,
    FavoriteType type,
  ) {
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('itemId', isEqualTo: itemId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Stream all favorites for a user
  Stream<List<FavoriteModel>> streamFavoritesByUserId(String userId) {
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final favorites = snapshot.docs
          .map((doc) => FavoriteModel.fromJson(doc.data()))
          .toList();
      // Sort in-memory to avoid composite index requirement
      favorites.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return favorites;
    });
  }

  /// Stream favorites by type (product or vendor)
  Stream<List<FavoriteModel>> streamFavoritesByType(
    String userId,
    FavoriteType type,
  ) {
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((snapshot) {
      final favorites = snapshot.docs
          .map((doc) => FavoriteModel.fromJson(doc.data()))
          .toList();
      // Sort in-memory to avoid composite index requirement
      favorites.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return favorites;
    });
  }

  /// Get all favorite product IDs for a user
  Future<List<String>> getFavoriteProductIds(String userId) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: FavoriteType.product.name)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['itemId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all favorite vendor IDs for a user
  Future<List<String>> getFavoriteVendorIds(String userId) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: FavoriteType.vendor.name)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['itemId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
