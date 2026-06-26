import 'api_client.dart';

class WalletApi {
  final ApiClient client;

  WalletApi(this.client);

  Future<int> getBalance() async {
    final json = await client.get('/api/wallet/balance');
    return ((json as Map<String, dynamic>)['balance'] as num).toInt();
  }
}
