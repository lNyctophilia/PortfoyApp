import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/utils/formatters.dart';

void main() {
  group('Formatters Price & Number Parsing Tests', () {
    test('parseDouble handles single comma and dot correctly', () {
      expect(Formatters.parseDouble('125,50'), 125.5);
      expect(Formatters.parseDouble('125.50'), 125.5);
      expect(Formatters.parseDouble('0,45'), 0.45);
      expect(Formatters.parseDouble('0.45'), 0.45);
      expect(Formatters.parseDouble('1000'), 1000.0);
    });

    test('parseDouble handles thousand separators properly', () {
      expect(Formatters.parseDouble('1.250,50'), 1250.5);
      expect(Formatters.parseDouble('1,250.50'), 1250.5);
      expect(Formatters.parseDouble('1.000.000'), 1000000.0);
      expect(Formatters.parseDouble('1,000,000'), 1000000.0);
    });

    test('formatPrice formats with comma as decimal separator', () {
      expect(Formatters.formatPrice(125.50), '125,50');
      expect(Formatters.formatPrice(1.2345), '1,2345');
      expect(Formatters.formatPrice(0.004567), '0,004567');
      expect(Formatters.formatPrice(0), '0');
    });

    test('formatNumber formats with comma as decimal separator', () {
      expect(Formatters.formatNumber(10), '10');
      expect(Formatters.formatNumber(10.5), '10,5');
    });
  });

  group('Formatters formatDuration Tests', () {
    test('calculates duration in months and days correctly', () {
      final start = DateTime(2026, 7, 1);
      final end = DateTime(2026, 10, 3);
      expect(Formatters.formatDuration(start, end), '3 ay 2 gün');
    });

    test('calculates duration with years, months, and days', () {
      final start = DateTime(2024, 5, 10);
      final end = DateTime(2026, 8, 15);
      expect(Formatters.formatDuration(start, end), '2 yıl 3 ay 5 gün');
    });

    test('handles same day or future date gracefully', () {
      final today = DateTime(2026, 10, 28);
      expect(Formatters.formatDuration(today, today), '0 gün');
      expect(Formatters.formatDuration(DateTime(2026, 11, 1), today), '0 gün');
    });

    test('handles month end day boundary correctly', () {
      final start = DateTime(2026, 1, 31);
      final end = DateTime(2026, 3, 1);
      expect(Formatters.formatDuration(start, end), '1 ay 1 gün');
    });
  });
}
