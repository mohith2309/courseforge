import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiResult {
  final bool launched; // did a UPI app actually open?
  final String? error;
  const UpiResult({required this.launched, this.error});
}

/// Direct UPI payment. Builds a `upi://pay?...` intent and hands it to the
/// installed UPI apps (GPay / PhonePe / Paytm / FamPay…). Money goes straight
/// to [payeeVpa] — there's no server, no Razorpay, and the app cannot
/// cryptographically confirm the payment, so the caller must ask the user to
/// confirm completion (honor system).
class UpiPayment {
  /// Receiving UPI ID. Override at build time with
  /// --dart-define=UPI_VPA=you@bank to change where profits go.
  static const String payeeVpa =
      String.fromEnvironment('UPI_VPA', defaultValue: 'mohith2309@fam');

  static const String payeeName =
      String.fromEnvironment('UPI_NAME', defaultValue: 'CourseForge');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens a UPI app pre-filled to pay [amountInr] to [payeeVpa].
  /// [note] becomes the transaction note; [txnRef] a unique reference.
  Future<UpiResult> pay({
    required int amountInr,
    required String note,
    required String txnRef,
  }) async {
    if (!supported) {
      return const UpiResult(
          launched: false,
          error: 'UPI payments are available on Android.');
    }
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeVpa,
        'pn': payeeName,
        'tr': txnRef,
        'tn': note,
        'am': amountInr.toStringAsFixed(0),
        'cu': 'INR',
      },
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        return const UpiResult(
            launched: false,
            error: 'No UPI app found. Install GPay, PhonePe, or FamPay.');
      }
      return const UpiResult(launched: true);
    } catch (e) {
      return UpiResult(launched: false, error: 'Could not open a UPI app.');
    }
  }
}
