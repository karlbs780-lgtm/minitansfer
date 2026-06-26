import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/ui_feedback.dart';

/// Home tab: greeting, balance card (with hide/show), quick actions, account info.
class HomeTab extends StatefulWidget {
  final void Function(int index) onNavigate;

  const HomeTab({super.key, required this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await context.read<WalletProvider>().loadBalance();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        await _logout();
      } else {
        showErrorSnackBar(context, e.message);
      }
    }
  }

  Future<void> _logout() async {
    context.read<WalletProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final wallet = context.watch<WalletProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, color: colors.primary),
            const SizedBox(width: 8),
            const Text('MiniTransfer'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Se deconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SizedBox(height: 8),
            Text('Bonjour, ${user?.name ?? ''}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Gerez vos finances en toute simplicite.',
                style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            _BalanceCard(
              balance: wallet.balance ?? user?.balance,
              loading: wallet.loadingBalance && wallet.balance == null,
              hidden: _balanceHidden,
              onToggle: () => setState(() => _balanceHidden = !_balanceHidden),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onNavigate(1),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Transferer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onNavigate(2),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Historique'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Infos compte',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
            const SizedBox(height: 12),
            _AccountInfoCard(email: user?.email ?? '', phone: user?.phone ?? ''),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int? balance;
  final bool loading;
  final bool hidden;
  final VoidCallback onToggle;

  const _BalanceCard({
    required this.balance,
    required this.loading,
    required this.hidden,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: AppTheme.balanceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative soft circles.
            Positioned(
              right: -30,
              top: -30,
              child: _circle(110, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              left: -24,
              bottom: -36,
              child: _circle(96, Colors.white.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Solde du portefeuille',
                          style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600)),
                      InkWell(
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            hidden ? Icons.visibility_off : Icons.visibility,
                            color: colors.onPrimary.withValues(alpha: 0.9),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loading || balance == null)
                    const SizedBox(
                      height: 34,
                      width: 34,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  else
                    Text(
                      hidden ? '•••••••• FCFA' : formatFcfa(balance!),
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String email;
  final String phone;

  const _AccountInfoCard({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _row(context, Icons.mail_outline, 'EMAIL', email),
          Divider(height: 24, color: colors.outlineVariant.withValues(alpha: 0.5)),
          _row(context, Icons.call_outlined, 'TELEPHONE', phone),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: colors.surfaceContainer, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: colors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
