import 'dart:async';

class PaymentResult {
  final bool success;
  final String message;
  final String? orderId;
  const PaymentResult(this.success, this.message, {this.orderId});
}

/// Enrollment payment flow.
///
/// Razorpay's secret key must never live in a client app — order creation
/// belongs on a server (see /firebase/functions in the repo plan). This
/// service is written against that contract: it would call your backend's
/// `createRazorpayOrder` endpoint, open the Razorpay checkout, then verify.
///
/// With no backend configured it runs in MOCK mode and simulates a
/// successful payment so the enroll → learn flow is fully demoable offline.
class PaymentService {
  PaymentService({String? backendBaseUrl})
      : _backendBaseUrl = backendBaseUrl ??
            const String.fromEnvironment('BACKEND_URL', defaultValue: '');

  final String _backendBaseUrl;

  bool get isLive => _backendBaseUrl.isNotEmpty;

  Future<PaymentResult> payForCourse({
    required String courseId,
    required int amountInr,
  }) async {
    if (!isLive) {
      // Simulate the round-trip a real checkout would take.
      await Future.delayed(const Duration(milliseconds: 900));
      return PaymentResult(
        true,
        'Enrolled (demo mode — no real charge). '
        'Configure BACKEND_URL + Razorpay to go live.',
        orderId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Live path (intentionally left as the integration point):
    //   1. POST $_backendBaseUrl/createRazorpayOrder { courseId, amountInr }
    //   2. open Razorpay checkout with returned orderId + keyId
    //   3. backend webhook verifies signature and creates the enrollment
    return const PaymentResult(
      false,
      'Live payment path not wired in this build. Use demo mode or implement '
      'the backend order/verify endpoints.',
    );
  }
}
