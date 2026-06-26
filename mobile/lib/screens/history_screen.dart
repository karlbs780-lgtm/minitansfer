import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_exception.dart';
import '../utils/formatters.dart';
import '../utils/ui_feedback.dart';

/// History tab: transactions grouped by day, newest first.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<WalletProvider>().loadHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        context.read<WalletProvider>().reset();
        await context.read<AuthProvider>().logout();
      } else {
        showErrorSnackBar(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, color: colors.primary),
            const SizedBox(width: 8),
            const Text('Historique'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context, wallet.loadingHistory, wallet.transactions),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool loading, List<TransactionModel> transactions) {
    if (loading && transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (transactions.isEmpty) {
      return _EmptyState();
    }

    // Build a grouped list: a day header each time the day changes.
    final children = <Widget>[const SizedBox(height: 8)];
    String? currentLabel;
    for (final tx in transactions) {
      final label = dayLabel(tx.createdAt);
      if (label != currentLabel) {
        currentLabel = label;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _TransactionCard(tx),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: children,
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard(this.transaction);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sent = transaction.isSent;
    final failed = transaction.status == 'FAILED';

    final Color accent = failed ? colors.outline : (sent ? colors.error : colors.primary);
    final Color iconBg = failed
        ? colors.surfaceContainerHighest
        : (sent ? colors.errorContainer : colors.secondaryContainer);
    final String sign = sent ? '-' : '+';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(sent ? Icons.arrow_upward : Icons.arrow_downward, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sent
                      ? 'Envoye a ${transaction.counterpartyEmail}'
                      : 'Recu de ${transaction.counterpartyEmail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  failed ? '${formatTime(transaction.createdAt)} • Echoue' : formatTime(transaction.createdAt),
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign${formatFcfa(transaction.amount)}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              decoration: failed ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: colors.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long, size: 40, color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('Aucune transaction',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, color: colors.onSurface)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text("Vous n'avez pas encore effectue de transaction.",
              style: TextStyle(color: colors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
