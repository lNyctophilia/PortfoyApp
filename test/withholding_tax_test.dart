import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/services/market_data_service.dart';

void main() {
  group('Stopaj (Withholding Tax) Tests', () {
    test('Default withholding tax rate detection based on fund title', () {
      // Hisse Senedi Yoğun Fon -> %0
      expect(
        MarketDataService.defaultWithholdingTaxRate(
          AssetCategory.fon,
          'İŞ PORTFÖY HİSSE SENEDİ (TL) FONU (HİSSE SENEDİ YOĞUN FON)',
          'TI2',
        ),
        0.0,
      );

      expect(
        MarketDataService.defaultWithholdingTaxRate(
          AssetCategory.fon,
          'MARMARA CAPITAL PORTFÖY HİSSE SENEDİ YOĞUN FON',
          'MAC',
        ),
        0.0,
      );

      // Diğer Fonlar (Para piyasası, değişken vb.) -> %17.5
      expect(
        MarketDataService.defaultWithholdingTaxRate(
          AssetCategory.fon,
          'TERA PORTFÖY BİRİNCİ SERBEST FON',
          'TLY',
        ),
        17.5,
      );

      expect(
        MarketDataService.defaultWithholdingTaxRate(
          AssetCategory.fon,
          'TACİRLER PORTFÖY DEĞİŞKEN FON',
          'TCD',
        ),
        17.5,
      );

      // Fon dışı kategoriler -> %0
      expect(
        MarketDataService.defaultWithholdingTaxRate(
          AssetCategory.hisse,
          'THY',
          'THYAO',
        ),
        0.0,
      );
    });

    test('Fund asset stopaj and net profit calculation when in profit', () {
      final now = DateTime.now();
      // 100 adet 10 TL'den alındı, güncel fiyat 20 TL (Kâr: 1000 TL, Stopaj: %17.5)
      final fundAsset = PortfolioAsset(
        id: 'f1',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        symbol: 'TCD',
        category: AssetCategory.fon,
        purchaseDate: now,
        purchasePrice: 10.0,
        quantity: 100.0,
        currentPrice: 20.0,
        withholdingTaxRate: 17.5,
      );

      expect(fundAsset.totalCost, 1000.0);
      expect(fundAsset.currentValue, 2000.0);
      expect(fundAsset.totalProfit, 1000.0);
      expect(fundAsset.effectiveWithholdingTaxRate, 17.5);

      // Stopaj kesintisi = 1000 * 0.175 = 175 TL
      expect(fundAsset.withholdingTaxAmount, 175.0);
      // Net kâr = 1000 - 175 = 825 TL
      expect(fundAsset.netProfit, 825.0);
      // Net değer = 2000 - 175 = 1825 TL
      expect(fundAsset.netCurrentValue, 1825.0);
      // Net birim fiyat = 1825 / 100 = 18.25 TL
      expect(fundAsset.netCurrentPrice, 18.25);
    });

    test('Fund asset in loss has ZERO stopaj (zararlarda stopaj olmaz)', () {
      final now = DateTime.now();
      // 100 adet 20 TL'den alındı, güncel fiyat 15 TL (Zarar: -500 TL)
      final fundAsset = PortfolioAsset(
        id: 'f2',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        symbol: 'TCD',
        category: AssetCategory.fon,
        purchaseDate: now,
        purchasePrice: 20.0,
        quantity: 100.0,
        currentPrice: 15.0,
        withholdingTaxRate: 17.5,
      );

      expect(fundAsset.totalProfit, -500.0);
      // Zararda stopaj kesilmez
      expect(fundAsset.withholdingTaxAmount, 0.0);
      expect(fundAsset.netProfit, -500.0);
      expect(fundAsset.netCurrentValue, 1500.0);
      expect(fundAsset.netCurrentPrice, 15.0);
    });

    test('Realized profit on fund sale applies stopaj on profits only', () {
      final now = DateTime.now();
      // Kârlı satış: 50 adet, 10 TL maliyet, 20 TL satış fiyatı -> Kâr: 500 TL, Stopaj: 87.50 TL
      final profitableSale = PortfolioTransaction(
        id: 'tx1',
        portfolioId: 'p1',
        type: TransactionType.satis,
        symbol: 'TCD',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        category: AssetCategory.fon,
        date: now,
        quantity: 50.0,
        price: 20.0,
        costPrice: 10.0,
        withholdingTaxRate: 17.5,
      );

      expect(profitableSale.realizedProfit, 500.0);
      expect(profitableSale.withholdingTax, 87.5);
      expect(profitableSale.netRealizedProfit, 412.5);

      // Zararlı satış: 50 adet, 20 TL maliyet, 10 TL satış fiyatı -> Zarar: -500 TL
      final lossSale = PortfolioTransaction(
        id: 'tx2',
        portfolioId: 'p1',
        type: TransactionType.satis,
        symbol: 'TCD',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        category: AssetCategory.fon,
        date: now,
        quantity: 50.0,
        price: 10.0,
        costPrice: 20.0,
        withholdingTaxRate: 17.5,
      );

      expect(lossSale.realizedProfit, -500.0);
      // Zararlı satışta stopaj kesintisi 0'dır
      expect(lossSale.withholdingTax, 0.0);
      expect(lossSale.netRealizedProfit, -500.0);
    });

    test('Portfolio net totals reflect stopaj deductions correctly', () {
      final now = DateTime.now();
      final fundInProfit = PortfolioAsset(
        id: 'f1',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        symbol: 'TCD',
        category: AssetCategory.fon,
        purchaseDate: now,
        purchasePrice: 10.0,
        quantity: 100.0,
        currentPrice: 20.0,
        withholdingTaxRate: 17.5, // 1000 TL kâr -> 175 TL stopaj
      );

      final stockAsset = PortfolioAsset(
        id: 's1',
        name: 'TÜRK HAVA YOLLARI',
        symbol: 'THYAO',
        category: AssetCategory.hisse,
        purchaseDate: now,
        purchasePrice: 200.0,
        quantity: 10.0,
        currentPrice: 250.0, // 500 TL kâr -> 0 TL stopaj
      );

      final saleTx = PortfolioTransaction(
        id: 'tx1',
        portfolioId: 'p1',
        type: TransactionType.satis,
        symbol: 'TCD',
        name: 'TACİRLER PORTFÖY DEĞİŞKEN FON',
        category: AssetCategory.fon,
        date: now,
        quantity: 50.0,
        price: 20.0,
        costPrice: 10.0,
        withholdingTaxRate: 17.5, // 500 TL kâr -> 87.5 TL stopaj
      );

      final portfolio = Portfolio(
        id: 'p1',
        name: 'Ana Portföy',
        createdAt: now,
        assets: [fundInProfit, stockAsset],
        transactions: [saleTx],
      );

      expect(portfolio.totalProfit, 1500.0);
      expect(portfolio.totalWithholdingTax, 175.0);
      expect(portfolio.netTotalProfit, 1325.0);

      expect(portfolio.realizedProfit, 500.0);
      expect(portfolio.realizedWithholdingTax, 87.5);
      expect(portfolio.netRealizedProfit, 412.5);
    });
  });
}

