class CategorySlice {
  final int? categoryId;
  final String name;
  final String color;
  final double total;
  final double share; // 0..1

  const CategorySlice({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.total,
    required this.share,
  });

  factory CategorySlice.fromJson(Map<String, dynamic> json) => CategorySlice(
        categoryId: json['category_id'] as int?,
        name: json['name'] as String,
        color: json['color'] as String,
        total: (json['total'] as num).toDouble(),
        share: (json['share'] as num).toDouble(),
      );
}

class BudgetStatus {
  final int categoryId;
  final String name;
  final String color;
  final double limit;
  final double spent;
  final double pct;
  final double remaining;

  const BudgetStatus({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.limit,
    required this.spent,
    required this.pct,
    required this.remaining,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) => BudgetStatus(
        categoryId: json['category_id'] as int,
        name: json['name'] as String,
        color: json['color'] as String,
        limit: (json['limit'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        pct: (json['pct'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
      );
}

class MonthlyPoint {
  final String month; // "2026-08"
  final double income;
  final double expense;
  final double net;

  const MonthlyPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        month: json['month'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
      );
}

class Budget {
  final int id;
  final int categoryId;
  final double monthlyLimit;

  const Budget({required this.id, required this.categoryId, required this.monthlyLimit});

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      );
}

class Summary {
  final double balance;
  final double monthIncome;
  final double monthExpense;
  final double monthNet;
  final List<CategorySlice> topCategories;
  final List<MonthlyPoint> trend;
  final List<BudgetStatus> budgets;

  const Summary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthNet,
    required this.topCategories,
    required this.trend,
    this.budgets = const [],
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        balance: (json['balance'] as num).toDouble(),
        monthIncome: (json['month_income'] as num).toDouble(),
        monthExpense: (json['month_expense'] as num).toDouble(),
        monthNet: (json['month_net'] as num).toDouble(),
        topCategories: (json['top_categories'] as List<dynamic>)
            .map((e) => CategorySlice.fromJson(e as Map<String, dynamic>))
            .toList(),
        trend: (json['trend'] as List<dynamic>)
            .map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgets: (json['budgets'] as List<dynamic>?)
                ?.map((e) => BudgetStatus.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
