import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;
  final bool simulated;
  const CheckoutResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
    this.simulated = false,
  });
}

/// Native, in-app Razorpay checkout (Android/iOS) — no web page.
///
/// The publishable key_id is safe to embed; the secret stays on the server.
/// When a server order is available, we pass order_id so the payment can be
/// signature-verified. On platforms without the native SDK (desktop dev) it
/// returns a simulated success so the flow stays demoable.
class RazorpayCheckout {
  static const _publicKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_SuU4j828CrwrXO',
  );

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<CheckoutResult> pay({
    required int amountInr,
    required String description,
    String? orderId,
    String? keyId,
    String? email,
    String? contact,
  }) async {
    if (!supported) {
      // Desktop/web dev — simulate so buying/upgrading still works end-to-end.
      await Future.delayed(const Duration(milliseconds: 700));
      return const CheckoutResult(success: true, simulated: true);
    }

    final razorpay = Razorpay();
    final completer = Completer<CheckoutResult>();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      if (!completer.isCompleted) {
        completer.complete(CheckoutResult(
          success: true,
          paymentId: r.paymentId,
          orderId: r.orderId,
          signature: r.signature,
        ));
      }
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (!completer.isCompleted) {
        completer.complete(CheckoutResult(
          success: false,
          error: r.message ?? 'Payment cancelled',
        ));
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    razorpay.open({
      'key': keyId == null || keyId.isEmpty || keyId == 'mock' ? _publicKey : keyId,
      'amount': amountInr * 100, // paise
      'currency': 'INR',
      'name': 'CourseForge',
      'description': description,
      if (orderId != null && !orderId.startsWith('order_mock')) 'order_id': orderId,
      'prefill': {
        if (email != null) 'email': email,
        if (contact != null) 'contact': contact,
      },
      'theme': {'color': '#0D9488'},
    });

    final result = await completer.future;
    razorpay.clear();
    return result;
  }
}
