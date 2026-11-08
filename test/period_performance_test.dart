import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/widgets/period_performance_badge.dart';

void main() {
  group('PeriodPerformanceRow & AssetItemTile Integration Tests', () {
    final testAsset = PortfolioAsset(
      id: 'asset-1',
      symbol: 'THYAO',
      name: 'Türk Hava Yolları',
      category: AssetCategory.hisse,
      quantity: 10,
      purchasePrice: 200,
      currentPrice: 250,
      purchaseDate: DateTime.now().subtract(const Duration(days: 400)),
      dailyChangePercent: 2.5,
      weeklyChangePercent: 5.0,
      monthlyChangePercent: 10.0,
      threeMonthlyChangePercent: 15.0,
      sixMonthlyChangePercent: 20.0,
      yearlyChangePercent: 25.0,
    );

    test('PeriodPerformanceRow.fromAsset populates all 7 periods correctly', () {
      final row = PeriodPerformanceRow.fromAsset(
        testAsset,
        mode: ReturnCalculationMode.brut,
      );

      expect(row.dailyPercent, equals(2.5));
      expect(row.weeklyPercent, equals(5.0));
      expect(row.monthlyPercent, equals(10.0));
      expect(row.threeMonthlyPercent, equals(15.0));
      expect(row.sixMonthlyPercent, equals(20.0));
      expect(row.yearlyPercent, equals(25.0));
      expect(row.allTimePercent, equals(testAsset.totalProfitPercent));
    });

    testWidgets('PeriodPerformanceRow renders on desktop with expanded rows', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: PeriodPerformanceRow.fromAsset(
                testAsset,
                mode: ReturnCalculationMode.brut,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1G'), findsOneWidget);
      expect(find.text('1H'), findsOneWidget);
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('3A'), findsOneWidget);
      expect(find.text('6A'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('Ömür Boyu'), findsOneWidget);
    });

    testWidgets('PeriodPerformanceRow renders on mobile width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: PeriodPerformanceRow.fromAsset(
                testAsset,
                mode: ReturnCalculationMode.brut,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1G'), findsOneWidget);
      expect(find.text('1H'), findsOneWidget);
    });
  });
}
