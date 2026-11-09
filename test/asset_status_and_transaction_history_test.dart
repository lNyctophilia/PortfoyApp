import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portfoy_app/dialogs/asset_status_dialog.dart';
import 'package:portfoy_app/dialogs/portfolio_detail_dialog.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';
import 'package:portfoy_app/widgets/portfolio_card.dart';
import 'package:portfoy_app/screens/settings_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AssetStatusDialog Tests', () {
    testWidgets('FullScreen AssetStatusDialog does not have İşlem Ekle button in AppBar',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_1',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 100,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_1',
        name: 'Test Portföy',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssetStatusDialog(
            portfolio: portfolio,
            asset: asset,
            provider: provider,
            isFullScreen: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify "İşlem Ekle" button is NOT in AppBar
      expect(find.text('İşlem Ekle'), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Durumum screen displays Adet, pure number without suffix, and Ort. Maliyet in summary bar',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_2',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 50,
        purchasePrice: 10,
        currentPrice: 15,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_2',
        name: 'Altın Portföyü',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssetStatusDialog(
            portfolio: portfolio,
            asset: asset,
            provider: provider,
            isFullScreen: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify summary bar has 'Adet' and pure number '50' without 'Adet' suffix
      final summaryBar = find.byKey(const Key('asset_status_summary_card'));
      expect(find.descendant(of: summaryBar, matching: find.text('Adet')), findsOneWidget);
      expect(find.descendant(of: summaryBar, matching: find.text('50')), findsOneWidget);
      expect(find.descendant(of: summaryBar, matching: find.text('50 Adet')), findsNothing);

      // Verify "Ort. Maliyet" is found and "Ort. Kalan Maliyet" is gone
      expect(find.descendant(of: summaryBar, matching: find.text('Ort. Maliyet')), findsOneWidget);
      expect(find.descendant(of: summaryBar, matching: find.text('Ort. Kalan Maliyet')), findsNothing);

      // Verify no horizontal SingleChildScrollView in summaryBar on mobile
      expect(
        find.descendant(
          of: summaryBar,
          matching: find.byWidgetPredicate(
            (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetStatusDialog renders stretched single row on desktop without SingleChildScrollView',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_2',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 50,
        purchasePrice: 250,
        currentPrice: 300,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_2',
        name: 'Altın Portföyü',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssetStatusDialog(
            portfolio: portfolio,
            asset: asset,
            provider: provider,
            isFullScreen: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final summaryBar = find.byKey(const Key('asset_status_summary_card'));
      expect(summaryBar, findsOneWidget);

      // Should have Expanded metric items inside Row
      expect(
        find.descendant(of: summaryBar, matching: find.byType(Expanded)),
        findsAtLeastNWidgets(4),
      );
      // No horizontal scroll on desktop
      expect(
        find.descendant(
          of: summaryBar,
          matching: find.byWidgetPredicate(
            (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PortfolioCard and PortfolioDetailDialog do not render redundant historical performance titles',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_3',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 10,
        purchasePrice: 2000,
        currentPrice: 2500,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_3',
        name: 'Test Portföy',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      // 1. Verify PortfolioCard does not have 'Tarihsel Değişimler'
      await tester.pumpWidget(
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: PortfolioCard(
                portfolio: portfolio,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tarihsel Değişimler'), findsNothing);

      // 2. Verify PortfolioDetailDialog does not have 'Tarihsel Getiriler'
      await provider.addPortfolio(name: 'Test Portföy');
      final pId = provider.rawPortfolios.first.id;
      await tester.pumpWidget(
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: provider,
          child: MaterialApp(
            home: PortfolioDetailDialog(
              portfolioId: pId,
              isFullScreen: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tarihsel Getiriler'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Transaction History Net vs Gross Display Tests', () {
    test('PortfolioTransaction calculates net and gross profit and percentages correctly', () {
      final saleTx = PortfolioTransaction(
        id: 'tx_satis_1',
        portfolioId: 'port_1',
        type: TransactionType.satis,
        symbol: 'NNF',
        name: 'Hedef Portföy Birinci Hisse Fonu',
        category: AssetCategory.fon,
        date: DateTime(2025, 2, 1),
        quantity: 100,
        price: 20, // total revenue = 2000
        costPrice: 10, // total cost = 1000
        realizedProfit: 1000,
        withholdingTaxRate: 17.5,
      );

      // Gross
      expect(saleTx.realizedProfit, 1000.0);
      expect(saleTx.profitPercent, 100.0);

      // Withholding Tax: 1000 * 17.5% = 175
      expect(saleTx.withholdingTax, 175.0);

      // Net
      expect(saleTx.netRealizedProfit, 825.0);
      expect(saleTx.netProfitPercent, 82.5);
    });

    testWidgets('PortfolioDetailDialog Transaction History tab updates dynamically between Net and Gross',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      await provider.addPortfolio(name: 'Test Portföy');
      final pId = provider.rawPortfolios.first.id;

      final saleTx = PortfolioTransaction(
        id: 'tx_1',
        portfolioId: pId,
        type: TransactionType.satis,
        symbol: 'NNF',
        name: 'Hedef Fon',
        category: AssetCategory.fon,
        date: DateTime(2025, 2, 1),
        quantity: 100,
        price: 20,
        costPrice: 10,
        realizedProfit: 1000,
        withholdingTaxRate: 17.5,
      );

      await provider.addTransaction(pId, saleTx);
      await provider.setReturnMode(ReturnCalculationMode.brut);

      await tester.pumpWidget(
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: provider,
          child: MaterialApp(
            home: PortfolioDetailDialog(
              portfolioId: pId,
              isFullScreen: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to transactions tab
      final txTabFinder = find.textContaining('İşlemler');
      expect(txTabFinder, findsOneWidget);
      await tester.tap(txTabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Under Brut: should show +%100,00 and ₺1.000,00
      expect(find.text('(+%100,00)'), findsOneWidget);

      // Switch mode to Net
      await provider.setReturnMode(ReturnCalculationMode.net);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Under Net: should show +%82,50 and ₺825,00
      expect(find.text('(+%82,50)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetStatusDialog aligns summary, tab buttons, and transaction cards to 16px on mobile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_align',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 10,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_align',
        name: 'Altın Portföyü',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssetStatusDialog(
            portfolio: portfolio,
            asset: asset,
            provider: provider,
            isFullScreen: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Summary card bounds
      final summaryFinder = find.byKey(const Key('asset_status_summary_card'));
      expect(summaryFinder, findsOneWidget);
      final summaryRect = tester.getRect(summaryFinder);
      expect(summaryRect.left, 16.0);
      expect(summaryRect.right, 390.0 - 16.0);

      // 2. Tab buttons row bounds
      final alisTabFinder = find.text('Alış Lotları');
      expect(alisTabFinder, findsOneWidget);
      final alisButton = find.ancestor(of: alisTabFinder, matching: find.byType(InkWell)).first;
      final alisButtonRect = tester.getRect(alisButton);
      expect(alisButtonRect.left, 16.0);

      final satisTabFinder = find.text('Satış Geçmişi');
      expect(satisTabFinder, findsOneWidget);
      final satisButton = find.ancestor(of: satisTabFinder, matching: find.byType(InkWell)).first;
      final satisButtonRect = tester.getRect(satisButton);
      expect(satisButtonRect.right, 390.0 - 16.0);

      // 3. Lot card bounds
      final lotDateFinder = find.textContaining('Alış:');
      expect(lotDateFinder, findsOneWidget);
      final lotCardFinder = find.ancestor(of: lotDateFinder, matching: find.byType(Container)).first;
      final lotCardRect = tester.getRect(lotCardFinder);
      expect(lotCardRect.left, 16.0);
      expect(lotCardRect.right, 390.0 - 16.0);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('SettingsScreen active mode preview container stretches across full width on desktop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final currentModeFinder = find.byKey(const Key('settings_active_mode_box'));
      expect(currentModeFinder, findsOneWidget);

      final modeContainerRect = tester.getRect(currentModeFinder);

      // On 1200px screen, SettingsScreen has ConstrainedBox(maxWidth: 720) with horizontal padding 24 (720 - 48 = 672).
      // The parent RadioGroup container has 1px border on each side: 672 - 2 = 670 width.
      // The mode box outer geometry (including 16 margin on each side) stretches across the full 670px width.
      expect(modeContainerRect.width, 670.0);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
