import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_state.dart';
import '../theme.dart';

/// Icon key <-> IconData mapping used throughout the app.
const kIconOptions = <String, IconData>{
  'restaurant': Icons.restaurant_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'directions_car': Icons.directions_car_outlined,
  'home': Icons.home_outlined,
  'receipt': Icons.receipt_outlined,
  'favorite': Icons.favorite_outline,
  'movie': Icons.movie_outlined,
  'school': Icons.school_outlined,
  'payments': Icons.payments_outlined,
  'work': Icons.work_outline,
  'label': Icons.label_outline,
  'flight': Icons.flight_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'pets': Icons.pets_outlined,
  'music_note': Icons.music_note_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'child_care': Icons.child_care_outlined,
};

const kColorPresets = [
  '#FF7043', '#66BB6A', '#42A5F5', '#8D6E63', '#AB47BC', '#EF5350',
  '#FFA726', '#EC407A', '#5C6BC0', '#26A69A', '#26C6DA', '#9E9E9E',
  '#78909C', '#FF6E40', '#7CB342', '#29B6F6',
];

class CategoryEditorScreen extends StatelessWidget {
  const CategoryEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = context.watch<FinanceState>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: cats.isEmpty
          ? Center(child: Text('No categories', style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = cats[i];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: parseHexColor(c.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(kIconOptions[c.icon] ?? Icons.label_outline,
                          color: parseHexColor(c.color), size: 18),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(c.color,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _openSheet(context, existingId: c.id, name: c.name, color: c.color, icon: c.icon),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context,
      {int? existingId, String? name, String? color, String? icon}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CatSheet(existingId: existingId, name: name, color: color, icon: icon),
    );
  }
}

class _CatSheet extends StatefulWidget {
  final int? existingId;
  final String? name;
  final String? color;
  final String? icon;
  const _CatSheet({this.existingId, this.name, this.color, this.icon});

  @override
  State<_CatSheet> createState() => _CatSheetState();
}

class _CatSheetState extends State<_CatSheet> {
  late final TextEditingController _name;
  late String _color;
  late String _icon;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name ?? '');
    _color = widget.color ?? kColorPresets.first;
    _icon = widget.icon ?? 'label';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _busy = true);
    final state = context.read<FinanceState>();
    final ok = widget.existingId == null
        ? await state.createCategory(name: name, color: _color, icon: _icon)
        : await state.updateCategory(widget.existingId!, name: name, color: _color, icon: _icon);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Failed')));
    }
  }

  Future<void> _delete() async {
    final state = context.read<FinanceState>();
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('Transactions in this category will become Uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Delete', style: TextStyle(color: cs.error))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final success = await state.deleteCategory(widget.existingId!);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existingId != null;
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(isEdit ? 'Edit category' : 'New category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (isEdit)
                IconButton(
                    onPressed: _busy ? null : _delete,
                    icon: Icon(Icons.delete_outline, color: cs.error)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Category name'),
            ),
            const SizedBox(height: 16),
            Text('Color', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kColorPresets
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: parseHexColor(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _color == c ? cs.onSurface : Colors.transparent, width: 2),
                          ),
                          child: _color == c
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Icon', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kIconOptions.entries
                  .map((e) => ChoiceChip(
                        label: Icon(e.value, size: 18),
                        selected: _icon == e.key,
                        onSelected: (_) => setState(() => _icon = e.key),
                        showCheckmark: false,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
