import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/utils/fifo_calculator.dart';

void main() {
  group('FifoCalculator Tests', () {
    final now = DateTime.now();

    test('Single initial lot without transactions', () {
      final asset = PortfolioAsset(
        id: 'asset-1',
        name: 'Bitcoin',
        symbol: 'BTC',
        category: AssetCategory.kripto,
        purchaseDate: now.subtract(const Duration(days: 30)),
        purchasePrice: 60000.0,
        quantity: 2.0,
        currentPrice: 70000.0,
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Test Portfolio',
        createdAt: now,
        assets: [asset],
        transactions: [],
      );

      final result = FifoCalculator.calculate(portfolio, 'BTC', assetFallback: asset);

      expect(result.allLots.length, 1);
      expect(result.remainingQuantity, 2.0);
      expect(result.averageRemainingCost, 60000.0);
      expect(result.allLots.first.isActive, true);
    });

    test('Multiple buy lots and partial FIFO sale', () {
      final buy1 = PortfolioTransaction(
        id: 'tx1',
        portfolioId: 'p1',
        type: TransactionType.alis,
        symbol: 'BTC',
        name: 'Bitcoin',
        category: AssetCategory.kripto,
        date: now.subtract(const Duration(days: 20)),
        quantity: 100.0,
        price: 10.0, // Maliyet: 1000
      );

      final buy2 = PortfolioTransaction(
        id: 'tx2',
        portfolioId: 'p1',
        type: TransactionType.alis,
        symbol: 'BTC',
        name: 'Bitcoin',
        category: AssetCategory.kripto,
        date: now.subtract(const Duration(days: 10)),
        quantity: 50.0,
        price: 20.0, // Maliyet: 1000
      );

      // Satış: 120 adet @ 30.0
      // FIFO: 100 adet @ 10.0 + 20 adet @ 20.0
      // Satış maliyeti: 1000 + 400 = 1400 (Birim maliyet: 1400 / 120 = 11.6667)
      // Satış geliri: 120 * 30 = 3600
      // Gerçekleşen kâr: 3600 - 1400 = 2200
      // Kalan lot: buy2'den 30 adet @ 20.0 (Kalan maliyet: 600, Ortalama: 20.0)
      final sale1 = PortfolioTransaction(
        id: 'tx3',
        portfolioId: 'p1',
        type: TransactionType.satis,
        symbol: 'BTC',
        name: 'Bitcoin',
        category: AssetCategory.kripto,
        date: now.subtract(const Duration(days: 5)),
        quantity: 120.0,
        price: 30.0,
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Test Portfolio',
        createdAt: now,
        assets: [],
        transactions: [buy1, buy2, sale1],
      );

      final result = FifoCalculator.calculate(portfolio, 'BTC');

      expect(result.allLots.length, 2);
      expect(result.allLots[0].isFullySold, true);
      expect(result.allLots[0].remainingQuantity, 0.0);
      expect(result.allLots[1].isPartiallySold, true);
      expect(result.allLots[1].remainingQuantity, 30.0);

      expect(result.remainingQuantity, 30.0);
      expect(result.averageRemainingCost, 20.0);
      expect(result.remainingCost, 600.0);

      expect(result.saleRecords.length, 1);
      final saleRecord = result.saleRecords.first;
      expect(saleRecord.totalSaleCost, 1400.0);
      expect(saleRecord.realizedProfit, 2200.0);
      expect(saleRecord.consumptions.length, 2);
      expect(saleRecord.consumptions[0].quantityConsumed, 100.0);
      expect(saleRecord.consumptions[1].quantityConsumed, 20.0);
    });

    test('Estimate sale cost for proposed sale quantity', () {
      final buy1 = PortfolioTransaction(
        id: 'tx1',
        portfolioId: 'p1',
        type: TransactionType.alis,
        symbol: 'THYAO',
        name: 'THY',
        category: AssetCategory.hisse,
        date: now.subtract(const Duration(days: 10)),
        quantity: 10.0,
        price: 100.0,
      );
      final buy2 = PortfolioTransaction(
        id: 'tx2',
        portfolioId: 'p1',
        type: TransactionType.alis,
        symbol: 'THYAO',
        name: 'THY',
        category: AssetCategory.hisse,
        date: now.subtract(const Duration(days: 5)),
        quantity: 10.0,
        price: 200.0,
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Test Portfolio',
        createdAt: now,
        assets: [],
        transactions: [buy1, buy2],
      );

      // 15 adet satılmak istendiğinde:
      // 10 adet @ 100 + 5 adet @ 200 = 1000 + 1000 = 2000
      // Birim maliyet = 2000 / 15 = 133.3333...
      final est = FifoCalculator.estimateSaleCost(portfolio, 'THYAO', 15.0);

      expect(est.hasEnoughHoldings, true);
      expect(est.totalCost, 2000.0);
      expect(est.unitCost, closeTo(133.33, 0.01));
    });
  });
}
