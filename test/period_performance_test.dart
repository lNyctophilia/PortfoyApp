import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/services/inflation_service.dart';
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

    test('Empty portfolio in Reel mode yields all periods 0.0 (no negative inflation applied)', () {
      final emptyPortfolio = Portfolio(
        id: 'empty_port',
        name: 'Boş Portföy',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        assets: [],
      );

      final row = PeriodPerformanceRow.fromPortfolio(
        emptyPortfolio,
        mode: ReturnCalculationMode.reel,
        periodInflation: const PeriodInflationData(
          daily: 0.06,
          weekly: 0.43,
          monthly: 1.85,
          threeMonthly: 5.62,
          sixMonthly: 11.45,
          yearly: 32.50,
          latestYear: 2026,
          latestMonth: 10,
        ),
      );

      expect(row.dailyPercent, equals(0.0));
      expect(row.weeklyPercent, equals(0.0));
      expect(row.monthlyPercent, equals(0.0));
      expect(row.threeMonthlyPercent, equals(0.0));
      expect(row.sixMonthlyPercent, equals(0.0));
      expect(row.yearlyPercent, equals(0.0));
      expect(row.allTimePercent, equals(0.0));
    });

    test('Asset and Portfolio bought today in Reel mode do not apply weekly inflation', () {
      final todayAsset = PortfolioAsset(
        id: 'asset_today',
        symbol: 'KCHOL',
        name: 'Koç Holding',
        category: AssetCategory.hisse,
        quantity: 100,
        purchasePrice: 200,
        currentPrice: 200,
        purchaseDate: DateTime.now(),
        dailyChangePercent: 0.0,
        weeklyChangePercent: -2.0, // market weekly
      );

      final todayPortfolio = Portfolio(
        id: 'today_port',
        name: 'Bugün Açılan Portföy',
        createdAt: DateTime.now(),
        assets: [todayAsset],
      );

      const inflationData = PeriodInflationData(
        daily: 0.06,
        weekly: 0.43,
        monthly: 1.85,
        threeMonthly: 5.62,
        sixMonthly: 11.45,
        yearly: 32.50,
        latestYear: 2026,
        latestMonth: 10,
      );

      // Portfolio row
      final pRow = PeriodPerformanceRow.fromPortfolio(
        todayPortfolio,
        mode: ReturnCalculationMode.reel,
        periodInflation: inflationData,
      );

      expect(pRow.weeklyPercent, equals(0.0)); // <7 days -> neutral 0.0, not negative
      expect(pRow.monthlyPercent, equals(0.0));
      expect(pRow.dailyPercent, equals(0.0)); // holdingDays < 1 -> no daily inflation deducted

      // Asset row
      final aRow = PeriodPerformanceRow.fromAsset(
        todayAsset,
        mode: ReturnCalculationMode.reel,
        periodInflation: inflationData,
      );

      expect(aRow.weeklyPercent, equals(0.0));
      expect(aRow.monthlyPercent, equals(0.0));
      expect(aRow.dailyPercent, equals(0.0));
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
