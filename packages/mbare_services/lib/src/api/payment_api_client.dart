import 'package:dio/dio.dart';
import 'package:mbare_core/mbare_core.dart';

/// Payment API client for Ecocash and other payment providers
class PaymentApiClient {
  PaymentApiClient({required String baseUrl, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  /// Initialize mock payment (for development)
  Future<Result<Map<String, dynamic>>> initiateMockPayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      // Simulate API delay
      await Future<void>.delayed(const Duration(seconds: 2));

      // Mock successful response
      return success({
        'transactionId': 'MOCK_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'orderId': orderId,
        'amount': amount,
        'phoneNumber': phoneNumber,
        'message': 'Mock payment initiated successfully',
      });
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Check mock payment status
  Future<Result<Map<String, dynamic>>> checkMockPaymentStatus({
    required String transactionId,
  }) async {
    try {
      // Simulate API delay
      await Future<void>.delayed(const Duration(seconds: 1));

      // Mock successful response (80% success rate)
      final isSuccess = DateTime.now().second % 5 != 0;

      return success({
        'transactionId': transactionId,
        'status': isSuccess ? 'completed' : 'failed',
        'message':
            isSuccess
                ? 'Payment completed successfully'
                : 'Payment failed - insufficient funds',
      });
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Initiate Ecocash payment (placeholder for real implementation)
  Future<Result<Map<String, dynamic>>> initiateEcocashPayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ecocash/initiate',
        data: {
          'orderId': orderId,
          'amount': amount,
          'phoneNumber': phoneNumber,
        },
      );

      return success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to initiate Ecocash payment',
          code: e.response?.statusCode.toString(),
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Check Ecocash payment status (placeholder for real implementation)
  Future<Result<Map<String, dynamic>>> checkEcocashPaymentStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/ecocash/status/$transactionId',
      );

      return success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to check payment status',
          code: e.response?.statusCode.toString(),
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  /// Initiate Stripe payment (placeholder for real implementation)
  Future<Result<Map<String, dynamic>>> initiateStripePayment({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/stripe/create-payment-intent',
        data: {
          'orderId': orderId,
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
        },
      );

      return success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return failure(
        ServerFailure(
          message: e.message ?? 'Failed to initiate Stripe payment',
          code: e.response?.statusCode.toString(),
        ),
      );
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }
}
