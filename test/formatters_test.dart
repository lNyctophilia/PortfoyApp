import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/utils/formatters.dart';

void main() {
  group('Formatters Turkish Format & Parsing Tests', () {
    test('formatPriceGrouped formats integer with dot thousand separators', () {
      expect(Formatters.formatPriceGrouped(0), '0');
      expect(Formatters.formatPriceGrouped(100), '100');
      expect(Formatters.formatPriceGrouped(1000), '1.000');
      expect(Formatters.formatPriceGrouped(1234567), '1.234.567');
    });

    test('formatPriceGrouped formats decimals with comma', () {
      expect(Formatters.formatPriceGrouped(12.5), '12,50');
      expect(Formatters.formatPriceGrouped(1234.56), '1.234,56');
      expect(Formatters.formatPriceGrouped(0.123456), '0,123456');
    });

    test('parseDouble parses Turkish format correctly', () {
      expect(Formatters.parseDouble('1.250'), 1250.0);
      expect(Formatters.parseDouble('1.234,56'), 1234.56);
      expect(Formatters.parseDouble('0,5'), 0.5);
      expect(Formatters.parseDouble('1.000.000,75'), 1000000.75);
      expect(Formatters.parseDouble('250,00'), 250.0);
    });

    test('TurkishNumberInputFormatter formats while typing', () {
      final formatter = TurkishNumberInputFormatter(maxDecimals: 6);

      // Typing digits
      var res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(res.text, '1');

      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '1234', selection: TextSelection.collapsed(offset: 4)),
      );
      expect(res.text, '1.234');

      // Typing comma
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '1.234,', selection: TextSelection.collapsed(offset: 6)),
      );
      expect(res.text, '1.234,');

      // Typing decimal digits
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '1.234,5', selection: TextSelection.collapsed(offset: 7)),
      );
      expect(res.text, '1.234,5');

      // Typing dot instead of comma
      res = formatter.formatEditUpdate(
        const TextEditingValue(text: '123', selection: TextSelection.collapsed(offset: 3)),
        const TextEditingValue(text: '123.', selection: TextSelection.collapsed(offset: 4)),
      );
      expect(res.text, '123,');
    });
  });
}
