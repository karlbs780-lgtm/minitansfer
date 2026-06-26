import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../services/api_exception.dart';
import '../utils/formatters.dart';
import '../utils/ui_feedback.dart';
import '../widgets/loading_button.dart';

/// Transfer tab: available balance banner, recipient + amount form, quick amounts.
class TransferTab extends StatefulWidget {
  /// Called after a successful transfer (used to switch to the history tab).
  final VoidCallback onSent;

  const TransferTab({super.key, required this.onSent});

  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalance());
  }

  Future<void> _loadBalance() async {
    try {
      await context.read<WalletProvider>().loadBalance();
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(int value) {
    final current = int.tryParse(_amountController.text.trim()) ?? 0;
    _amountController.text = (current + value).toString();
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final amount = int.parse(_amountController.text.trim());
    setState(() => _submitting = true);
    try {
      final result = await context.read<WalletProvider>().transfer(
            recipient: _recipientController.text.trim(),
            amount: amount,
          );
      if (!mounted) return;
      showSuccessSnackBar(context, result.message);
      _recipientController.clear();
      _amountController.clear();
      widget.onSent();
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateRecipient(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email ou telephone du destinataire obligatoire';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Montant obligatoire';
    final amount = int.tryParse(value.trim());
    if (amount == null) return 'Le montant doit etre un nombre entier';
    if (amount <= 0) return 'Le montant doit etre strictement positif';
    final balance = context.read<WalletProvider>().balance;
    if (balance != null && amount > balance) return 'Montant superieur au solde disponible';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final balance = context.watch<WalletProvider>().balance;

    return Scaffold(
      appBar: AppBar(title: const Text('Transferer de l\'argent')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceBanner(balance: balance),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Destinataire',
                          hintText: 'Email ou numero de telephone',
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        validator: _validateRecipient,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          labelText: 'Montant',
                          suffixText: 'FCFA',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: _validateAmount,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final v in [1000, 5000, 10000])
                              ActionChip(
                                label: Text('+ ${formatAmount(v)}'),
                                onPressed: () => _addAmount(v),
                                backgroundColor: colors.surfaceContainer,
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                    color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  loading: _submitting,
                  onPressed: _submit,
                  label: 'Envoyer',
                  icon: Icons.send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  final int? balance;

  const _BalanceBanner({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Solde disponible',
                  style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                balance == null ? '—' : formatFcfa(balance!),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.primary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet, color: colors.primary),
          ),
        ],
      ),
    );
  }
}
