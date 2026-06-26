import '../models/transaction.dart';
import '../models/transfer_result.dart';
import 'api_client.dart';

class TransferApi {
  final ApiClient client;

  TransferApi(this.client);

  Future<TransferResult> transfer({
    required String recipient,
    required int amount,
  }) async {
    final json = await client.post('/api/transfers', body: {
      'recipient': recipient,
      'amount': amount,
    });
    return TransferResult.fromJson(json as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> history() async {
    final json = await client.get('/api/transfers/history');
    return (json as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
