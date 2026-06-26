import 'transaction.dart';

/// Outcome of a successful transfer: confirmation message, the recorded
/// transaction and the sender's updated balance.
class TransferResult {
  final String message;
  final TransactionModel transaction;
  final int newBalance;

  const TransferResult({
    required this.message,
    required this.transaction,
    required this.newBalance,
  });

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      message: json['message'] as String? ?? 'Transfert effectue.',
      transaction: TransactionModel.fromJson(json['transaction'] as Map<String, dynamic>),
      newBalance: (json['newBalance'] as num).toInt(),
    );
  }
}
