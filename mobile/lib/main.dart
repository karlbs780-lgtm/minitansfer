import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/api_client.dart';
import 'services/auth_api.dart';
import 'services/token_storage.dart';
import 'services/transfer_api.dart';
import 'services/wallet_api.dart';

void main() {
  // Manual dependency wiring (a single shared ApiClient + secure token storage).
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl, tokenStorage: tokenStorage);

  final authApi = AuthApi(apiClient);
  final walletApi = WalletApi(apiClient);
  final transferApi = TransferApi(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authApi: authApi, tokenStorage: tokenStorage)..tryAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(walletApi: walletApi, transferApi: transferApi),
        ),
      ],
      child: const MiniTransferApp(),
    ),
  );
}
