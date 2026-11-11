import 'package:flutter/services.dart';
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
    final sign = value < 0 ? '-' : '';
    return '$sign%${value.abs().toStringAsFixed(2).replaceAll('.', ',')}';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    final safeDiff = diff < 0 ? 0 : diff;
    return '$safeDiff Gün';
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

  /// Fiyatı Türk sayı standardına göre formatlar: Binlikler '.', kuruş/ondalık ','
  /// Örn: 1250.5 -> "1.250,5", 1234567.89 -> "1.234.567,89", 0.123456 -> "0,123456"
  static String formatPriceGrouped(double val, {int maxDecimals = 6, bool trimZeros = true}) {
    if (val == 0) return '0';

    // 7. basamak kontrolü (fon veya mikro-kriptolar için)
    final s7 = val.toStringAsFixed(7);
    final int decimals = (!s7.endsWith('0')) ? 7 : maxDecimals;

    final fixedStr = val.toStringAsFixed(decimals);
    final parts = fixedStr.split('.');
    String intPart = parts[0];
    String fracPart = parts.length > 1 ? parts[1] : '';

    if (trimZeros && fracPart.isNotEmpty) {
      while (fracPart.length > 2 && fracPart.endsWith('0')) {
        fracPart = fracPart.substring(0, fracPart.length - 1);
      }
    }

    // Binlik nokta ekleme
    final isNegative = intPart.startsWith('-');
    if (isNegative) intPart = intPart.substring(1);

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(intPart[i]);
    }
    final formattedInt = (isNegative ? '-' : '') + buffer.toString();

    if (fracPart.isEmpty || (trimZeros && (fracPart == '00' || fracPart == '0'))) {
      return formattedInt;
    }
    return '$formattedInt,$fracPart';
  }

  static String formatPrice(double val) {
    return formatPriceGrouped(val);
  }

  /// Birim fiyat ve maliyetleri Türk formatında gösterir (en az 2, varsa 6-7 basamağa kadar ondalık)
  static String formatCurrencyPrice(double val) {
    if (val == 0) return '0,00 ₺';
    final formatted = formatPriceGrouped(val);
    if (!formatted.contains(',')) {
      return '$formatted,00 ₺';
    }
    final parts = formatted.split(',');
    if (parts.length > 1 && parts[1].length == 1) {
      return '${parts[0]},${parts[1]}0 ₺';
    }
    return '$formatted ₺';
  }

  static String formatNumber(double val) {
    if (val == val.roundToDouble()) return formatPriceGrouped(val, maxDecimals: 0);
    return formatPriceGrouped(val, maxDecimals: 4);
  }

  static double parseDouble(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 0.0;

    // Virgül varsa Türk formatı: nokta binlik, virgül ondalık
    if (clean.contains(',')) {
      final normalized = clean.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }

    // Virgül yoksa ve nokta varsa
    if (clean.contains('.')) {
      final dotCount = clean.split('.').length - 1;
      // Birden fazla nokta varsa (örn: 1.250.000) kesinlikle binlik ayracıdır
      if (dotCount > 1) {
        return double.tryParse(clean.replaceAll('.', '')) ?? 0.0;
      }
      // Tek nokta varsa: Eğer noktadan sonra tam 3 basamak varsa ve sayı 1000'lik basamak uyumluysa (örn 1.250)
      final parts = clean.split('.');
      if (parts[1].length == 3 && parts[0].isNotEmpty && parts[0].length <= 3 && !parts[0].startsWith('0')) {
        return double.tryParse(clean.replaceAll('.', '')) ?? 0.0;
      }
      return double.tryParse(clean) ?? 0.0;
    }

    return double.tryParse(clean) ?? 0.0;
  }
}

/// Türk sayı giriş formatlayıcısı: Binlikler '.', kuruş/ondalık ','
class TurkishNumberInputFormatter extends TextInputFormatter {
  final int maxDecimals;
  final bool allowDecimals;

  TurkishNumberInputFormatter({
    this.maxDecimals = 6,
    this.allowDecimals = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }

    // Kullanıcı nokta tuşuna basarsa kabul etme (nokta manuel koyulamaz)
    if (newValue.text.length > oldValue.text.length) {
      final start = oldValue.selection.start;
      final end = newValue.selection.end;
      if (start >= 0 && end >= start && end <= newText.length) {
        final inserted = newText.substring(start, end);
        if (inserted == '.') {
          return oldValue;
        }
      }
    }

    // Silme durumunda: Eğer kullanıcı noktayı sildiyse (örn "1.250"deki '.' silinmeye çalışıldıysa)
    // Noktadan önceki basamağı da silerek kullanıcının takılmasını önle
    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.end > 0 &&
        oldValue.text[oldValue.selection.end - 1] == '.') {
      final delPos = oldValue.selection.end - 1;
      if (delPos > 0) {
        final adjusted = oldValue.text.substring(0, delPos - 1) +
            oldValue.text.substring(delPos);
        return formatEditUpdate(
          oldValue,
          TextEditingValue(
            text: adjusted,
            selection: TextSelection.collapsed(offset: delPos - 1),
          ),
        );
      }
    }

    // Tek bir virgüle izin ver (virgül varsa ayrıştır)
    final hasCommaInInput = allowDecimals && newText.contains(',');
    final rawParts = newText.split(',');

    // Tam sayı kısmı: Noktaları ve rakam dışı tüm karakterleri temizle
    var rawInt = rawParts[0].replaceAll(RegExp(r'[^0-9]'), '');
    String? rawDec;

    if (hasCommaInInput && rawParts.length > 1) {
      // Virgülden sonraki ondalık kısmı: sadece rakamlar
      rawDec = rawParts.sublist(1).join('').replaceAll(RegExp(r'[^0-9]'), '');
    }

    // Eğer tam sayı boşsa ama virgül varsa '0' ile başlat
    if (rawInt.isEmpty) {
      if (hasCommaInInput) {
        rawInt = '0';
      } else {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    }

    // Baştaki fazla sıfırları temizle (örn: 05 -> 5, ama tek başına 0 kalabilir)
    if (rawInt.length > 1 && rawInt.startsWith('0')) {
      rawInt = rawInt.replaceFirst(RegExp(r'^0+'), '');
      if (rawInt.isEmpty) rawInt = '0';
    }

    // Binlik gruplama ekle (sağdan sola 3'erli '.')
    final formattedInt = StringBuffer();
    for (int i = 0; i < rawInt.length; i++) {
      if (i > 0 && (rawInt.length - i) % 3 == 0) {
        formattedInt.write('.');
      }
      formattedInt.write(rawInt[i]);
    }

    String result = formattedInt.toString();
    if (rawDec != null) {
      if (rawDec.length > maxDecimals) {
        rawDec = rawDec.substring(0, maxDecimals);
      }
      result += ',$rawDec';
    } else if (hasCommaInInput || (allowDecimals && newText.endsWith(','))) {
      result += ',';
    }

    // İmleç pozisyonunu hassas ve hatasız hesapla
    int intDigitsBeforeCursor = 0;
    bool isCursorAfterComma = false;
    int decDigitsBeforeCursor = 0;

    final cursorLimit = newValue.selection.end.clamp(0, newText.length);
    for (int i = 0; i < cursorLimit; i++) {
      final char = newText[i];
      if (char == ',') {
        isCursorAfterComma = true;
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        if (isCursorAfterComma) {
          decDigitsBeforeCursor++;
        } else {
          intDigitsBeforeCursor++;
        }
      }
    }

    int newOffset = 0;
    if (!isCursorAfterComma) {
      if (intDigitsBeforeCursor == 0) {
        newOffset = 0;
      } else {
        int counted = 0;
        for (int i = 0; i < result.length; i++) {
          if (result[i] == ',') break;
          if (RegExp(r'[0-9]').hasMatch(result[i])) {
            counted++;
            if (counted == intDigitsBeforeCursor) {
              newOffset = i + 1;
              break;
            }
          }
        }
      }
    } else {
      final commaIdx = result.indexOf(',');
      if (commaIdx == -1) {
        newOffset = result.length;
      } else if (decDigitsBeforeCursor == 0) {
        newOffset = commaIdx + 1;
      } else {
        int counted = 0;
        newOffset = commaIdx + 1;
        for (int i = commaIdx + 1; i < result.length; i++) {
          if (RegExp(r'[0-9]').hasMatch(result[i])) {
            counted++;
            if (counted == decDigitsBeforeCursor) {
              newOffset = i + 1;
              break;
            }
          }
        }
      }
    }

    if (newOffset > result.length) newOffset = result.length;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
