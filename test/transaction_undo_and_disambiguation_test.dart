import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';
import 'package:portfoy_app/services/asset_catalog_service.dart';
import 'package:portfoy_app/services/market_data_service.dart';

void main() {
  group('TEB Fund Logos & Resolution Tests', () {
    test('resolveFundLogoCandidates returns valid logos for TEB funds', () {
      final candidates = MarketDataService.resolveFundLogoCandidates(
        'TPZ',
        'TEB Portföy Kira Sertifikaları (Döviz) Katılım Fonu',
      );
      expect(candidates, isNotEmpty);
      expect(candidates.first, contains('teb.svg'));

      final logo = MarketDataService.resolveFundLogo('TPZ', 'TEB Portföy Kira Sertifikaları (Döviz) Katılım Fonu');
      expect(logo, isNotNull);
      expect(logo, contains('teb.svg'));
    });
  });

  group('TPZ Disambiguation & BYF Catalog Tests', () {
    test('TPZ search returns TEFAS fund and does not drop duplicates with different categories/byf', () async {
      final results = await AssetCatalogService.search(query: 'TPZ');
      expect(results, isNotEmpty);
      final hasTefasTpz = results.any(
        (r) => r.symbol == 'TPZ' && r.category == AssetCategory.fon && !r.isByf,
      );
      expect(hasTefasTpz, isTrue);
    });

    test('BYF items have isByf flag set to true', () async {
      final results = await AssetCatalogService.search(query: 'GLDTR');
      expect(results, isNotEmpty);
      final gldtr = results.firstWhere((r) => r.symbol == 'GLDTR');
      expect(gldtr.isByf, isTrue);
    });
  });

  group('Transaction Undo (Rollback) Tests', () {
    test('Undoing a single Alis transaction completely removes the asset from portfolio', () async {
      final provider = PortfolioProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.loadData();

      // Add portfolio
      await provider.addPortfolio(name: 'Test Portfolio 1');
      final pId = provider.rawPortfolios.first.id;

      // Add Alis transaction
      final tx = PortfolioTransaction(
        id: 'tx_1',
        portfolioId: pId,
        assetId: 'asset_1',
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        category: AssetCategory.hisse,
        type: TransactionType.alis,
        price: 300.0,
        quantity: 10.0,
        date: DateTime.now(),
      );

      await provider.addTransaction(pId, tx);
      expect(provider.rawPortfolios.first.assets.length, equals(1));
      expect(provider.rawPortfolios.first.assets.first.quantity, equals(10.0));

      // Undo Alis transaction
      await provider.deleteTransaction(pId, 'tx_1');

      // Asset must be completely removed because remaining quantity is 0
      expect(provider.rawPortfolios.first.assets.isEmpty, isTrue);
      expect(provider.rawPortfolios.first.transactions.isEmpty, isTrue);
    });

    test('Undoing the latest of two Alis transactions reduces quantity and recalculates average cost', () async {
      final provider = PortfolioProvider();
      await provider.loadData();
      await provider.addPortfolio(name: 'Test Portfolio 2');
      final pId = provider.rawPortfolios.first.id;

      // Tx 1: 10 units at 100 TL
      final tx1 = PortfolioTransaction(
        id: 'tx_1',
        portfolioId: pId,
        symbol: 'ASELS',
        name: 'Aselsan',
        category: AssetCategory.hisse,
        type: TransactionType.alis,
        price: 100.0,
        quantity: 10.0,
        date: DateTime(2026, 1, 1),
      );
      await provider.addTransaction(pId, tx1);

      // Tx 2: 10 units at 200 TL (Avg cost: 150 TL, total qty: 20)
      final tx2 = PortfolioTransaction(
        id: 'tx_2',
        portfolioId: pId,
        symbol: 'ASELS',
        name: 'Aselsan',
        category: AssetCategory.hisse,
        type: TransactionType.alis,
        price: 200.0,
        quantity: 10.0,
        date: DateTime(2026, 1, 2),
      );
      await provider.addTransaction(pId, tx2);

      expect(provider.rawPortfolios.first.assets.first.quantity, equals(20.0));
      expect(provider.rawPortfolios.first.assets.first.purchasePrice, equals(150.0));

      // Undo Tx 2
      await provider.deleteTransaction(pId, 'tx_2');

      // Quantity should be 10 and price should be restored to 100.0
      expect(provider.rawPortfolios.first.assets.first.quantity, equals(10.0));
      expect(provider.rawPortfolios.first.assets.first.purchasePrice, equals(100.0));
    });
  });

  group('GPN & TEFAS Fund Protection and Self-Healing Tests', () {
    test('isKnownTefasFund identifies GPN as a known TEFAS fund', () {
      expect(AssetCatalogService.isKnownTefasFund('GPN'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('gpn'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('AAPL'), isFalse);
    });

    test('Self-healing restores corrupted GPN asset name and logo from Global Payments', () async {
      final provider = PortfolioProvider();
      await provider.loadData();
      await provider.addPortfolio(name: 'GPN Portföyü');
      final pId = provider.rawPortfolios.first.id;

      // Add corrupted GPN asset with Global Payments Inc.
      final corruptedTx = PortfolioTransaction(
        id: 'tx_gpn',
        portfolioId: pId,
        symbol: 'GPN',
        name: 'Global Payments Inc.',
        category: AssetCategory.fon,
        type: TransactionType.alis,
        price: 1.5,
        quantity: 1000,
        date: DateTime.now(),
      );
      await provider.addTransaction(pId, corruptedTx);

      final p = provider.getPortfolioById(pId);
      expect(p, isNotNull);
      final asset = p!.assets.firstWhere((a) => a.symbol == 'GPN');
      expect(asset.name, contains('Garanti Portföy'));
      expect(asset.name, isNot(contains('Global Payments')));

      final tx = p.transactions.firstWhere((t) => t.symbol == 'GPN');
      expect(tx.name, contains('Garanti Portföy'));
    });
  });
}
