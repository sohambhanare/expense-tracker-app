import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_state.dart';
import '../theme.dart';
import '../utils/format.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.watch<FinanceState>();
    final summary = finance.summary;
    final categories = finance.categories;
    final budgetByCat = {
      for (final b in (summary?.budgets ?? [])) b.categoryId: b,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: categories.isEmpty
          ? Center(
              child: Text('No categories yet',
                  style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final budget = budgetByCat[cat.id];
                final hasBudget = budget != null;
                final pct = (budget?.pct ?? 0).clamp(0.0, 1.0);
                final over = (budget?.pct ?? 0) > 1.0;
                final sem = context.sem;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: parseHexColor(cat.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.label_outline,
                          color: parseHexColor(cat.color), size: 18),
                    ),
                    title: Text(cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: hasBudget
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    over ? sem.expense : sem.income,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Money.fmt(budget.spent)} of ${Money.fmt(budget.limit)}'
                                ' • ${over ? 'Over by ${Money.fmt(budget.spent - budget.limit)}' : '${Money.fmt(budget.remaining)} left'}',
                                style: TextStyle(
                                  color: over ? sem.expense : cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: over ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          )
                        : Text('No budget set',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    trailing: TextButton(
                      onPressed: () => _editBudget(context, cat.id, cat.name, budget?.limit),
                      child: Text(hasBudget ? 'Edit' : 'Set'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editBudget(
      BuildContext context, int catId, String name, double? currentLimit) async {
    final ctrl = TextEditingController(
        text: currentLimit == null ? '' : currentLimit.toStringAsFixed(2));
    final cs = Theme.of(context).colorScheme;
    final res = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget — $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 400',
                prefixText: '${Money.fmt(0).characters.first} ',
                helperText: 'Monthly limit for this category',
              ),
            ),
            if (currentLimit != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(-1),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove budget'),
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    final finance = context.read<FinanceState>();
    if (res == -1) {
      final ok = await finance.deleteBudget(catId);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(finance.error ?? 'Failed')));
      }
    } else if (res != null) {
      final ok = await finance.setBudget(catId, res);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(finance.error ?? 'Failed')));
      }
    }
  }
}
