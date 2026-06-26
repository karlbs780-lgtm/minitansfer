import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../models/transfer_result.dart';
import '../services/transfer_api.dart';
import '../services/wallet_api.dart';

/// Source of truth for the wallet balance and transaction history shown in the UI.
class WalletProvider extends ChangeNotifier {
  final WalletApi _walletApi;
  final TransferApi _transferApi;

  WalletProvider({required WalletApi walletApi, required TransferApi transferApi})
      : _walletApi = walletApi,
        _transferApi = transferApi;

  int? _balance;
  List<TransactionModel> _transactions = [];
  bool _loadingBalance = false;
  bool _loadingHistory = false;

  int? get balance => _balance;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get loadingBalance => _loadingBalance;
  bool get loadingHistory => _loadingHistory;

  Future<void> loadBalance() async {
    _loadingBalance = true;
    notifyListeners();
    try {
      _balance = await _walletApi.getBalance();
    } finally {
      _loadingBalance = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _loadingHistory = true;
    notifyListeners();
    try {
      _transactions = await _transferApi.history();
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  /// Performs a transfer and optimistically updates the cached balance from the response.
  Future<TransferResult> transfer({required String recipient, required int amount}) async {
    final result = await _transferApi.transfer(recipient: recipient, amount: amount);
    _balance = result.newBalance;
    notifyListeners();
    return result;
  }

  /// Clears cached state on logout.
  void reset() {
    _balance = null;
    _transactions = [];
    notifyListeners();
  }
}
