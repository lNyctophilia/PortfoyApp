import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/portfolio_asset.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';
import 'package:portfoy_app/dialogs/add_edit_portfolio_dialog.dart';
import 'package:portfoy_app/dialogs/portfolio_detail_dialog.dart';
import 'package:portfoy_app/features/model_portfolio/models/model_portfolio_analysis.dart';
import 'package:portfoy_app/features/model_portfolio/services/model_portfolio_service.dart';
import 'package:portfoy_app/features/model_portfolio/widgets/model_monthly_history_view.dart';
import 'package:portfoy_app/features/model_portfolio/widgets/model_period_performance_row.dart';
import 'package:portfoy_app/features/model_portfolio/widgets/model_portfolio_badge.dart';
import 'package:portfoy_app/widgets/portfolio_card.dart';
import 'package:portfoy_app/dialogs/add_transaction_dialog.dart';

void main() {
  group('Model Portfolio Unit & Service Tests', () {
    test('Portfolio serialization and deserialization retains isModel flag and allocations', () {
      final asset = PortfolioAsset(
        id: 'a1',
        name: 'Türk Hava Yolları',
        symbol: 'THYAO',
        category: AssetCategory.hisse,
        purchaseDate: DateTime(2024, 1, 1),
        purchasePrice: 250.0,
        quantity: 10,
        currentPrice: 300.0,
        dailyChangePercent: 2.5,
        weeklyChangePercent: 5.0,
        monthlyChangePercent: 12.0,
        yearlyChangePercent: 65.0,
        twoYearlyChangePercent: 120.0,
        threeYearlyChangePercent: 250.0,
        fiveYearlyChangePercent: 600.0,
        earliestDate: DateTime(2022, 1, 1),
        targetAllocationPercent: 40.0,
        monthlyReturns: {'2026-10': 4.5, '2026-09': -2.0},
      );

      final p = Portfolio(
        id: 'port_model_1',
        name: 'BIST Temettü & Büyüme',
        description: 'Örnek model portföy',
        createdAt: DateTime(2026, 1, 1),
        assets: [asset],
        isModel: true,
      );

      final json = p.toJson();
      expect(json['isModel'], true);

      final decoded = Portfolio.fromJson(json);
      expect(decoded.isModel, true);
      expect(decoded.totalAllocationPercent, 40.0);
      expect(decoded.assets.first.targetAllocationPercent, 40.0);
      expect(decoded.assets.first.twoYearlyChangePercent, 120.0);
      expect(decoded.assets.first.fiveYearlyChangePercent, 600.0);
      expect(decoded.assets.first.monthlyReturns['2026-10'], 4.5);
    });

    test('Model portfolio calculates category and asset allocations from target percentages', () {
      final p = Portfolio(
        id: 'model_p',
        name: 'Dengeli Model',
        createdAt: DateTime(2026, 1, 1),
        isModel: true,
        assets: [
          PortfolioAsset(
            id: 'a1',
            name: 'THYAO',
            symbol: 'THYAO',
            category: AssetCategory.hisse,
            purchaseDate: DateTime(2025, 1, 1),
            purchasePrice: 100,
            quantity: 1,
            currentPrice: 100,
            targetAllocationPercent: 50.0,
          ),
          PortfolioAsset(
            id: 'a2',
            name: 'Gram Altın',
            symbol: 'ALTIN',
            category: AssetCategory.emtia,
            purchaseDate: DateTime(2025, 1, 1),
            purchasePrice: 100,
            quantity: 1,
            currentPrice: 100,
            targetAllocationPercent: 30.0,
          ),
          PortfolioAsset(
            id: 'a3',
            name: 'Kuveyt Türk Fonu',
            symbol: 'KUT',
            category: AssetCategory.fon,
            purchaseDate: DateTime(2025, 1, 1),
            purchasePrice: 100,
            quantity: 1,
            currentPrice: 100,
            targetAllocationPercent: 20.0,
          ),
        ],
      );

      expect(p.totalAllocationPercent, 100.0);
      final catPcts = p.categoryPercentages;
      expect(catPcts[AssetCategory.hisse], 50.0);
      expect(catPcts[AssetCategory.emtia], 30.0);
      expect(catPcts[AssetCategory.fon], 20.0);

      final allocations = p.assetAllocations;
      expect(allocations.first.symbol, 'THYAO');
      expect(allocations.first.percentage, 50.0);
    });

    test('ModelPortfolioService calculates 1G-5Y returns and tracks historical limit warning correctly', () {
      final now = DateTime.now();

      // Varlık 1: 10 ay önce halka arz olmuş (earliestDate: 10 ay önce)
      final assetRecent = PortfolioAsset(
        id: 'recent_ipo',
        name: 'Yeni Halka Arz',
        symbol: 'YENI',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 300)),
        purchasePrice: 50,
        quantity: 1,
        currentPrice: 75,
        dailyChangePercent: 2.0,
        weeklyChangePercent: 4.0,
        monthlyChangePercent: 8.0,
        yearlyChangePercent: 0.0,
        earliestDate: now.subtract(const Duration(days: 300)),
        targetAllocationPercent: 50.0,
        monthlyReturns: {
          '2026-10': 5.0,
          '2026-09': 3.0,
        },
      );

      // Varlık 2: 5 yıllık geçmişi var
      final assetOld = PortfolioAsset(
        id: 'old_stock',
        name: 'Köklü Şirket',
        symbol: 'KOKLU',
        category: AssetCategory.hisse,
        purchaseDate: now.subtract(const Duration(days: 1800)),
        purchasePrice: 10,
        quantity: 1,
        currentPrice: 100,
        dailyChangePercent: 4.0,
        weeklyChangePercent: 6.0,
        monthlyChangePercent: 10.0,
        yearlyChangePercent: 80.0,
        twoYearlyChangePercent: 150.0,
        threeYearlyChangePercent: 300.0,
        fiveYearlyChangePercent: 700.0,
        earliestDate: now.subtract(const Duration(days: 2000)),
        targetAllocationPercent: 50.0,
        monthlyReturns: {
          '2026-10': 10.0,
          '2026-09': 6.0,
          '2026-08': 4.0,
          '2026-07': -2.0,
          '2026-06': 8.0,
        },
      );

      final p = Portfolio(
        id: 'model_backtest',
        name: 'Test Model',
        createdAt: now,
        isModel: true,
        assets: [assetRecent, assetOld],
      );

      final analysis = ModelPortfolioService.analyze(p);

      // Günlük: (%2 * 0.5) + (%4 * 0.5) = %3.0
      expect(analysis.periodReturns['1G'], 3.0);
      // Haftalık: (%4 * 0.5) + (%6 * 0.5) = %5.0
      expect(analysis.periodReturns['1H'], 5.0);
      // 1 Yıl hedefinde YENI hissesinin verisi 300 günlük olduğu için eksik listesinde olmalı
      expect(analysis.isPeriodExceeded('1Y'), isTrue);
      expect(analysis.getMissingAssetsForPeriod('1Y'), contains('YENI'));

      // 5 Yıl hedefinde YENI hissesi bulunmalı
      expect(analysis.getMissingAssetsForPeriod('5Y'), contains('YENI'));
      expect(analysis.getMissingAssetsForPeriod('5Y'), isNot(contains('KOKLU')));

      // Aylık analiz kontrolleri
      expect(analysis.monthlyHistory.isNotEmpty, isTrue);
      // Ekim 2026: (5*0.5 + 10*0.5) = 7.5%
      final oct = analysis.monthlyHistory.firstWhere((m) => m.monthKey == '2026-10');
      expect(oct.returnPercent, 7.5);
      expect(oct.hasWarning, isFalse);

      // 2026-08 ayında YENI hissesinin verisi bittiği için ilk kez uyarı vermeli!
      final aug = analysis.monthlyHistory.firstWhere((m) => m.monthKey == '2026-08');
      expect(aug.hasWarning, isTrue);
      expect(aug.warnedAssetNames, contains('YENI'));
      expect(aug.warningMessage, contains('YENI için bu tarihten öncesi veri bulunmuyor'));

      // 2026-07 ve 2026-06 aylarında YENI hissesi tekrar uyarılmamalı!
      final jul = analysis.monthlyHistory.firstWhere((m) => m.monthKey == '2026-07');
      expect(jul.warnedAssetNames, isNot(contains('YENI')));

      final jun = analysis.monthlyHistory.firstWhere((m) => m.monthKey == '2026-06');
      expect(jun.warnedAssetNames, isNot(contains('YENI')));

      // İstatistikler: bestMonth, worstMonth, averageMonthlyReturn
      expect(analysis.bestMonth != null, isTrue);
      expect(analysis.worstMonth != null, isTrue);
    });
  });

  group('Model Portfolio Widget Tests', () {
    testWidgets('AddEditPortfolioDialog offers Canlı Portföy and Model Portföy selection',
        (WidgetTester tester) async {
      bool? savedModelType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditPortfolioDialog(
              onSave: (name, desc, [isModel]) {
                savedModelType = isModel;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Canlı Portföy'), findsOneWidget);
      expect(find.text('Model Portföy'), findsOneWidget);

      // Model Portföy seçeneğine tıkla
      await tester.tap(find.text('Model Portföy'));
      await tester.pump();

      // Portföy İsmi gir
      await tester.enterText(find.byType(TextFormField).first, 'Benim Modelim');
      await tester.pump();

      // Kaydet butonuna tıkla
      await tester.tap(find.text('Portföyü Oluştur'));
      await tester.pump();

      expect(savedModelType, isTrue);
    });

    testWidgets('PortfolioCard displays ModelPortfolioBadge when isModel is true',
        (WidgetTester tester) async {
      final modelPortfolio = Portfolio(
        id: 'test_model_card',
        name: 'Model Portföyüm',
        createdAt: DateTime.now(),
        isModel: true,
        assets: [
          PortfolioAsset(
            id: 'm1',
            name: 'Aselsan',
            symbol: 'ASELS',
            category: AssetCategory.hisse,
            purchaseDate: DateTime.now(),
            purchasePrice: 60,
            quantity: 1,
            currentPrice: 75,
            yearlyChangePercent: 45.0,
            targetAllocationPercent: 100.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<PortfolioProvider>(
              create: (_) => PortfolioProvider(),
              child: PortfolioCard(
                portfolio: modelPortfolio,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ModelPortfolioBadge), findsOneWidget);
      expect(find.text('Model'), findsOneWidget);
      expect(find.text('1 Yıllık Getiri (Backtest)'), findsOneWidget);
      expect(find.byType(ModelPeriodPerformanceRow), findsOneWidget);
    });

    testWidgets('ModelMonthlyHistoryView displays warning exclamation and tooltip for exceeded assets',
        (WidgetTester tester) async {
      final analysis = ModelPortfolioAnalysis(
        averageMonthlyReturn: 4.2,
        bestMonth: const ModelMonthReturn(
          monthKey: '2026-10',
          monthLabel: 'Ekim 2026',
          returnPercent: 12.5,
          year: 2026,
          month: 10,
        ),
        worstMonth: const ModelMonthReturn(
          monthKey: '2026-08',
          monthLabel: 'Ağustos 2026',
          returnPercent: -3.4,
          year: 2026,
          month: 8,
        ),
        monthlyHistory: const [
          ModelMonthReturn(
            monthKey: '2026-10',
            monthLabel: 'Ekim 2026',
            returnPercent: 12.5,
            year: 2026,
            month: 10,
          ),
          ModelMonthReturn(
            monthKey: '2026-09',
            monthLabel: 'Eylül 2026',
            returnPercent: 3.5,
            warnedAssetNames: ['THYAO'],
            year: 2026,
            month: 9,
          ),
          ModelMonthReturn(
            monthKey: '2026-08',
            monthLabel: 'Ağustos 2026',
            returnPercent: -3.4,
            year: 2026,
            month: 8,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelMonthlyHistoryView(
                analysis: analysis,
                isMobile: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ekim 2026'), findsOneWidget);
      expect(find.text('Eylül 2026'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('THYAO'), findsOneWidget);

      // Tooltip içeriği kontrolü
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(
        tooltip.message,
        'Bu varlığın son verisi geçildi: THYAO için bu tarihten öncesi veri bulunmuyor.',
      );
    });

    testWidgets('AddTransactionDialog for model portfolio renders percentage input instead of Adet and hides Satış tab',
        (WidgetTester tester) async {
      final modelPortfolio = Portfolio(
        id: 'test_model_tx',
        name: 'Model Portföy',
        createdAt: DateTime.now(),
        isModel: true,
        assets: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTransactionDialog(
              portfolio: modelPortfolio,
              onSave: (_, __) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // "Satış" tab is NOT present
      expect(find.text('Satış'), findsNothing);
      // Title is "Varlık Ekle"
      expect(find.text('Varlık Ekle'), findsOneWidget);
      // Yüzdelik Pay (%) is present, Adet is absent
      expect(find.text('Yüzdelik Pay (%)'), findsOneWidget);
      expect(find.text('Adet'), findsNothing);
      expect(find.text('Güncel Fiyat'), findsOneWidget);
      expect(find.text('Model Portföy Payı'), findsOneWidget);
      // Action button is "Varlığı Ekle"
      expect(find.text('Varlığı Ekle'), findsOneWidget);
    });
  });
}
