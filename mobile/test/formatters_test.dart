import 'package:flutter_test/flutter_test.dart';
import 'package:minitransfer_mobile/models/transaction.dart';
import 'package:minitransfer_mobile/utils/formatters.dart';

void main() {
  group('formatAmount', () {
    test('groups thousands with a space', () {
      expect(formatAmount(0), '0');
      expect(formatAmount(500), '500');
      expect(formatAmount(10000), '10 000');
      expect(formatAmount(1234567), '1 234 567');
    });
  });

  group('formatFcfa', () {
    test('appends the FCFA currency', () {
      expect(formatFcfa(10000), '10 000 FCFA');
    });
  });

  group('TransactionModel.fromJson', () {
    test('parses a SENT transaction', () {
      final tx = TransactionModel.fromJson({
        'id': 'tx-1',
        'direction': 'SENT',
        'counterpartyEmail': 'bob@mail.com',
        'amount': 2000,
        'status': 'COMPLETED',
        'createdAt': '2026-01-01T10:00:00Z',
      });

      expect(tx.isSent, isTrue);
      expect(tx.counterpartyEmail, 'bob@mail.com');
      expect(tx.amount, 2000);
    });
  });
}
