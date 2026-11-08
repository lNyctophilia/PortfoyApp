import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 1,
  );

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy', 'tr_TR');

  static String currency(double value) {
    return _currencyFormat.format(value);
  }

  static String compactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return _compactCurrencyFormat.format(value);
    }
    return _currencyFormat.format(value);
  }

  static String percent(double value, {bool includeSign = true}) {
    if (!includeSign) {
      return '%${value.abs().toStringAsFixed(2).replaceAll('.', ',')}';
    }
    final sign = value > 0 ? '+' : '';
    return '$sign%${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  static String monthYear(DateTime date) {
    try {
      return _monthYearFormat.format(date);
    } catch (_) {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  static String daysAgo(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    if (diff < 30) return '$diff gün önce';
    if (diff < 365) return '${(diff / 30).floor()} ay önce';
    return '${(diff / 365).toStringAsFixed(1)} yıl önce';
  }

  static String formatDuration(DateTime startDate, [DateTime? endDate]) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final now = endDate ?? DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    if (end.isBefore(start)) {
      return '0 gün';
    }

    int years = 0;
    int months = 0;

    DateTime addYearsAndMonths(int y, int m) {
      final totalMonths = (start.year + y) * 12 + (start.month - 1) + m;
      final year = totalMonths ~/ 12;
      final month = (totalMonths % 12) + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final day = start.day > daysInMonth ? daysInMonth : start.day;
      return DateTime(year, month, day);
    }

    while (true) {
      final next = addYearsAndMonths(years + 1, 0);
      if (!next.isAfter(end)) {
        years++;
      } else {
        break;
      }
    }

    while (true) {
      final next = addYearsAndMonths(years, months + 1);
      if (!next.isAfter(end)) {
        months++;
      } else {
        break;
      }
    }

    final reachedDate = addYearsAndMonths(years, months);
    final days = end.difference(reachedDate).inDays;

    final parts = <String>[];
    if (years > 0) parts.add('$years yıl');
    if (months > 0) parts.add('$months ay');
    if (days > 0) parts.add('$days gün');

    if (parts.isEmpty) {
      return '0 gün';
    }

    return parts.join(' ');
  }

  static String formatPrice(double val) {
    if (val == 0) return '0';
    // 7. hane sıfır değilse 7 basamak, aksi halde 6 basamak
    final s7 = val.toStringAsFixed(7);
    final str = (!s7.endsWith('0')) ? s7 : val.toStringAsFixed(6);
    return str.replaceAll('.', ',');
  }

  static String formatNumber(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString().replaceAll('.', ',');
  }

  static double parseDouble(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 0.0;

    if (clean.contains('.') && clean.contains(',')) {
      final lastDot = clean.lastIndexOf('.');
      final lastComma = clean.lastIndexOf(',');
      if (lastDot > lastComma) {
        return double.tryParse(clean.replaceAll(',', '')) ?? 0.0;
      } else {
        return double.tryParse(clean.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
      }
    }

    if (clean.contains(',')) {
      final commaCount = clean.split(',').length - 1;
      if (commaCount > 1) {
        return double.tryParse(clean.replaceAll(',', '')) ?? 0.0;
      }
      return double.tryParse(clean.replaceAll(',', '.')) ?? 0.0;
    }

    if (clean.contains('.')) {
      final dotCount = clean.split('.').length - 1;
      if (dotCount > 1) {
        return double.tryParse(clean.replaceAll('.', '')) ?? 0.0;
      }
      return double.tryParse(clean) ?? 0.0;
    }

    return double.tryParse(clean) ?? 0.0;
  }
}
