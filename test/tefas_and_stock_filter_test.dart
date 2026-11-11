import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/services/asset_catalog_service.dart';
import 'package:portfoy_app/services/market_data_service.dart';
import 'package:portfoy_app/services/tefas_service.dart';

void main() {
  group('KUT & Kuveyt Türk Fund Logo Tests', () {
    test('resolveFundLogoCandidates returns authentic Kuveyt Turk logos for KUT and KZL', () {
      final kutCandidates = MarketDataService.resolveFundLogoCandidates(
        'KUT',
        'KUVEYT TÜRK PORTFÖY KIYMETLİ MADENLER KATILIM FONU',
      );
      expect(kutCandidates, isNotEmpty);
      expect(
        kutCandidates.any((c) => c.contains('kuveyt_turk.svg') || c.contains('Kuveyt_T%C3%BCrk_Logo.svg')),
        isTrue,
      );
      // Albaraka logosu kesinlikle Kuveyt Türk adayları arasında olmamalıdır
      expect(
        kutCandidates.any((c) => c.contains('albaraka')),
        isFalse,
      );

      final kzlCandidates = MarketDataService.resolveFundLogoCandidates(
        'KZL',
        'KUVEYT TÜRK PORTFÖY ALTIN KATILIM FONU',
      );
      expect(kzlCandidates, isNotEmpty);
      expect(kzlCandidates.any((c) => c.contains('albaraka')), isFalse);
    });

    test('resolveFundLogo for KUT never returns Albaraka logo', () {
      final logo = MarketDataService.resolveFundLogo(
        'KUT',
        'KUVEYT TÜRK PORTFÖY KIYMETLİ MADENLER KATILIM FONU',
      );
      expect(logo, isNotNull);
      expect(logo, isNot(contains('albaraka')));
      expect(
        logo!.contains('kuveyt_turk.svg') || logo.contains('Kuveyt_T%C3%BCrk_Logo.svg'),
        isTrue,
      );
    });
  });

  group('KUT & Dynamic TEFAS Search Tests', () {
    test('AssetCatalogService.search finds KUT fund with category fon', () async {
      final results = await AssetCatalogService.search(query: 'KUT');
      expect(results, isNotEmpty);
      final kut = results.firstWhere(
        (r) => r.symbol.toUpperCase() == 'KUT',
        orElse: () => throw Exception('KUT not found in search results'),
      );
      expect(kut.category, equals(AssetCategory.fon));
      expect(kut.name, contains('KUVEYT'));
      expect(kut.iconUrl, isNot(contains('albaraka')));
    });

    test('isKnownTefasFund identifies KUT, KZL and standard 3-char fund codes', () {
      expect(AssetCatalogService.isKnownTefasFund('KUT'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('kut'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('KZL'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('TPZ'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('GPN'), isTrue);
      expect(AssetCatalogService.isKnownTefasFund('USD'), isFalse);
      expect(AssetCatalogService.isKnownTefasFund('BTC'), isFalse);
    });

    test('resolveFundSubtitle correctly identifies Kuveyt Türk, Garanti and others', () {
      expect(
        AssetCatalogService.resolveFundSubtitle('KUVEYT TÜRK PORTFÖY KIYMETLİ MADENLER KATILIM FONU'),
        equals('Kuveyt Türk • Katılım Fonu'),
      );
      expect(
        AssetCatalogService.resolveFundSubtitle('GARANTİ PORTFÖY BİRİNCİ HİSSE FONU'),
        equals('Garanti BBVA • Fon'),
      );
      expect(
        AssetCatalogService.resolveFundSubtitle('İŞ PORTFÖY HİSSE SENEDİ FONU'),
        equals('İş Portföy • Fon'),
      );
    });
  });

  group('Stock and Debt Instrument Filter Tests', () {
    test('Filters out ES34330702 Kutxabank bond and foreign corporate debt instruments', () async {
      final results = await AssetCatalogService.search(
        category: AssetCategory.hisse,
        query: 'kut',
      );

      // ES34330702, ES0443307089 veya A4E0ZF gibi tahvil/ISIN kodları kesinlikle sonuçlarda yer almamalıdır
      final hasDebtCode = results.any((r) =>
          r.symbol.toUpperCase().startsWith('ES34') ||
          r.symbol.toUpperCase().startsWith('XS') ||
          r.symbol.toUpperCase() == 'ES34330702');
      expect(hasDebtCode, isFalse, reason: 'ES34330702 bond must be filtered out from stocks');
    });

    test('Legitimate stocks such as THYAO and AAPL are allowed in stock search', () async {
      final bistResults = await AssetCatalogService.search(
        category: AssetCategory.hisse,
        query: 'THYAO',
      );
      expect(bistResults.any((r) => r.symbol == 'THYAO'), isTrue);

      final usResults = await AssetCatalogService.search(
        category: AssetCategory.hisse,
        query: 'AAPL',
      );
      expect(usResults.any((r) => r.symbol == 'AAPL'), isTrue);
    });
  });

  group('TefasService Jitter & Business Date Tests', () {
    test('getLatestBusinessDateString returns YYYYMMDD and does not return weekend dates', () {
      final dateStr = TefasService.getLatestBusinessDateString();
      expect(dateStr.length, equals(8));
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final dt = DateTime(year, month, day);
      expect(dt.weekday, isNot(DateTime.saturday));
      expect(dt.weekday, isNot(DateTime.sunday));
    });

    test('getPreviousBusinessDateString steps back skipping weekends', () {
      // 2026-11-09 Pazartesi -> bir önceki iş günü 2026-11-06 Cuma olmalı
      final prev = TefasService.getPreviousBusinessDateString('20261109');
      expect(prev, equals('20261106'));
    });
  });
}

