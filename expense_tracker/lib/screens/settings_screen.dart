import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/finance_state.dart';
import '../state/settings_state.dart';
import '../utils/currency.dart';
import '../utils/csv.dart';
import 'budgets_screen.dart';
import 'category_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final settings = context.watch<SettingsState>();
    final cs = Theme.of(context).colorScheme;
    final onVariant = cs.onSurfaceVariant;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          // Profile
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(
                  (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(user?.email ?? '',
                      style: TextStyle(color: onVariant, fontSize: 13)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Appearance', onVariant: onVariant),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.brightness_6_outlined, size: 18, color: onVariant),
                const SizedBox(width: 8),
                const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.smartphone, size: 16)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => context.read<SettingsState>().setThemeMode(s.first),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Preferences', onVariant: onVariant),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.payments_outlined,
            title: 'Currency',
            subtitle: '${findCurrency(settings.currencyCode).name} (${findCurrency(settings.currencyCode).symbol} • ${settings.currencyCode})',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _pickCurrency(context),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Manage', onVariant: onVariant),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budgets',
            subtitle: 'Set monthly limits per category',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetsScreen())),
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: 'Add, edit or delete categories',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryEditorScreen())),
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.download_outlined,
            title: 'Export transactions',
            subtitle: 'Share as CSV',
            trailing: const Icon(Icons.share_outlined, size: 18),
            onTap: () => _exportCsv(context),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async => context.read<AuthState>().logout(),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Expense Tracker • FastAPI + Flutter',
                style: TextStyle(color: onVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final current = context.read<SettingsState>().currencyCode;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(builder: (ctx2, setSB) {
          final filtered = kCurrencies
              .where((c) =>
                  query.isEmpty ||
                  c.code.toLowerCase().contains(query) ||
                  c.name.toLowerCase().contains(query))
              .toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search currency…', prefixIcon: Icon(Icons.search, size: 18)),
                    onChanged: (v) => setSB(() => query = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final sel = c.code == current;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: sel
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Text(c.symbol,
                              style: TextStyle(
                                  color: sel ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                        title: Text('${c.code} — ${c.name}',
                            style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                        subtitle: Text(c.code, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                        trailing: sel ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                        onTap: () => Navigator.of(ctx).pop(c.code),
                      );
                    },
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
    if (picked != null && context.mounted) {
      await context.read<SettingsState>().setCurrency(picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Currency: $picked')));
      }
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final txns = context.read<FinanceState>().transactions;
    if (txns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions to export')));
      return;
    }
    try {
      await shareCsv(txns, fileName: 'expenses-${DateTime.now().toIso8601String().substring(0, 10)}.csv');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color onVariant;
  const _SectionLabel(this.text, {required this.onVariant});
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: onVariant, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant)),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
