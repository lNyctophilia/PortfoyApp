import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/services/inflation_service.dart';
import 'package:portfoy_app/widgets/period_performance_badge.dart';

void main() {
  group('InflationService and Real Return Tests', () {
    test('Calculates real return percentage with Fisher equation', () {
      // Örnek 1: Nominal %50 getiri, %25 enflasyon
      // (1 + 0.50) / (1 + 0.25) - 1 = 1.50 / 1.25 - 1 = 0.20 -> %20
      final realRate1 = InflationService.calculateRealReturnPercent(
        nominalReturnPercent: 50.0,
        inflationPercent: 25.0,
      );
      expect(realRate1, 20.0);

      // Örnek 2: Nominal %10 getiri, %20 enflasyon (negatif reel getiri)
      // (1 + 0.10) / (1 + 0.20) - 1 = 1.10 / 1.20 - 1 = -0.0833 -> -%8.33
      final realRate2 = InflationService.calculateRealReturnPercent(
        nominalReturnPercent: 10.0,
        inflationPercent: 20.0,
      );
      expect(realRate2, -8.33);

      // Örnek 3: Enflasyon 0 olduğunda reel getiri nominal getiriye eşittir
      final realRate3 = InflationService.calculateRealReturnPercent(
        nominalReturnPercent: 15.0,
        inflationPercent: 0.0,
      );
      expect(realRate3, 15.0);
    });

    test('Calculates real profit amount correctly', () {
      // 10.000 TL maliyet, %40 enflasyon -> düzeltilmiş maliyet 14.000 TL
      // Güncel değer 18.000 TL -> Reel Kâr: 4.000 TL
      final realProfit = InflationService.calculateRealProfitAmount(
        currentValue: 18000.0,
        totalCost: 10000.0,
        inflationPercent: 40.0,
      );
      expect(realProfit, 4000.0);
    });

    test('Computes inflation from fallback TÜFE index table when offline', () async {
      // 2023-1 TÜFE (1203.48) ile 2024-1 TÜFE (1984.02) arası değişim:
      // (1984.02 - 1203.48) / 1203.48 * 100 = 64.86%
      final info = await InflationService.fetchInflationRate(
        startYear: 2023,
        startMonth: 1,
        endYear: 2024,
        endMonth: 1,
      );

      expect(info.inflationRate, closeTo(64.86, 0.1));
      expect(info.startYear, 2023);
      expect(info.endYear, 2024);
    });

    test('Same period inflation is 0%', () async {
      final info = await InflationService.fetchInflationRate(
        startYear: 2024,
        startMonth: 5,
        endYear: 2024,
        endMonth: 5,
      );
      expect(info.inflationRate, 0.0);
    });

    test('Portfolio aggregates real profits across multiple assets with different inflation rates', () {
      final asset1 = PortfolioAsset(
        id: 'a1',
        name: 'Hisse 1',
        symbol: 'HIS1',
        category: AssetCategory.hisse,
        purchaseDate: DateTime(2023, 1, 1),
        purchasePrice: 100.0,
        quantity: 100, // Maliyet: 10.000 TL
        currentPrice: 150.0, // Değer: 15.000 TL
      );

      final asset2 = PortfolioAsset(
        id: 'a2',
        name: 'Hisse 2',
        symbol: 'HIS2',
        category: AssetCategory.hisse,
        purchaseDate: DateTime(2024, 1, 1),
        purchasePrice: 200.0,
        quantity: 100, // Maliyet: 20.000 TL
        currentPrice: 220.0, // Değer: 22.000 TL
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Test Portföyü',
        createdAt: DateTime(2023, 1, 1),
        assets: [asset1, asset2],
      );

      // a1 için %30 enflasyon, a2 için %20 enflasyon varsayalım
      final inflationRates = {
        'a1': 30.0, // Düzeltilmiş maliyet: 13.000, Reel kâr: 2.000
        'a2': 20.0, // Düzeltilmiş maliyet: 24.000, Reel kâr: -2.000
      };

      // Toplam Nominal Kâr: 37.000 - 30.000 = 7.000 TL
      expect(portfolio.totalProfit, 7000.0);
      expect(portfolio.profitForMode(ReturnCalculationMode.brut), 7000.0);

      // Toplam Reel Kâr: 2.000 + (-2.000) = 0.0 TL
      expect(portfolio.realTotalProfit(inflationRates), 0.0);
      expect(portfolio.profitForMode(ReturnCalculationMode.reel, inflationRates), 0.0);
      expect(portfolio.profitPercentForMode(ReturnCalculationMode.reel, inflationRates), 0.0);
      expect(portfolio.realCost(inflationRates), 37000.0);
    });

    test('getPeriodInflationRates returns 1A, 3A, 6A, 1Y official rates and daily/weekly compounding', () async {
      final periodData = await InflationService.getPeriodInflationRates();

      expect(periodData.monthly, greaterThan(0.0));
      expect(periodData.threeMonthly, greaterThan(periodData.monthly));
      expect(periodData.sixMonthly, greaterThan(periodData.threeMonthly));
      expect(periodData.yearly, greaterThan(periodData.sixMonthly));
      expect(periodData.daily, greaterThan(0.0));
      expect(periodData.weekly, greaterThan(periodData.daily));
    });

    test('Holding less than 1 year calculates pro-rata monthly TÜFE inflation and does not return 0%', () async {
      final now = DateTime.now();

      // 15 gün önce alınan varlık
      final inf15d = await InflationService.getInflationSince(
        now.subtract(const Duration(days: 15)),
        now,
      );
      expect(inf15d, greaterThan(0.0));
      expect(inf15d, lessThan(2.0));

      // 30 gün (1 ay) önce alınan varlık
      final inf1m = await InflationService.getInflationSince(
        now.subtract(const Duration(days: 30)),
        now,
      );
      expect(inf1m, greaterThan(inf15d));

      // 90 gün (3 ay) önce alınan varlık
      final inf3m = await InflationService.getInflationSince(
        now.subtract(const Duration(days: 90)),
        now,
      );
      expect(inf3m, greaterThan(inf1m));

      // 180 gün (6 ay) önce alınan varlık
      final inf6m = await InflationService.getInflationSince(
        now.subtract(const Duration(days: 180)),
        now,
      );
      expect(inf6m, greaterThan(inf3m));
    });

    test('PeriodPerformanceRow applies Fisher equation in reel mode', () {
      final now = DateTime.now();
      final asset = PortfolioAsset(
        id: 'p_asset',
        name: 'Aselsan',
        symbol: 'ASELS',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 400)),
        purchasePrice: 100,
        quantity: 10,
        currentPrice: 150,
        dailyChangePercent: 2.0,
        weeklyChangePercent: 5.0,
        monthlyChangePercent: 10.0,
        threeMonthlyChangePercent: 20.0,
        sixMonthlyChangePercent: 35.0,
        yearlyChangePercent: 60.0,
      );

      final p = Portfolio(
        id: 'p_test',
        name: 'Dönemsel Test Portföyü',
        createdAt: now.subtract(const Duration(days: 400)),
        assets: [asset],
      );

      const periodInflation = PeriodInflationData(
        daily: 0.06,
        weekly: 0.42,
        monthly: 2.0,
        threeMonthly: 5.0,
        sixMonthly: 12.0,
        yearly: 30.0,
        latestYear: 2026,
        latestMonth: 9,
      );

      // Brüt mod (nominal değerler)
      final rowBrut = PeriodPerformanceRow.fromPortfolio(
        p,
        mode: ReturnCalculationMode.brut,
      );
      expect(rowBrut.monthlyPercent, closeTo(10.0, 0.01));
      expect(rowBrut.yearlyPercent, closeTo(60.0, 0.01));

      // Reel mod (TÜFE düşülmüş reel getiriler)
      // 1 Aylık: (1 + 0.10) / (1 + 0.02) - 1 = 1.10 / 1.02 - 1 = 7.84%
      // 1 Yıllık: (1 + 0.60) / (1 + 0.30) - 1 = 1.60 / 1.30 - 1 = 23.08%
      final rowReel = PeriodPerformanceRow.fromPortfolio(
        p,
        mode: ReturnCalculationMode.reel,
        periodInflation: periodInflation,
      );

      expect(rowReel.monthlyPercent, closeTo(7.84, 0.05));
      expect(rowReel.yearlyPercent, closeTo(23.08, 0.05));
    });
  });
}
