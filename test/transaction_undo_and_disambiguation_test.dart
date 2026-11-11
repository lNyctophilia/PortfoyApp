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
      expect(candidates.first, contains('paribas.svg'));

      final logo = MarketDataService.resolveFundLogo('TPZ', 'TEB Portföy Kira Sertifikaları (Döviz) Katılım Fonu');
      expect(logo, isNotNull);
      expect(logo, contains('paribas.svg'));
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

    test('GPN stock gets Global Payments logo and GPN fon gets Garanti logo without collision', () {
      final stockLogo = MarketDataService.getKnownAssetLogo('GPN', AssetCategory.hisse);
      expect(stockLogo, isNotNull);
      expect(stockLogo, contains('global-payments.svg'));

      final fundLogo = MarketDataService.getKnownAssetLogo('GPN', AssetCategory.fon, 'Garanti Portföy');
      expect(fundLogo, isNotNull);
      expect(fundLogo, contains('garanti.svg'));
      expect(fundLogo, isNot(contains('global-payments.svg')));
    });

    test('findCurated with AssetCategory.hisse does not return Garanti fund for GPN', () {
      final stockCurated = AssetCatalogService.findCurated('GPN', AssetCategory.hisse);
      expect(stockCurated, isNull); // GPN is not in local _knownStocks, searched via TradingView

      final fundCurated = AssetCatalogService.findCurated('GPN', AssetCategory.fon);
      expect(fundCurated, isNotNull);
      expect(fundCurated!.category, equals(AssetCategory.fon));
      expect(fundCurated.name, contains('Garanti Portföy'));
    });

    test('Self-healing restores Global Payments hisse if corrupted with Garanti logo', () async {
      final provider = PortfolioProvider();
      await provider.loadData();
      await provider.addPortfolio(name: 'US Stock Portfolio');
      final pId = provider.rawPortfolios.first.id;

      // Add Global Payments with mistaken Garanti logo
      final corruptedStockTx = PortfolioTransaction(
        id: 'tx_stock_gpn',
        portfolioId: pId,
        symbol: 'GPN',
        name: 'Global Payments Inc.',
        category: AssetCategory.hisse,
        type: TransactionType.alis,
        price: 95.0,
        quantity: 10,
        iconUrl: 'https://s3-symbol-logo.tradingview.com/garanti.svg',
        date: DateTime.now(),
      );
      await provider.addTransaction(pId, corruptedStockTx);

      final p = provider.getPortfolioById(pId);
      expect(p, isNotNull);
      final asset = p!.assets.firstWhere((a) => a.symbol == 'GPN' && a.category == AssetCategory.hisse);
      expect(asset.name, equals('Global Payments Inc.'));
      expect(asset.iconUrl, contains('global-payments.svg'));
      expect(asset.iconUrl, isNot(contains('garanti.svg')));
    });
  });

  group('TEFAS Satis Valor Business Day Calculation Tests', () {
    test('Para Piyasasi / Likit fon uses T-1 business day', () {
      final wednesday = DateTime(2026, 10, 21); // Çarşamba
      final valorDate = MarketDataService.getTefasSatisValorDate(
        wednesday,
        symbol: 'GPN',
        fundName: 'Garanti Portföy Para Piyasası Katılım (TL) Fonu',
      );
      // T-1 -> Salı 20
      expect(valorDate, equals(DateTime(2026, 10, 20)));
    });

    test('Standard domestic equity/gold fund uses T-2 business days skipping weekends', () {
      final wednesday = DateTime(2026, 10, 21); // Çarşamba
      final valorDate = MarketDataService.getTefasSatisValorDate(
        wednesday,
        symbol: 'KUT',
        fundName: 'KUVEYT TÜRK PORTFÖY KIYMETLİ MADENLER KATILIM FONU',
      );
      // T-2 -> Pazartesi 19
      expect(valorDate, equals(DateTime(2026, 10, 19)));

      // Pazartesi'den geriye 2 iş günü -> Cuma ve Perşembe
      final monday = DateTime(2026, 10, 19); // Pazartesi
      final mondayValor = MarketDataService.getTefasSatisValorDate(
        monday,
        symbol: 'KUT',
      );
      expect(mondayValor, equals(DateTime(2026, 10, 15))); // Perşembe
    });

    test('Foreign equity fund uses T-3 business days skipping weekends', () {
      final wednesday = DateTime(2026, 10, 21); // Çarşamba
      final valorDate = MarketDataService.getTefasSatisValorDate(
        wednesday,
        symbol: 'AFT',
        fundName: 'Ak Portföy Yeni Teknolojiler Yabancı Hisse Senedi Fonu',
      );
      // T-3: Salı 20 -> Pazartesi 19 -> Cuma 16
      expect(valorDate, equals(DateTime(2026, 10, 16)));
    });
  });
}
