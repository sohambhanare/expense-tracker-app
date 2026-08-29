import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/summary.dart';
import '../state/auth_state.dart';
import '../state/finance_state.dart';
import '../state/settings_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/txn_tile.dart';
import 'budgets_screen.dart';
import 'txn_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild on currency/theme change (Money reads static config)
    context.watch<SettingsState>();
    final finance = context.watch<FinanceState>();
    final user = context.watch<AuthState>().user;
    final summary = finance.summary;
    final firstName = (user?.name ?? '').split(' ').first;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => finance.loadAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $firstName',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text("Here's your money at a glance",
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _BalanceCard(summary: summary),
            if (summary != null && summary.budgets.isNotEmpty) ...[
              const SizedBox(height: 16),
              _BudgetsProgressCard(budgets: summary.budgets),
            ],
            const SizedBox(height: 24),
            const Text('Recent activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (finance.transactionsState == LoadState.loading && finance.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (finance.transactions.isEmpty)
              const _EmptyCard()
            else
              ...finance.transactions.take(5).map(
                    (t) => TxnTile(txn: t, onTap: () => openEditTransaction(context, existing: t)),
                  ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Summary? summary;
  const _BalanceCard({this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final sem = context.sem;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sem.balanceStart, sem.balanceEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: sem.balanceBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total balance', style: TextStyle(color: Color(0xFF9FE8D5), fontSize: 13)),
        const SizedBox(height: 6),
        Text(s == null ? Money.fmt(0) : Money.fmt(s.balance),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: _MiniStat(
                  label: 'Income (month)',
                  value: s?.monthIncome ?? 0,
                  icon: Icons.arrow_downward,
                  color: sem.income)),
          const SizedBox(width: 12),
          Expanded(
              child: _MiniStat(
                  label: 'Spent (month)',
                  value: s?.monthExpense ?? 0,
                  icon: Icons.arrow_outward,
                  color: sem.expense)),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9FE8D5)))),
        ]),
        const SizedBox(height: 6),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(Money.fmt(value),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }
}

class _BudgetsProgressCard extends StatelessWidget {
  final List<BudgetStatus> budgets;
  const _BudgetsProgressCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    // Show top 4 by pct
    final shown = List<BudgetStatus>.from(budgets)..sort((a, b) => b.pct.compareTo(a.pct));
    final display = shown.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Budgets', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetsScreen())),
              child: const Text('Manage')),
        ]),
        const SizedBox(height: 4),
        ...display.map((b) {
          final pct = b.pct.clamp(0.0, 1.0);
          final over = b.pct > 1.0;
          final color = over ? sem.expense : (b.pct > 0.8 ? const Color(0xFFF59E0B) : sem.income);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: parseHexColor(b.color), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(b.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Text('${(b.pct * 100).round()}%',
                    style: TextStyle(fontSize: 12, color: over ? sem.expense : cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                over ? 'Over by ${Money.fmt(b.spent - b.limit)}' : '${Money.fmt(b.spent)} of ${Money.fmt(b.limit)}',
                style: TextStyle(color: over ? sem.expense : cs.onSurfaceVariant, fontSize: 11),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 40, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Tap + to record your first income or expense.',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ]),
    );
  }
}
