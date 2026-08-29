class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final String locale;
  final int decimalDigits;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.locale,
    this.decimalDigits = 2,
  });
}

const List<CurrencyOption> kCurrencies = [
  CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar', locale: 'en_US'),
  CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro', locale: 'de_DE'),
  CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound', locale: 'en_GB'),
  CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee', locale: 'en_IN'),
  CurrencyOption(
      code: 'JPY', symbol: '¥', name: 'Japanese Yen', locale: 'ja_JP', decimalDigits: 0),
  CurrencyOption(
      code: 'KRW', symbol: '₩', name: 'South Korean Won', locale: 'ko_KR', decimalDigits: 0),
  CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', locale: 'zh_CN'),
  CurrencyOption(code: 'AUD', symbol: r'$', name: 'Australian Dollar', locale: 'en_AU'),
  CurrencyOption(code: 'CAD', symbol: r'$', name: 'Canadian Dollar', locale: 'en_CA'),
  CurrencyOption(code: 'NZD', symbol: r'$', name: 'New Zealand Dollar', locale: 'en_NZ'),
  CurrencyOption(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc', locale: 'de_CH'),
  CurrencyOption(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', locale: 'sv_SE'),
  CurrencyOption(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', locale: 'nb_NO'),
  CurrencyOption(code: 'DKK', symbol: 'kr', name: 'Danish Krone', locale: 'da_DK'),
  CurrencyOption(code: 'PLN', symbol: 'zł', name: 'Polish Zloty', locale: 'pl_PL'),
  CurrencyOption(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna', locale: 'cs_CZ'),
  CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira', locale: 'tr_TR'),
  CurrencyOption(code: 'RUB', symbol: '₽', name: 'Russian Ruble', locale: 'ru_RU'),
  CurrencyOption(code: 'BRL', symbol: r'R$', name: 'Brazilian Real', locale: 'pt_BR'),
  CurrencyOption(code: 'MXN', symbol: r'$', name: 'Mexican Peso', locale: 'es_MX'),
  CurrencyOption(code: 'ZAR', symbol: 'R', name: 'South African Rand', locale: 'en_ZA'),
  CurrencyOption(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', locale: 'en_NG'),
  CurrencyOption(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling', locale: 'sw_KE'),
  CurrencyOption(code: 'GHS', symbol: '₵', name: 'Ghanaian Cedi', locale: 'en_GH'),
  CurrencyOption(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound', locale: 'ar_EG'),
  CurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', locale: 'ar_AE'),
  CurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', locale: 'ar_SA'),
  CurrencyOption(code: 'ILS', symbol: '₪', name: 'Israeli Shekel', locale: 'he_IL'),
  CurrencyOption(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee', locale: 'ur_PK'),
  CurrencyOption(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka', locale: 'bn_BD'),
  CurrencyOption(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee', locale: 'si_LK'),
  CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht', locale: 'th_TH'),
  CurrencyOption(code: 'VND', symbol: '₫', name: 'Vietnamese Dong', locale: 'vi_VN', decimalDigits: 0),
  CurrencyOption(
      code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', locale: 'id_ID', decimalDigits: 0),
  CurrencyOption(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', locale: 'ms_MY'),
  CurrencyOption(code: 'PHP', symbol: '₱', name: 'Philippine Peso', locale: 'fil_PH'),
  CurrencyOption(code: 'SGD', symbol: r'$', name: 'Singapore Dollar', locale: 'en_SG'),
  CurrencyOption(code: 'HKD', symbol: r'HK$', name: 'Hong Kong Dollar', locale: 'zh_HK'),
];

CurrencyOption findCurrency(String code) {
  for (final c in kCurrencies) {
    if (c.code == code) return c;
  }
  return kCurrencies.first;
}
