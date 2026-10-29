import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/services/market_data_service.dart';

void main() {
  test('MarketDataService tests', () async {
    final pastDate = DateTime(2024, 6, 10);

    // 1. Fon (TEFAS API'sinde logo desteği yoktur)
    final fon = await MarketDataService.fetchAssetData(
      category: AssetCategory.fon,
      symbol: 'TI2',
      purchaseDate: pastDate,
    );
    expect(fon, isNotNull);
    expect(fon!.currentPrice, greaterThan(0));
    expect(fon.weeklyChangePercent, isNot(isNaN));
    expect(fon.iconUrl, isNotNull);

    // 2. Hisse (Türkçe İ harfli BIST hissesi ve normal hisse)
    final hisseIsctr = await MarketDataService.fetchAssetData(
      category: AssetCategory.hisse,
      symbol: 'İSCTR',
      purchaseDate: pastDate,
    );
    expect(hisseIsctr, isNotNull);
    expect(hisseIsctr!.currentPrice, greaterThan(0));
    expect(hisseIsctr.weeklyChangePercent, isNot(isNaN));
    expect(hisseIsctr.iconUrl, isNotNull);

    final hisseThyao = await MarketDataService.fetchAssetData(
      category: AssetCategory.hisse,
      symbol: 'THYAO',
      purchaseDate: pastDate,
    );
    expect(hisseThyao, isNotNull);
    expect(hisseThyao!.currentPrice, greaterThan(0));
    expect(hisseThyao.iconUrl, isNotNull);

    // 3. Döviz
    final doviz = await MarketDataService.fetchAssetData(
      category: AssetCategory.doviz,
      symbol: 'USD',
      purchaseDate: pastDate,
    );
    expect(doviz, isNotNull);
    expect(doviz!.currentPrice, greaterThan(0));
    expect(doviz.iconUrl, isNotNull);

    // 4. Emtia (Altın)
    final altin = await MarketDataService.fetchAssetData(
      category: AssetCategory.emtia,
      symbol: 'Gram Altın',
      purchaseDate: pastDate,
    );
    expect(altin, isNotNull);
    expect(altin!.currentPrice, greaterThan(0));
    expect(altin.weeklyChangePercent, isNot(0.0));
    expect(altin.monthlyChangePercent, isNot(0.0));

    final ceyrek = await MarketDataService.fetchAssetData(
      category: AssetCategory.emtia,
      symbol: 'Çeyrek Altın',
      purchaseDate: pastDate,
    );
    expect(ceyrek, isNotNull);
    expect(ceyrek!.currentPrice, greaterThan(0));
    expect(ceyrek.weeklyChangePercent, isNot(0.0));

    // 5. Kripto (Bitcoin & Otomatik Kategori Çözümleme)
    final btc = await MarketDataService.fetchAssetData(
      category: AssetCategory.kripto,
      symbol: 'BTC',
      purchaseDate: pastDate,
    );
    expect(btc, isNotNull);
    expect(btc!.symbol, 'BTC');
    expect(btc.name, 'Bitcoin');
    expect(btc.currentPrice, greaterThan(0));
    expect(btc.iconUrl, isNotNull);

    // Kategori uyumsuzluğunda akıllı kripto tespiti
    final autoBtc = await MarketDataService.fetchAssetData(
      category: AssetCategory.hisse,
      symbol: 'bitcoin',
      purchaseDate: pastDate,
    );
    expect(autoBtc, isNotNull);
    expect(autoBtc!.resolvedCategory, AssetCategory.kripto);
    expect(autoBtc.currentPrice, greaterThan(0));
  });
}
