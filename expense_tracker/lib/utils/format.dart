import 'package:intl/intl.dart';

import 'currency.dart';

class Money {
  static CurrencyOption _current = kCurrencies.first;
  static NumberFormat? _currencyFmt;
  static NumberFormat? _compactFmt;

  static void configure(CurrencyOption c) {
    _current = c;
    _currencyFmt = null;
    _compactFmt = null;
  }

  static NumberFormat get _currency => _currencyFmt ??= NumberFormat.currency(
        locale: _current.locale,
        symbol: _current.symbol,
        decimalDigits: _current.decimalDigits,
      );

  static NumberFormat get _compact => _compactFmt ??= NumberFormat.compactCurrency(
        locale: _current.locale,
        symbol: _current.symbol,
        decimalDigits: _current.decimalDigits == 0 ? 0 : 1,
      );

  static String fmt(num v) => _currency.format(v);
  static String compact(num v) => _compact.format(v);

  static String signed(num v, {required bool income}) =>
      '${income ? '+' : '-'}${_currency.format(v.abs())}';
}

class Dates {
  static final _monthFmt = DateFormat('MMMM yyyy');
  static final _dayFmt = DateFormat('EEE, MMM d');

  static String month(String yyyyMm) {
    final parts = yyyyMm.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return _monthFmt.format(DateTime(dt.year, dt.month));
  }

  static String monthShort(String yyyyMm) {
    final parts = yyyyMm.split('-');
    return DateFormat('MMM').format(
      DateTime(int.parse(parts[0]), int.parse(parts[1])),
    );
  }

  static String day(DateTime d) => _dayFmt.format(d);

  static String shortDate(DateTime d) =>
      '${d.day} ${DateFormat.MMM().format(d)}';
}
