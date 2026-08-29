import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../state/finance_state.dart';
import '../state/settings_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/txn_tile.dart';
import 'txn_sheet.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final finance = context.watch<FinanceState>();
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            onChanged: finance.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search notes or categories…',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(
              child: SegmentedButton<TypeFilter>(
                segments: const [
                  ButtonSegment(value: TypeFilter.all, label: Text('All')),
                  ButtonSegment(value: TypeFilter.income, label: Text('In')),
                  ButtonSegment(value: TypeFilter.expense, label: Text('Out')),
                ],
                selected: {finance.typeFilter},
                onSelectionChanged: (s) => finance.setTypeFilter(s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  side: WidgetStatePropertyAll(BorderSide(color: cs.outlineVariant)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: finance.monthAnchor ?? now,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Pick any day in the target month',
                );
                if (picked != null) finance.setMonth(DateTime(picked.year, picked.month));
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
            ),
            if (finance.filtersActive)
              IconButton.outlined(onPressed: finance.clearFilters, icon: const Icon(Icons.filter_alt_off_outlined, size: 20)),
          ]),
        ),
        if (finance.monthAnchor != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(monthLabel(finance.monthAnchor!)),
                onDeleted: () => finance.setMonth(null),
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide.none,
              ),
            ),
          ),
        Expanded(child: _list(context, finance)),
      ]),
    );
  }

  Widget _list(BuildContext context, FinanceState finance) {
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    if (finance.transactionsState == LoadState.loading && finance.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (finance.transactionsState == LoadState.error && finance.transactions.isEmpty) {
      return Center(
          child: Text(finance.error ?? 'Failed to load',
              style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center));
    }
    final items = finance.visibleTransactions;
    if (items.isEmpty) {
      return Center(
          child: Text('Nothing here.\nTry changing filters or add a transaction.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)));
    }

    final groups = <String, List<Transaction>>{};
    for (final t in items) {
      (groups[Dates.day(t.date)] ??= []).add(t);
    }
    final keys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: () => finance.loadTransactions(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final key = keys[i];
          final dayTxns = groups[key]!;
          final dayNet = dayTxns.fold<double>(0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Row(children: [
                Text(key, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(Money.fmt(dayNet),
                    style: TextStyle(
                        color: dayNet >= 0 ? sem.income : sem.expense, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            ...dayTxns.map((t) => TxnTile(txn: t, onTap: () => openEditTransaction(context, existing: t))),
          ]);
        },
      ),
    );
  }
}

String monthLabel(DateTime d) {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[d.month - 1]} ${d.year}';
}
