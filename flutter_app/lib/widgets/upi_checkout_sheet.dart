import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/upi_payment.dart';
import '../theme/app_theme.dart';

/// Runs a direct-UPI checkout: opens a UPI app to pay [amountInr] to the
/// configured VPA, then (since UPI gives no callback) asks the user to confirm
/// they completed the payment. Returns true only if they confirm.
Future<bool> runUpiCheckout(
  BuildContext context,
  WidgetRef ref, {
  required int amountInr,
  required String note,
  required String txnRef,
}) async {
  final upi = ref.read(upiPaymentProvider);
  final res = await upi.pay(amountInr: amountInr, note: note, txnRef: txnRef);
  if (!context.mounted) return false;

  if (!res.launched) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.error ?? 'Could not open a UPI app.')),
    );
    return false;
  }

  // UPI apps don't return a result to us — confirm with the user.
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ConfirmSheet(amountInr: amountInr),
  );
  return confirmed ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.amountInr});
  final int amountInr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('Did you complete the ₹$amountInr payment?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Paid to ${UpiPayment.payeeVpa}. Once your UPI app shows '
            '“payment successful”, tap below to unlock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, I’ve paid — unlock'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet / cancel'),
          ),
        ],
      ),
    );
  }
}
