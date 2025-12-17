import 'package:fpdart/fpdart.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:mbare_services/mbare_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';

part 'settings_repository.g.dart';

/// Repository for platform settings operations
class SettingsRepository {
  SettingsRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  static const String _collectionPath = 'settings';
  static const String _settingsDocId = 'platform_settings';

  /// Get platform settings
  Future<Result<PlatformSettingsModel>> getPlatformSettings() async {
    final result = await _firestoreService.getDocument(
      '$_collectionPath/$_settingsDocId',
    );

    return result.fold(
      (failure) => Left(failure),
      (data) {
        if (data == null) {
          // Return default settings if not found
          return const Right(PlatformSettingsModel(
            id: _settingsDocId,
            deliveryFeePercentage: 10.0,
            platformFeePercentage: 5.0,
            minimumOrderAmount: 0.0,
            baseDeliveryFee: 5.0,
            isDeliveryFeePercentageBased: true,
          ));
        }
        return Right(PlatformSettingsModel.fromJson(data));
      },
    );
  }

  /// Stream platform settings
  Stream<Result<PlatformSettingsModel>> streamPlatformSettings() {
    return _firestoreService
        .streamDocument('$_collectionPath/$_settingsDocId')
        .map((result) {
      return result.fold(
        (failure) => Left(failure),
        (data) {
          if (data == null) {
            // Return default settings if not found
            return const Right(PlatformSettingsModel(
              id: _settingsDocId,
              deliveryFeePercentage: 10.0,
              platformFeePercentage: 5.0,
              minimumOrderAmount: 0.0,
              baseDeliveryFee: 5.0,
              isDeliveryFeePercentageBased: true,
            ));
          }
          return Right(PlatformSettingsModel.fromJson(data));
        },
      );
    });
  }

  /// Update platform settings
  Future<Result<void>> updatePlatformSettings(
    PlatformSettingsModel settings,
  ) async {
    final data = settings.toJson();
    data['updatedAt'] = DateTime.now().toIso8601String();

    return _firestoreService.setDocument(
      '$_collectionPath/$_settingsDocId',
      data,
    );
  }

  /// Update delivery fee percentage
  Future<Result<void>> updateDeliveryFeePercentage(
    double percentage,
    String updatedBy,
  ) async {
    return _firestoreService.updateDocument(
      '$_collectionPath/$_settingsDocId',
      {
        'deliveryFeePercentage': percentage,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': updatedBy,
      },
    );
  }

  /// Update platform fee percentage
  Future<Result<void>> updatePlatformFeePercentage(
    double percentage,
    String updatedBy,
  ) async {
    return _firestoreService.updateDocument(
      '$_collectionPath/$_settingsDocId',
      {
        'platformFeePercentage': percentage,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': updatedBy,
      },
    );
  }

  /// Update base delivery fee
  Future<Result<void>> updateBaseDeliveryFee(
    double fee,
    String updatedBy,
  ) async {
    return _firestoreService.updateDocument(
      '$_collectionPath/$_settingsDocId',
      {
        'baseDeliveryFee': fee,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': updatedBy,
      },
    );
  }

  /// Update minimum order amount
  Future<Result<void>> updateMinimumOrderAmount(
    double amount,
    String updatedBy,
  ) async {
    return _firestoreService.updateDocument(
      '$_collectionPath/$_settingsDocId',
      {
        'minimumOrderAmount': amount,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': updatedBy,
      },
    );
  }
}

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
}

@riverpod
Stream<Result<PlatformSettingsModel>> platformSettings(
  PlatformSettingsRef ref,
) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.streamPlatformSettings();
}
