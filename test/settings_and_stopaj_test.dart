import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/widgets/net_gross_badge.dart';

void main() {
  group('Stopaj and Net/Gross/Reel Calculations', () {
    test('Calculates withholding tax and net profit correctly for fund', () {
      final asset = PortfolioAsset(
        id: 'fon_1',
        name: 'Para Piyasası Fonu',
        symbol: 'PPF',
        category: AssetCategory.fon,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
        purchasePrice: 10.0,
        quantity: 1000,
        currentPrice: 12.0, // Maliyet: 10.000, Değer: 12.000, Kâr: 2.000
        withholdingTaxRate: 10.0, // %10 stopaj -> 200 TL stopaj
      );

      expect(asset.totalCost, 10000.0);
      expect(asset.currentValue, 12000.0); // Brüt Değer
      expect(asset.totalProfit, 2000.0); // Brüt Kâr
      expect(asset.effectiveWithholdingTaxRate, 10.0);
      expect(asset.withholdingTaxAmount, 200.0); // Stopaj tutarı
      expect(asset.netProfit, 1800.0); // Net Kâr
      expect(asset.netCurrentValue, 11800.0); // Net Değer
    });

    test('Calculates profit and return percentage according to ReturnCalculationMode', () {
      final asset = PortfolioAsset(
        id: 'fon_1',
        name: 'Borçlanma Fonu',
        symbol: 'BF',
        category: AssetCategory.fon,
        purchaseDate: DateTime(2024, 1, 1),
        purchasePrice: 100.0,
        quantity: 100, // Maliyet: 10.000 TL
        currentPrice: 160.0, // Güncel Değer: 16.000 TL, Brüt Kâr: 6.000 TL (%60)
        withholdingTaxRate: 10.0, // Stopaj: 600 TL, Net Değer: 15.400 TL, Net Kâr: 5.400 TL (%54)
      );

      const inflation = 30.0; // %30 enflasyon

      // 1. Brüt Mod
      expect(asset.profitForMode(ReturnCalculationMode.brut), 6000.0);
      expect(asset.profitPercentForMode(ReturnCalculationMode.brut), 60.0);
      expect(asset.valueForMode(ReturnCalculationMode.brut), 16000.0);

      // 2. Net Mod
      expect(asset.profitForMode(ReturnCalculationMode.net), 5400.0);
      expect(asset.profitPercentForMode(ReturnCalculationMode.net), 54.0);
      expect(asset.valueForMode(ReturnCalculationMode.net), 15400.0);

      // 3. Reel Mod (TÜFE Enflasyonuna göre)
      // Düzeltilmiş Maliyet: 10.000 * 1.30 = 13.000 TL
      // Reel Kâr: 15.400 - 13.000 = 2.400 TL
      // Fisher Denklemi: (1 + 0.54) / (1 + 0.30) - 1 = 1.54 / 1.30 - 1 = +18.46%
      expect(asset.realCost(inflation), 13000.0);
      expect(asset.realProfit(inflation), 2400.0);
      // Reel modda kâr tutarı eksiltilmez (net kâr tutarı korunur):
      expect(asset.profitForMode(ReturnCalculationMode.reel, inflation), 5400.0);
      expect(
        asset.profitPercentForMode(ReturnCalculationMode.reel, inflation),
        closeTo(18.46, 0.01),
      );
      expect(asset.valueForMode(ReturnCalculationMode.reel), 15400.0);
    });

    testWidgets('NetGrossBadge renders BRÜT, NET, and REEL labels properly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NetGrossBadge(mode: ReturnCalculationMode.brut),
                NetGrossBadge(mode: ReturnCalculationMode.net),
                NetGrossBadge(mode: ReturnCalculationMode.reel),
              ],
            ),
          ),
        ),
      );

      expect(find.text('BRÜT'), findsOneWidget);
      expect(find.text('NET'), findsOneWidget);
      expect(find.text('REEL'), findsOneWidget);
    });
  });
}
