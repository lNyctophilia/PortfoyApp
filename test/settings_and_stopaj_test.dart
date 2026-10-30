import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/widgets/net_gross_badge.dart';

void main() {
  group('Stopaj and Net/Gross Calculations', () {
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

    testWidgets('NetGrossBadge renders NET and BRUT labels properly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NetGrossBadge(isNet: true),
                NetGrossBadge(isNet: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('NET'), findsOneWidget);
      expect(find.text('BRÜT'), findsOneWidget);
    });
  });
}

