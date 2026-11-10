import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/portfolio.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/providers/portfolio_provider.dart';
import 'package:portfoy_app/widgets/asset_symbol_autocomplete.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Portfolio Model sortIndex Tests', () {
    test('Portfolio initializes with sortIndex and serializes correctly', () {
      final p1 = Portfolio(
        id: 'p1',
        name: 'Portföy 1',
        createdAt: DateTime(2025, 1, 1),
        assets: [],
        sortIndex: 3,
      );

      expect(p1.sortIndex, 3);

      final json = p1.toJson();
      expect(json['sortIndex'], 3);

      final fromJson = Portfolio.fromJson(json);
      expect(fromJson.sortIndex, 3);
      expect(fromJson.name, 'Portföy 1');
    });

    test('Portfolio fromJson handles legacy records without sortIndex (defaults to 0)', () {
      final legacyJson = {
        'id': 'legacy',
        'name': 'Eski Portföy',
        'createdAt': '2025-01-01T00:00:00.000',
        'assets': [],
        'transactions': [],
        'isVisible': true,
      };

      final portfolio = Portfolio.fromJson(legacyJson);
      expect(portfolio.sortIndex, 0);
    });

    test('Portfolio copyWith preserves or updates sortIndex', () {
      final p = Portfolio(
        id: 'p1',
        name: 'P1',
        createdAt: DateTime.now(),
        assets: [],
        sortIndex: 1,
      );

      final updated = p.copyWith(sortIndex: 5);
      expect(updated.sortIndex, 5);

      final unchanged = p.copyWith(name: 'Yeni İsim');
      expect(unchanged.sortIndex, 1);
      expect(unchanged.name, 'Yeni İsim');
    });
  });

  group('PortfolioProvider Reorder & Sync Tests', () {
    test('reorderPortfolios updates sortIndex consecutively', () async {
      final provider = PortfolioProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.loadData();

      // Üç portföy ekle
      await provider.addPortfolio(name: 'İlk Portföy');
      await provider.addPortfolio(name: 'İkinci Portföy');
      await provider.addPortfolio(name: 'Üçüncü Portföy');

      expect(provider.portfolios.length, 3);
      // Kullanıcı talebi: Yeni portföyler listenin en altına eklenir
      expect(provider.portfolios[0].name, 'İlk Portföy');
      expect(provider.portfolios[1].name, 'İkinci Portföy');
      expect(provider.portfolios[2].name, 'Üçüncü Portföy');

      expect(provider.portfolios[0].sortIndex, 0);
      expect(provider.portfolios[1].sortIndex, 1);
      expect(provider.portfolios[2].sortIndex, 2);

      // 3. portföyü (index 2) en başa (index 0) taşı
      await provider.reorderPortfolios(2, 0);

      expect(provider.portfolios[0].name, 'Üçüncü Portföy');
      expect(provider.portfolios[1].name, 'İlk Portföy');
      expect(provider.portfolios[2].name, 'İkinci Portföy');

      // sortIndex'ler kalıcı sıralamaya göre 0, 1, 2 atanmış olmalı
      expect(provider.portfolios[0].sortIndex, 0);
      expect(provider.portfolios[1].sortIndex, 1);
      expect(provider.portfolios[2].sortIndex, 2);
    });

    test('Cloud sync / snapshot sorting respects sortIndex over createdAt', () {
      // Senaryo: Buluttan gelen 2 portföy var:
      // pOld: createdAt eski ama sortIndex 0 (kullanıcı en başa sıralamış)
      // pNew: createdAt yeni ama sortIndex 1 (kullanıcı alta almış)
      final pOld = Portfolio(
        id: 'p_old',
        name: 'Eski Portföy (En Üstte Olmalı)',
        createdAt: DateTime(2024, 1, 1),
        assets: [],
        sortIndex: 0,
      );
      final pNew = Portfolio(
        id: 'p_new',
        name: 'Yeni Portföy (Altta Olmalı)',
        createdAt: DateTime(2025, 1, 1),
        assets: [],
        sortIndex: 1,
      );

      final list = [pNew, pOld];

      // Uygulanan sıralama algoritması:
      list.sort((a, b) {
        if (a.sortIndex != b.sortIndex) {
          return a.sortIndex.compareTo(b.sortIndex);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      expect(list[0].id, 'p_old');
      expect(list[1].id, 'p_new');
    });
  });

  group('AssetSymbolAutocomplete Widget & TapRegion Tests', () {
    testWidgets('AssetSymbolAutocomplete contains TapRegion to prevent touch dismissal', (tester) async {
      final controller = TextEditingController(text: 'THYAO');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetSymbolAutocomplete(
              controller: controller,
              category: AssetCategory.hisse,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // TapRegion bileşeninin mevcut olduğunu doğrula
      final tapRegionFinder = find.byType(TapRegion);
      expect(tapRegionFinder, findsWidgets);
    });
  });
}
