import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/summary.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/utils/csv.dart';
import 'package:expense_tracker/utils/format.dart';

void main() {
  group('Transaction model', () {
    test('parses JSON with nested category', () {
      final t = Transaction.fromJson({
        'id': 1,
        'type': 'expense',
        'amount': 24.5,
        'note': 'Lunch',
        'date': '2026-08-20',
        'category_id': 3,
        'category': {'id': 3, 'name': 'Food & Drinks', 'color': '#FF7043', 'icon': 'restaurant'},
      });

      expect(t.id, 1);
      expect(t.type, TxnType.expense);
      expect(t.isIncome, isFalse);
      expect(t.amount, 24.5);
      expect(t.category?.name, 'Food & Drinks');
    });

    test('serializes back to request JSON', () {
      final t = Transaction.fromJson({
        'id': 1,
        'type': 'income',
        'amount': 3500,
        'note': 'Salary',
        'date': '2026-08-01',
        'category_id': null,
        'category': null,
      });

      final json = t.toRequestJson();
      expect(json['type'], 'income');
      expect(json['date'], '2026-08-01');
      expect(json['category_id'], isNull);
    });

    test('handles all txn types round-trip', () {
      for (final type in TxnType.values) {
        final t = Transaction.fromJson({
          'id': 2,
          'type': type.name,
          'amount': 10,
          'note': '',
          'date': '2026-01-15',
          'category_id': null,
          'category': null,
        });
        expect(t.type, type);
      }
    });
  });

  group('Summary model', () {
    test('parses stats payload', () {
      final s = Summary.fromJson({
        'balance': 100.5,
        'month_income': 200,
        'month_expense': 99.5,
        'month_net': 100.5,
        'top_categories': [
          {'category_id': 1, 'name': 'Food', 'color': '#FF0000', 'total': 50, 'share': 0.5},
        ],
        'trend': [
          {'month': '2026-08', 'income': 200, 'expense': 100, 'net': 100},
        ],
      });

      expect(s.balance, 100.5);
      expect(s.topCategories.first.name, 'Food');
      expect(s.trend.first.net, 100);
      expect(s.budgets, isEmpty);
    });

    test('parses budgets in summary', () {
      final s = Summary.fromJson({
        'balance': 500,
        'month_income': 1000,
        'month_expense': 500,
        'month_net': 500,
        'top_categories': [],
        'trend': [],
        'budgets': [
          {
            'category_id': 1,
            'name': 'Food',
            'color': '#FF7043',
            'limit': 400,
            'spent': 150,
            'pct': 0.375,
            'remaining': 250,
          },
          {
            'category_id': 2,
            'name': 'Transport',
            'color': '#42A5F5',
            'limit': 200,
            'spent': 220,
            'pct': 1.1,
            'remaining': -20,
          },
        ],
      });

      expect(s.budgets.length, 2);
      expect(s.budgets.first.pct, closeTo(0.375, 0.001));
      expect(s.budgets[1].remaining, -20);
      expect(s.budgets[1].pct, greaterThan(1.0));
    });

    test('budget model round-trip', () {
      final b = Budget.fromJson({'id': 1, 'category_id': 3, 'monthly_limit': 500});
      expect(b.monthlyLimit, 500);
      expect(b.categoryId, 3);
    });
  });

  group('Formatting', () {
    test('money formats with dollar sign', () {
      Money.configure(findCurrency('USD'));
      expect(Money.fmt(1234.5), contains('1,234.50'));
    });

    test('money respects currency config', () {
      Money.configure(findCurrency('EUR'));
      expect(Money.fmt(1234.5), contains('€'));
      Money.configure(findCurrency('JPY'));
      // JPY has 0 decimals
      expect(Money.fmt(1000), isNot(contains('.')));
      // Reset to USD for other tests
      Money.configure(findCurrency('USD'));
    });

    test('money signed includes sign', () {
      Money.configure(findCurrency('USD'));
      expect(Money.signed(50, income: true), contains('+'));
      expect(Money.signed(50, income: false), contains('-'));
    });

    test('month labels', () {
      expect(Dates.monthShort('2026-08'), 'Aug');
      expect(Dates.month('2026-08'), 'August 2026');
      expect(Dates.day(DateTime(2026, 8, 20)), contains('Aug'));
    });

    test('currency catalog', () {
      expect(findCurrency('EUR').symbol, '€');
      expect(findCurrency('UNKNOWN').code, 'USD');
      expect(kCurrencies.length, greaterThan(20));
    });
  });

  group('CSV', () {
    test('buildCsv escapes quotes and commas', () {
      final t = Transaction.fromJson({
        'id': 1,
        'type': 'expense',
        'amount': 12.5,
        'note': 'Lunch, with "boss"',
        'date': '2026-08-10',
        'category_id': 1,
        'category': {'id': 1, 'name': 'Food, Drinks', 'color': '#FF0000', 'icon': 'restaurant'},
      });
      final csv = buildCsv([t]);
      expect(csv, contains('Date,Type,Category,Note,Amount'));
      expect(csv, contains('"Food, Drinks"'));
      expect(csv, contains('"Lunch, with ""boss"""'));
    });

    test('buildCsv handles uncategorized', () {
      final t = Transaction.fromJson({
        'id': 2,
        'type': 'income',
        'amount': 1000,
        'note': '',
        'date': '2026-08-01',
        'category_id': null,
        'category': null,
      });
      final csv = buildCsv([t]);
      expect(csv, contains('Uncategorized'));
    });
  });
}
