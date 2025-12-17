import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_repository.g.dart';

/// Repository for managing product, vendor, and driver reviews
class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _firestore.collection('reviews');

  /// Add a new review
  Future<Result<ReviewModel>> addReview(ReviewModel review) async {
    try {
      final reviewRef = _reviewsCollection.doc();
      final newReview = review.copyWith(
        id: reviewRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await reviewRef.set(newReview.toFirestoreJson());
      return right(newReview);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to add review'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Update an existing review
  Future<Result<ReviewModel>> updateReview(ReviewModel review) async {
    try {
      if (review.id == null) {
        return left(const NotFoundFailure(message: 'Review ID is required'));
      }

      final updatedReview = review.copyWith(updatedAt: DateTime.now());
      await _reviewsCollection.doc(review.id).update(updatedReview.toFirestoreJson());
      return right(updatedReview);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to update review'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Delete a review
  Future<Result<void>> deleteReview(String reviewId) async {
    try {
      await _reviewsCollection.doc(reviewId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to delete review'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Get reviews for a product
  Future<Result<List<ReviewModel>>> getReviewsByProductId(String productId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('targetId', isEqualTo: productId)
          .where('type', isEqualTo: ReviewType.product.name)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();

      // Sort in memory
      reviews.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return right(reviews);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to get reviews'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Stream reviews for a product
  Stream<List<ReviewModel>> streamReviewsByProductId(String productId) {
    return _reviewsCollection
        .where('targetId', isEqualTo: productId)
        .where('type', isEqualTo: ReviewType.product.name)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();

      // Sort in memory
      reviews.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return reviews;
    });
  }

  /// Get user's review for a product
  Future<Result<ReviewModel?>> getUserReviewForProduct(
    String userId,
    String productId,
  ) async {
    try {
      final snapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: productId)
          .where('type', isEqualTo: ReviewType.product.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return right(null);
      }

      return right(ReviewModel.fromJson(snapshot.docs.first.data()));
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to get review'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Get average rating for a product
  Future<Result<double>> getAverageRating(String productId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('targetId', isEqualTo: productId)
          .where('type', isEqualTo: ReviewType.product.name)
          .get();

      if (snapshot.docs.isEmpty) {
        return right(0.0);
      }

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();

      final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      return right(totalRating / reviews.length);
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to get average rating'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Get reviews for a vendor
  Stream<List<ReviewModel>> streamVendorReviews(String vendorId) {
    return _reviewsCollection
        .where('targetId', isEqualTo: vendorId)
        .where('type', isEqualTo: ReviewType.vendor.name)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();

      // Sort by date
      reviews.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return reviews;
    });
  }

  /// Get reviews for a driver
  Stream<List<ReviewModel>> streamDriverReviews(String driverId) {
    return _reviewsCollection
        .where('targetId', isEqualTo: driverId)
        .where('type', isEqualTo: ReviewType.driver.name)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();

      // Sort by date
      reviews.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return reviews;
    });
  }

  /// Get user's review for a target (vendor/driver) for a specific order
  Future<Result<ReviewModel?>> getUserReviewForTarget(
    String userId,
    String targetId,
    String orderId,
    ReviewType type,
  ) async {
    try {
      final snapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return right(null);
      }

      return right(ReviewModel.fromJson(snapshot.docs.first.data()));
    } on FirebaseException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Failed to get review'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  /// Stream user's review for a target
  Stream<ReviewModel?> streamUserReviewForTarget(
    String userId,
    String targetId,
    String orderId,
    ReviewType type,
  ) {
    return _reviewsCollection
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .where('orderId', isEqualTo: orderId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ReviewModel.fromJson(snapshot.docs.first.data());
    });
  }
}

/// Provider for review repository
@riverpod
ReviewRepository reviewRepository(ReviewRepositoryRef ref) {
  return ReviewRepository();
}

/// Provider to stream reviews for a product
@riverpod
Stream<List<ReviewModel>> streamProductReviews(
  StreamProductReviewsRef ref,
  String productId,
) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return reviewRepository.streamReviewsByProductId(productId);
}

/// Provider to get average rating for a product
@riverpod
Future<double> productAverageRating(
  ProductAverageRatingRef ref,
  String productId,
) async {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  final result = await reviewRepository.getAverageRating(productId);
  return result.fold((Failure _) => 0.0, (double rating) => rating);
}

/// Provider to get user's review for a product
@riverpod
Future<ReviewModel?> userProductReview(
  UserProductReviewRef ref,
  String userId,
  String productId,
) async {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  final result = await reviewRepository.getUserReviewForProduct(userId, productId);
  return result.fold((Failure _) => null, (ReviewModel? review) => review);
}

/// Provider to stream vendor reviews
@riverpod
Stream<List<ReviewModel>> streamVendorReviews(
  StreamVendorReviewsRef ref,
  String vendorId,
) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return reviewRepository.streamVendorReviews(vendorId);
}

/// Provider to stream driver reviews
@riverpod
Stream<List<ReviewModel>> streamDriverReviews(
  StreamDriverReviewsRef ref,
  String driverId,
) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return reviewRepository.streamDriverReviews(driverId);
}

/// Provider to stream user's review for a target
@riverpod
Stream<ReviewModel?> streamUserReviewForTarget(
  StreamUserReviewForTargetRef ref,
  String userId,
  String targetId,
  String orderId,
  ReviewType type,
) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return reviewRepository.streamUserReviewForTarget(userId, targetId, orderId, type);
}
