enum TransactionDirection { sent, received }

/// A transaction as seen from the current user's point of view.
class TransactionModel {
  final String id;
  final TransactionDirection direction;
  final String counterpartyEmail;
  final int amount;
  final String status;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.direction,
    required this.counterpartyEmail,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  bool get isSent => direction == TransactionDirection.sent;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      direction: (json['direction'] as String) == 'SENT'
          ? TransactionDirection.sent
          : TransactionDirection.received,
      counterpartyEmail: json['counterpartyEmail'] as String? ?? '',
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
