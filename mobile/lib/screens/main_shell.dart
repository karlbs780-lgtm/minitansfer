import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'transfer_screen.dart';

/// Authenticated shell: a Material 3 bottom navigation bar over the three tabs
/// (Accueil / Transfert / Historique). Tabs are rebuilt on selection so each one
/// refreshes its data when shown.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_index) {
      0 => HomeTab(onNavigate: _goTo),
      1 => TransferTab(onSent: () => _goTo(2)),
      _ => const HistoryTab(),
    };

    return Scaffold(
      body: body,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send),
              label: 'Transfert',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: 'Historique',
            ),
          ],
        ),
      ),
    );
  }
}
