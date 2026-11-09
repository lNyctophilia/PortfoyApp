import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portfoy_app/dialogs/add_edit_portfolio_dialog.dart';
import 'package:portfoy_app/dialogs/add_transaction_dialog.dart';
import 'package:portfoy_app/dialogs/asset_status_dialog.dart';
import 'package:portfoy_app/dialogs/portfolio_detail_dialog.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/models/return_mode.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';
import 'package:portfoy_app/utils/formatters.dart';
import 'package:portfoy_app/widgets/asset_item_tile.dart';
import 'package:portfoy_app/widgets/portfolio_card.dart';
import 'package:portfoy_app/screens/settings_screen.dart';
import 'package:portfoy_app/theme/app_theme.dart';
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
      final txTabFinder = find.textContaining('İşlem Geçmişi');
      expect(txTabFinder, findsOneWidget);
      await tester.tap(txTabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Under Brut: should show %100,00 and ₺1.000,00 (no plus sign)
      expect(find.textContaining('(%100,00)'), findsOneWidget);

      // Switch mode to Net
      await provider.setReturnMode(ReturnCalculationMode.net);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Under Net: should show %82,50 and ₺825,00 (no plus sign)
      expect(find.textContaining('(%82,50)'), findsOneWidget);

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

    test('Formatters.formatCurrencyPrice formats with exact decimals and Turkish symbols', () {
      expect(Formatters.formatCurrencyPrice(0.045612), equals('0,045612 ₺'));
      expect(Formatters.formatCurrencyPrice(1400.76), equals('1.400,76 ₺'));
      expect(Formatters.formatCurrencyPrice(125.0), equals('125,00 ₺'));
      expect(Formatters.formatCurrencyPrice(0.0), equals('0,00 ₺'));
    });

    testWidgets('AddEditPortfolioDialog has label Portföy İsmi without star and no hintText',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditPortfolioDialog(
              onSave: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Portföy İsmi'), findsOneWidget);
      expect(find.text('Portföy İsmi *'), findsNothing);
      expect(find.text('Örn: Teknoloji & Büyüme Fonları'), findsNothing);
      expect(find.text('Örn: BIST ve TEFAS teknoloji ağırlıklı yatırımlar'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PortfolioDetailDialog transactions empty state does not show subtitle or İlk İşlemi Ekle button',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      await provider.addPortfolio(name: 'Boş Portföy');
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
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to İşlem Geçmişi tab
      await tester.tap(find.textContaining('İşlem Geçmişi').first);
      await tester.pumpAndSettle();

      expect(find.text('Bu portföyde henüz işlem kaydı yok'), findsOneWidget);
      expect(find.text('Satış yaptıkça gerçekleşen kâr ve zararlarınız burada listelenir.'), findsNothing);
      expect(find.text('İlk İşlemi Ekle'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetItemTile in Reel mode does not render • TÜFE: %',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      await provider.setReturnMode(ReturnCalculationMode.reel);

      final asset = PortfolioAsset(
        id: 'asset_reel',
        symbol: 'CUSTOMSYM',
        name: 'Özel Varlık',
        category: AssetCategory.emtia,
        quantity: 10,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<PortfolioProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: AssetItemTile(
                asset: asset,
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('• TÜFE: %'), findsNothing);
      expect(find.textContaining('TÜFE'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetStatusDialog Lots and Sales tabs adhere to minimal specifications',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_lots',
        symbol: 'CUSTOMALTIN',
        name: 'Özel Altın',
        category: AssetCategory.emtia,
        quantity: 50,
        purchasePrice: 250,
        currentPrice: 300,
        purchaseDate: DateTime.now(),
      );
      final portfolio = Portfolio(
        id: 'port_lots',
        name: 'Altın Portföyü',
        createdAt: DateTime.now(),
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

      // 1. Lots tab checks:
      // No "Tamamı Duruyor" badge
      expect(find.text('Tamamı Duruyor'), findsNothing);
      // No "Alınan Miktar"
      expect(find.text('Alınan Miktar'), findsNothing);
      // No "Kalan Lot Değeri"
      expect(find.textContaining('Kalan Lot Değeri'), findsNothing);
      // No "Kâr/Zarar: " text inside badge
      expect(find.textContaining('Kâr/Zarar:'), findsNothing);
      // But P/L value exists
      expect(find.textContaining('2.500'), findsWidgets);

      // 2. Sales tab check:
      await tester.tap(find.textContaining('Satış').first);
      await tester.pumpAndSettle();

      expect(find.text('Bu varlık için henüz satış yapılmadı'), findsOneWidget);
      expect(find.text('Satış yaptığınızda FIFO maliyeti ve gerçekleşen kâr burada listelenir.'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    test('Formatters.percent does not include plus sign for positive and includes minus for negative', () {
      expect(Formatters.percent(15.5), '%15,50');
      expect(Formatters.percent(0.0), '%0,00');
      expect(Formatters.percent(-8.25), '-%8,25');
    });

    testWidgets('AddTransactionDialog Sell form has no asset pre-selected, no star, no helper text, and displays Toplam Adet/Fiyat',
        (WidgetTester tester) async {
      final asset = PortfolioAsset(
        id: 'asset_satis_test',
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        category: AssetCategory.hisse,
        quantity: 100,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime.now(),
      );
      final portfolio = Portfolio(
        id: 'port_tx_test',
        name: 'Hisse Portföyü',
        createdAt: DateTime.now(),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTransactionDialog(
              portfolio: portfolio,
              initialType: TransactionType.satis,
              onSave: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Header has sell tag icon
      expect(find.byIcon(Icons.sell_rounded), findsWidgets);

      // 2. "Portföydeki Varlık" without star
      expect(find.text('Portföydeki Varlık'), findsOneWidget);
      expect(find.textContaining('Portföydeki Varlık *'), findsNothing);

      // 3. Initial placeholder visible, no asset pre-selected
      expect(find.text('Portföyden satılacak varlığı seçin...'), findsOneWidget);

      // 4. "Toplam Adet" and "Toplam Fiyat" box exists
      expect(find.text('Toplam Adet'), findsOneWidget);
      expect(find.text('Toplam Fiyat'), findsOneWidget);

      // 5. No helperText "Portföydeki: 100" under quantity
      expect(find.textContaining('Portföydeki:'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AddTransactionDialog Sell form improvements: no price in picker, subtle border, centered stats, layout order, auto clamp',
        (WidgetTester tester) async {
      final asset = PortfolioAsset(
        id: 'asset_satis_improve',
        symbol: 'TESTXYZ',
        name: 'Test Varlik',
        category: AssetCategory.hisse,
        quantity: 100,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_tx_improve',
        name: 'Hisse Portföyü',
        createdAt: DateTime(2025, 1, 1),
        assets: [asset],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTransactionDialog(
              portfolio: portfolio,
              initialType: TransactionType.satis,
              onSave: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Open Asset Picker
      await tester.tap(find.text('Portföyden satılacak varlığı seçin...'));
      await tester.pumpAndSettle();

      // Check BottomSheet contents: symbol, category badge, and name exist, but price does NOT exist
      expect(find.text('TESTXYZ'), findsWidgets);
      expect(find.text('Test Varlik'), findsWidgets);
      expect(find.text(AssetCategory.hisse.displayName), findsWidgets);
      expect(find.text(Formatters.formatCurrencyPrice(250)), findsNothing);

      // Select asset
      await tester.tap(find.text('TESTXYZ').last);
      await tester.pumpAndSettle();

      // 2. Check asset container border has NO red highlight (is AppTheme.borderSubtle)
      final inkWellFinder = find.ancestor(
        of: find.byIcon(Icons.keyboard_arrow_down_rounded),
        matching: find.byType(InkWell),
      ).first;
      final assetCardContainer = tester.widget<Container>(
        find.descendant(of: inkWellFinder, matching: find.byType(Container)).first,
      );
      final boxDec = assetCardContainer.decoration as BoxDecoration?;
      expect(boxDec?.border?.top.color, AppTheme.borderSubtle);

      // 3. Toplam Adet and Toplam Fiyat columns are centered
      final adetCol = tester.widget<Column>(
        find.ancestor(of: find.text('Toplam Adet'), matching: find.byType(Column)).first,
      );
      expect(adetCol.crossAxisAlignment, CrossAxisAlignment.center);

      final fiyatCol = tester.widget<Column>(
        find.ancestor(of: find.text('Toplam Fiyat'), matching: find.byType(Column)).first,
      );
      expect(fiyatCol.crossAxisAlignment, CrossAxisAlignment.center);

      // 4. Form layout order: Tarih & Adet are in a Row together, and Satış Fiyatı is below them
      final adetFieldFinder = find.widgetWithText(TextFormField, 'Adet');
      final adetRowFinder = find.ancestor(of: adetFieldFinder, matching: find.byType(Row)).first;
      expect(
        find.descendant(of: adetRowFinder, matching: find.byIcon(Icons.calendar_today_rounded)),
        findsOneWidget,
      );
      // Satış Fiyatı is present
      expect(find.widgetWithText(TextFormField, 'Satış Fiyatı'), findsOneWidget);

      // 5. Adet auto-clamp test:
      // Initially, selecting TESTXYZ populated 100 Adet
      expect(find.text('100'), findsWidgets);

      // User enters 250 (more than 100 in portfolio)
      await tester.enterText(adetFieldFinder, '250');
      await tester.pump();

      // Submit field (Enter / Done action)
      final textField = tester.widget<TextField>(
        find.descendant(of: adetFieldFinder, matching: find.byType(TextField)),
      );
      textField.onSubmitted?.call('250');
      await tester.pump();

      // Verify it clamped back to 100
      final editableText = tester.widget<EditableText>(
        find.descendant(of: adetFieldFinder, matching: find.byType(EditableText)),
      );
      expect(editableText.controller.text, '100');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PortfolioDetailDialog Transaction History renders Fiyat, Adet, Tutar columns with dividers',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      await provider.addPortfolio(name: 'İşlem Portföyü');
      final pId = provider.rawPortfolios.first.id;

      final alisTx = PortfolioTransaction(
        id: 'tx_alis_cols',
        portfolioId: pId,
        type: TransactionType.alis,
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        date: DateTime(2025, 1, 1),
        quantity: 50,
        price: 150,
        costPrice: 150,
      );

      await provider.addTransaction(pId, alisTx);

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
      final txTabFinder = find.textContaining('İşlem Geçmişi');
      expect(txTabFinder, findsOneWidget);
      await tester.tap(txTabFinder);
      await tester.pumpAndSettle();

      // Check for columns Fiyat, Adet, Tutar
      expect(find.text('Fiyat'), findsOneWidget);
      expect(find.text('Adet'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetStatusDialog renders 2-layer layout on PC with Adet and Maliyet on far right',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      final asset = PortfolioAsset(
        id: 'asset_pc_status',
        symbol: 'ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 100,
        purchasePrice: 40,
        currentPrice: 50,
        purchaseDate: DateTime(2025, 1, 1),
      );
      final portfolio = Portfolio(
        id: 'port_pc_status',
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

      // Verifies label changes: 'Adet' and 'Maliyet' present, 'Kalan Miktar' and 'Toplam Maliyet' absent
      expect(find.text('Kalan Miktar'), findsNothing);
      expect(find.text('Toplam Maliyet'), findsNothing);
      expect(find.text('Alış Fiyatı'), findsWidgets);
      expect(find.text('Adet'), findsWidgets);
      expect(find.text('Maliyet'), findsWidgets);

      // Verify column ordering: Alış Fiyatı left < Adet left < Maliyet left (Maliyet on far right)
      final alisFiyatRect = tester.getRect(find.text('Alış Fiyatı').first);
      final adetRect = tester.getRect(find.text('Adet').first);
      final maliyetRect = tester.getRect(find.text('Maliyet').first);
      expect(alisFiyatRect.left < adetRect.left, isTrue);
      expect(adetRect.left < maliyetRect.left, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PortfolioDetailDialog Transaction History renders 3-column table on mobile for sales with header K/Z pill',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      await provider.addPortfolio(name: 'Mobil Satış Portföyü');
      final pId = provider.rawPortfolios.first.id;

      final satisTx = PortfolioTransaction(
        id: 'tx_satis_mobile',
        portfolioId: pId,
        type: TransactionType.satis,
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        category: AssetCategory.hisse,
        date: DateTime(2025, 2, 1),
        quantity: 20,
        price: 300,
        costPrice: 200,
        realizedProfit: 2000,
      );

      await provider.addTransaction(pId, satisTx);

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

      final txTabFinder = find.textContaining('İşlem Geçmişi');
      await tester.tap(txTabFinder);
      await tester.pumpAndSettle();

      // Mobile table still has exactly Fiyat, Adet, Tutar columns
      expect(find.text('Fiyat'), findsOneWidget);
      expect(find.text('Adet'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);
      // 'K/Z' is NOT a column header in the table
      expect(find.text('K/Z'), findsNothing);

      // But profit pill is rendered in header
      expect(find.textContaining('(%50,00)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AssetStatusDialog tab buttons do not show count badges',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());
      final asset = PortfolioAsset(
        id: 'asset_tab_test',
        symbol: 'CUSTOMALTIN',
        name: 'Gram Altın',
        category: AssetCategory.emtia,
        quantity: 100,
        purchasePrice: 200,
        currentPrice: 250,
        purchaseDate: DateTime.now(),
      );
      final portfolio = Portfolio(
        id: 'port_tab_test',
        name: 'Altın Portföyü',
        createdAt: DateTime.now(),
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

      // Tab buttons contain 'Alış Lotları' and 'Satış Geçmişi'
      expect(find.text('Alış Lotları'), findsOneWidget);
      expect(find.text('Satış Geçmişi'), findsOneWidget);

      // Verify that within the tab buttons there are no numeric count badges
      final tabInkWells = find.ancestor(of: find.text('Alış Lotları'), matching: find.byType(InkWell));
      expect(tabInkWells, findsOneWidget);

      // The button child row should only have Icon, SizedBox, Flexible(Text) -> exactly 3 items (no count badge container)
      final rowFinder = find.descendant(of: tabInkWells, matching: find.byType(Row)).first;
      final row = tester.widget<Row>(rowFinder);
      expect(row.children.length, 3);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PortfolioDetailDialog Transaction History tab button renders only title and icon without count',
        (WidgetTester tester) async {
      final provider = PortfolioProvider();
      addTearDown(() => provider.dispose());

      await provider.addPortfolio(name: 'Test Tab Portfoy');
      final pId = provider.rawPortfolios.first.id;
      final tx = PortfolioTransaction(
        id: 'tx_tab_1',
        portfolioId: pId,
        assetId: 'asset_dummy',
        symbol: 'CUSTOMALTIN',
        name: 'Altın',
        category: AssetCategory.emtia,
        type: TransactionType.alis,
        price: 100,
        quantity: 10,
        date: DateTime.now(),
      );
      await provider.addTransaction(pId, tx);

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

      // Button says exactly 'İşlem Geçmişi' without any parenthetical count
      expect(find.text('İşlem Geçmişi'), findsOneWidget);
      expect(find.textContaining('İşlemler ('), findsNothing);
      expect(find.textContaining('İşlem Geçmişi ('), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
