import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';

void main() {
  group('Realized Profit & Transaction tests', () {
    test('Calculates realized profit accurately on sell transactions', () {
      final tx = PortfolioTransaction(
        id: 'tx-1',
        portfolioId: 'p-1',
        type: TransactionType.satis,
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        category: AssetCategory.hisse,
        date: DateTime.now(),
        quantity: 10,
        price: 300, // Satış fiyatı
        costPrice: 200, // Alış maliyeti
      );

      // (300 - 200) * 10 = 1000
      expect(tx.realizedProfit, 1000.0);
      expect(tx.profitPercent, 50.0);
    });

    test('Portfolio sums realized profit correctly across transactions', () {
      final p = Portfolio(
        id: 'p-1',
        name: 'Test Portfolio',
        createdAt: DateTime.now(),
        assets: [],
        transactions: [
          PortfolioTransaction(
            id: 'tx-1',
            portfolioId: 'p-1',
            type: TransactionType.satis,
            symbol: 'THYAO',
            name: 'THY',
            category: AssetCategory.hisse,
            date: DateTime.now(),
            quantity: 10,
            price: 300,
            costPrice: 200,
          ), // +1000
          PortfolioTransaction(
            id: 'tx-2',
            portfolioId: 'p-1',
            type: TransactionType.satis,
            symbol: 'ASELS',
            name: 'Aselsan',
            category: AssetCategory.hisse,
            date: DateTime.now(),
            quantity: 5,
            price: 50,
            costPrice: 60,
          ), // -50
          PortfolioTransaction(
            id: 'tx-3',
            portfolioId: 'p-1',
            type: TransactionType.alis,
            symbol: 'GARAN',
            name: 'Garanti',
            category: AssetCategory.hisse,
            date: DateTime.now(),
            quantity: 20,
            price: 100,
          ), // 0
        ],
      );

      expect(p.realizedProfit, 950.0);
    });

    test('Portfolio calculates allTimeProfitPercent and earliestPurchaseDate correctly', () {
      final earlierDate = DateTime(2023, 1, 15);
      final laterDate = DateTime(2023, 6, 20);

      final p = Portfolio(
        id: 'p-2',
        name: 'Test Portfolio 2',
        createdAt: DateTime(2023, 10, 1),
        assets: [
          PortfolioAsset(
            id: 'a-1',
            name: 'THY',
            symbol: 'THYAO',
            category: AssetCategory.hisse,
            purchaseDate: laterDate,
            purchasePrice: 100,
            quantity: 10, // Cost = 1000
            currentPrice: 150, // Value = 1500 -> Profit = 500 (+50%)
          ),
        ],
        transactions: [
          PortfolioTransaction(
            id: 'tx-0',
            portfolioId: 'p-2',
            type: TransactionType.alis,
            symbol: 'KCHOL',
            name: 'Koç Holding',
            category: AssetCategory.hisse,
            date: earlierDate,
            quantity: 5,
            price: 50,
          ),
        ],
      );

      expect(p.earliestPurchaseDate, earlierDate);
      expect(p.allTimeProfitPercent, 50.0);
    });

    test('Portfolio handles isVisible and serialization correctly', () {
      final p = Portfolio(
        id: 'p-vis',
        name: 'Visible Test',
        createdAt: DateTime.now(),
        assets: [],
        isVisible: false,
      );

      expect(p.isVisible, false);

      final copy = p.copyWith(isVisible: true);
      expect(copy.isVisible, true);

      final json = p.toJson();
      expect(json['isVisible'], false);

      final restored = Portfolio.fromJson(json);
      expect(restored.isVisible, false);
    });
  });
}
