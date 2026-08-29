import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F1115);
  static const surface = Color(0xFF171B22);
  static const surfaceAlt = Color(0xFF1F252E);
  static const border = Color(0xFF2A303B);

  static const accent = Color(0xFF2DD4A7);
  static const accentDark = Color(0xFF0E9F6E);
  static const income = Color(0xFF2DD4A7);
  static const expense = Color(0xFFFF6B6B);

  static const textPrimary = Color(0xFFF2F4F7);
  static const textSecondary = Color(0xFF9AA3B2);
}

class AppSemantics extends ThemeExtension<AppSemantics> {
  final Color income;
  final Color expense;
  final Color balanceStart;
  final Color balanceEnd;
  final Color balanceBorder;

  const AppSemantics({
    required this.income,
    required this.expense,
    required this.balanceStart,
    required this.balanceEnd,
    required this.balanceBorder,
  });

  @override
  ThemeExtension<AppSemantics> copyWith({
    Color? income,
    Color? expense,
    Color? balanceStart,
    Color? balanceEnd,
    Color? balanceBorder,
  }) =>
      AppSemantics(
        income: income ?? this.income,
        expense: expense ?? this.expense,
        balanceStart: balanceStart ?? this.balanceStart,
        balanceEnd: balanceEnd ?? this.balanceEnd,
        balanceBorder: balanceBorder ?? this.balanceBorder,
      );

  @override
  ThemeExtension<AppSemantics> lerp(
      covariant ThemeExtension<AppSemantics>? other, double t) {
    if (other is! AppSemantics) return this;
    return AppSemantics(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      balanceStart: Color.lerp(balanceStart, other.balanceStart, t)!,
      balanceEnd: Color.lerp(balanceEnd, other.balanceEnd, t)!,
      balanceBorder: Color.lerp(balanceBorder, other.balanceBorder, t)!,
    );
  }

  static const dark = AppSemantics(
    income: Color(0xFF2DD4A7),
    expense: Color(0xFFFF6B6B),
    balanceStart: Color(0xFF134E48),
    balanceEnd: Color(0xFF0B2B26),
    balanceBorder: Color(0xFF1E4A40),
  );

  static const light = AppSemantics(
    income: Color(0xFF0E7A5E),
    expense: Color(0xFFDC2626),
    balanceStart: Color(0xFF134E48),
    balanceEnd: Color(0xFF0B2B26),
    balanceBorder: Color(0xFF1E4A40),
  );
}

extension SemanticX on BuildContext {
  AppSemantics get sem => Theme.of(this).extension<AppSemantics>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
}

class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E9F6E),
      brightness: Brightness.light,
    );
    return _build(cs, AppSemantics.light, isDark: false);
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E9F6E),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF171B22),
      onSurface: const Color(0xFFF2F4F7),
      surfaceContainerHighest: const Color(0xFF1F252E),
      outlineVariant: const Color(0xFF2A303B),
      primary: const Color(0xFF2DD4A7),
      onPrimary: const Color(0xFF04150F),
      error: const Color(0xFFFF6B6B),
    );
    return _build(cs, AppSemantics.dark, isDark: true);
  }

  static ThemeData _build(ColorScheme cs, AppSemantics sem,
      {required bool isDark}) {
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF6F7F9);
    final onBg = isDark ? const Color(0xFFF2F4F7) : const Color(0xFF0F172A);
    final card = isDark ? const Color(0xFF171B22) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A303B) : const Color(0xFFE2E8F0);
    final fillColor = isDark ? const Color(0xFF1F252E) : const Color(0xFFF1F5F9);
    final hintColor = isDark ? const Color(0xFF9AA3B2) : const Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      extensions: [sem],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onBg,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onBg),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: hintColor),
        labelStyle: TextStyle(color: hintColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: cs.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hintColor,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? cs.primary : hintColor,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: fillColor,
        contentTextStyle: TextStyle(color: onBg),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(color: cardBorder),
      chipTheme: ChipThemeData(
        backgroundColor: fillColor,
        side: BorderSide.none,
        labelStyle: TextStyle(color: onBg, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

Color parseHexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}
