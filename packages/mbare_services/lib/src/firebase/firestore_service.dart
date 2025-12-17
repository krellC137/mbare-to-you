import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbare_core/mbare_core.dart';

/// Firestore database service wrapper
class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Get the Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Get a single document
  Future<Result<Map<String, dynamic>?>> getDocument(String path) async {
    try {
      final doc = await _firestore.doc(path).get();

      if (!doc.exists) {
        return success(null);
      }

      return success(doc.data());
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to get document',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get multiple documents from a collection
  Future<Result<List<Map<String, dynamic>>>> getCollection(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final docs =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      return success(docs);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to get collection',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Stream a single document
  Stream<Result<Map<String, dynamic>?>> streamDocument(String path) {
    return _firestore.doc(path).snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) {
          return success(null);
        }
        return success(snapshot.data());
      } catch (e) {
        return failure(ServerFailure(message: e.toString()));
      }
    });
  }

  /// Stream a collection
  Stream<Result<List<Map<String, dynamic>>>> streamCollection(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      try {
        final docs =
            snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        return success(docs);
      } catch (e) {
        return failure(ServerFailure(message: e.toString()));
      }
    });
  }

  /// Add a new document with auto-generated ID
  Future<Result<String>> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      return success(docRef.id);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to add document',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Set a document (create or overwrite)
  Future<Result<void>> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to set document',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Update a document (merge fields)
  Future<Result<void>> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.doc(path).update(data);
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to update document',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Delete a document
  Future<Result<void>> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to delete document',
          code: e.code,
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Run a transaction
  Future<Result<T>> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      final result = await _firestore.runTransaction(transactionHandler);
      return success(result);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(message: e.message ?? 'Transaction failed', code: e.code),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Run a batch write
  Future<Result<void>> runBatch(
    void Function(WriteBatch batch) batchHandler,
  ) async {
    try {
      final batch = _firestore.batch();
      batchHandler(batch);
      await batch.commit();
      return success(null);
    } on FirebaseException catch (e) {
      return failure(
        ServerFailure(message: e.message ?? 'Batch write failed', code: e.code),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Query helpers

  /// Where equal to
  Query<Map<String, dynamic>> whereEqualTo(
    Query<Map<String, dynamic>> query,
    String field,
    dynamic value,
  ) {
    return query.where(field, isEqualTo: value);
  }

  /// Where not equal to
  Query<Map<String, dynamic>> whereNotEqualTo(
    Query<Map<String, dynamic>> query,
    String field,
    dynamic value,
  ) {
    return query.where(field, isNotEqualTo: value);
  }

  /// Where in array
  Query<Map<String, dynamic>> whereIn(
    Query<Map<String, dynamic>> query,
    String field,
    List<dynamic> values,
  ) {
    return query.where(field, whereIn: values);
  }

  /// Where array contains
  Query<Map<String, dynamic>> whereArrayContains(
    Query<Map<String, dynamic>> query,
    String field,
    dynamic value,
  ) {
    return query.where(field, arrayContains: value);
  }

  /// Order by field
  Query<Map<String, dynamic>> orderBy(
    Query<Map<String, dynamic>> query,
    String field, {
    bool descending = false,
  }) {
    return query.orderBy(field, descending: descending);
  }

  /// Limit results
  Query<Map<String, dynamic>> limitTo(
    Query<Map<String, dynamic>> query,
    int count,
  ) {
    return query.limit(count);
  }

  /// Start after document
  Query<Map<String, dynamic>> startAfter(
    Query<Map<String, dynamic>> query,
    DocumentSnapshot doc,
  ) {
    return query.startAfterDocument(doc);
  }

  /// Get server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Get array union
  FieldValue arrayUnion(List<dynamic> elements) =>
      FieldValue.arrayUnion(elements);

  /// Get array remove
  FieldValue arrayRemove(List<dynamic> elements) =>
      FieldValue.arrayRemove(elements);

  /// Get increment
  FieldValue increment(num value) => FieldValue.increment(value);

  /// Delete field
  FieldValue get deleteField => FieldValue.delete();
}
