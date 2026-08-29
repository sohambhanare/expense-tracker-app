import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../state/finance_state.dart';
import '../state/settings_state.dart';
import '../theme.dart';
import '../utils/currency.dart';
import '../utils/format.dart';

Future<void> openEditTransaction(
  BuildContext context, {
  Transaction? existing,
}) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TxnSheet(existing: existing),
  );
}

class _TxnSheet extends StatefulWidget {
  final Transaction? existing;

  const _TxnSheet({this.existing});

  @override
  State<_TxnSheet> createState() => _TxnSheetState();
}

class _TxnSheetState extends State<_TxnSheet> {
  late TxnType _type;
  late TextEditingController _amount;
  late TextEditingController _note;
  late DateTime _date;
  int? _categoryId;
  bool _busy = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = context.read<FinanceState>();
    final t = widget.existing;
    _type = t?.type ?? TxnType.expense;
    _amount = TextEditingController(text: t == null ? '' : t.amount.toStringAsFixed(2));
    _note = TextEditingController(text: t?.note ?? '');
    _date = t?.date ?? DateTime.now();
    _categoryId = t?.categoryId ?? state.categories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _busy = true);
    final state = context.read<FinanceState>();
    final txn = Transaction(
      id: widget.existing?.id ?? 0,
      type: _type,
      amount: amount,
      note: _note.text.trim(),
      date: _date,
      categoryId: _categoryId,
      category: state.categories.where((c) => c.id == _categoryId).firstOrNull,
    );
    final ok = widget.existing == null
        ? await state.saveTransaction(txn)
        : await state.editTransaction(widget.existing!.id, txn);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Could not save transaction')),
      );
    }
  }

  Future<void> _delete() async {
    final state = context.read<FinanceState>();
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final ok = await state.removeTransaction(widget.existing!.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<FinanceState>().categories;
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    final forType = _type;
    final curSymbol = findCurrency(context.watch<SettingsState>().currencyCode).symbol;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null ? 'New transaction' : 'Edit transaction',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (widget.existing != null)
                  IconButton(
                    onPressed: _busy ? null : _delete,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<TxnType>(
              segments: const [
                ButtonSegment(
                  value: TxnType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_outward, size: 18),
                ),
                ButtonSegment(
                  value: TxnType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward, size: 18),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
              style: ButtonStyle(
                side: WidgetStateProperty.all(BorderSide(color: cs.outlineVariant)),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return forType == TxnType.income
                        ? sem.income.withValues(alpha: 0.18)
                        : sem.expense.withValues(alpha: 0.18);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: widget.existing == null,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '$curSymbol ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final selected = c.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = c.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? parseHexColor(c.color).withValues(alpha: 0.22)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? parseHexColor(c.color)
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? parseHexColor(c.color)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(Dates.shortDate(_date)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _note,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Note (optional)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.existing == null ? 'Add' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewTransactionSheet {
  static Future<void> open(BuildContext context) => openEditTransaction(context);
}
