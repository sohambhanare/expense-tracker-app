import 'category.dart';

enum TxnType { income, expense }

class Transaction {
  final int id;
  final TxnType type;
  final double amount;
  final String note;
  final DateTime date;
  final int? categoryId;
  final Category? category;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.category,
  });

  bool get isIncome => type == TxnType.income;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        type: TxnType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        note: (json['note'] ?? '') as String,
        date: DateTime.parse(json['date'] as String),
        categoryId: json['category_id'] as int?,
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toRequestJson() => {
        'type': type.name,
        'amount': amount,
        'note': note,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'category_id': categoryId,
      };
}
