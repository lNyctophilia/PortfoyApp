import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';

void main() {
  group('Period Performance Tests', () {
    test('Portfolio younger than 1 year does not show yearly data', () {
      final now = DateTime.now();
      final assetRecent = PortfolioAsset(
        id: '1',
        name: 'ASELS',
        symbol: 'ASELS',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 45)),
        purchasePrice: 100,
        quantity: 10,
        currentPrice: 120,
        dailyChangePercent: 2.0,
        weeklyChangePercent: 5.0,
        monthlyChangePercent: 10.0,
        threeMonthlyChangePercent: 25.0,
        sixMonthlyChangePercent: 40.0,
        yearlyChangePercent: 80.0,
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Test Portföy',
        createdAt: now.subtract(const Duration(days: 45)),
        assets: [assetRecent],
      );

      expect(portfolio.hasDailyData, isTrue);
      expect(portfolio.hasWeeklyData, isTrue);
      expect(portfolio.hasMonthlyData, isTrue);
      expect(portfolio.hasThreeMonthlyData, isFalse);
      expect(portfolio.hasSixMonthlyData, isFalse);
      expect(portfolio.hasYearlyData, isFalse);
    });

    test('Portfolio older than 1 year shows yearly data', () {
      final now = DateTime.now();
      final assetOld = PortfolioAsset(
        id: '1',
        name: 'THYAO',
        symbol: 'THYAO',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 400)),
        purchasePrice: 100,
        quantity: 10,
        currentPrice: 200,
        yearlyChangePercent: 100.0,
      );

      final portfolio = Portfolio(
        id: 'p2',
        name: 'Eski Portföy',
        createdAt: now.subtract(const Duration(days: 400)),
        assets: [assetOld],
      );

      expect(portfolio.hasDailyData, isTrue);
      expect(portfolio.hasWeeklyData, isTrue);
      expect(portfolio.hasMonthlyData, isTrue);
      expect(portfolio.hasThreeMonthlyData, isTrue);
      expect(portfolio.hasSixMonthlyData, isTrue);
      expect(portfolio.hasYearlyData, isTrue);
    });

    test('Asset holding period correctly bounds period profit to totalProfit when held less than period', () {
      final now = DateTime.now();
      final asset = PortfolioAsset(
        id: '1',
        name: 'KCHOL',
        symbol: 'KCHOL',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 10)),
        purchasePrice: 100,
        quantity: 10,
        currentPrice: 105,
        yearlyChangePercent: 150.0, // Market yearly gain
      );

      // Asset held for 10 days, total profit is (105 - 100) * 10 = 50.
      expect(asset.totalProfit, 50.0);
      expect(asset.yearlyProfit, 50.0); // Does NOT take the 150% market gain!
      expect(asset.hasYearlyData, isFalse);
      expect(asset.hasWeeklyData, isTrue);
      expect(asset.hasMonthlyData, isFalse);
    });
  });
}

