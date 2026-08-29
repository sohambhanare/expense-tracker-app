import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme.dart';
import '../utils/format.dart';

class TxnTile extends StatelessWidget {
  final Transaction txn;
  final VoidCallback? onTap;

  const TxnTile({super.key, required this.txn, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    final category = txn.category;
    final catColor = category != null ? parseHexColor(category.color) : cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFor(category?.icon), color: catColor, size: 20),
        ),
        title: Text(
          txn.note.isEmpty ? (category?.name ?? 'Uncategorized') : txn.note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          category?.name ?? 'Uncategorized',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Text(
          Money.signed(txn.amount, income: txn.isIncome),
          style: TextStyle(
            color: txn.isIncome ? sem.income : sem.expense,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? icon) => switch (icon) {
        'restaurant' => Icons.restaurant_outlined,
        'shopping_cart' => Icons.shopping_cart_outlined,
        'shopping_bag' => Icons.shopping_bag_outlined,
        'directions_car' => Icons.directions_car_outlined,
        'home' => Icons.home_outlined,
        'receipt' => Icons.receipt_outlined,
        'favorite' => Icons.favorite_outline,
        'movie' => Icons.movie_outlined,
        'school' => Icons.school_outlined,
        'payments' => Icons.payments_outlined,
        'work' => Icons.work_outline,
        'flight' => Icons.flight_outlined,
        'local_cafe' => Icons.local_cafe_outlined,
        'fitness_center' => Icons.fitness_center_outlined,
        'pets' => Icons.pets_outlined,
        'music_note' => Icons.music_note_outlined,
        'sports_esports' => Icons.sports_esports_outlined,
        'child_care' => Icons.child_care_outlined,
        _ => Icons.label_outline,
      };
}
