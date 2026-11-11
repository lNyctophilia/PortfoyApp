import 'dart:convert';
import '../core/network/app_http_client.dart';
import '../models/asset_category.dart';
import 'asset_catalog_service.dart';
import 'storage_service.dart';
import 'tefas_service.dart';

class MarketAssetInfo {
  final String symbol;
  final String name;
  final double currentPrice;
  final double? purchaseDatePrice;
  final double dailyChangePercent;
  final double weeklyChangePercent;
  final double monthlyChangePercent;
  final double threeMonthlyChangePercent;
  final double sixMonthlyChangePercent;
  final double yearlyChangePercent;
  final AssetCategory? resolvedCategory;
  final String? iconUrl;
  final DateTime? earliestDate;
  final double? withholdingTaxRate;

  MarketAssetInfo({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    this.purchaseDatePrice,
    this.dailyChangePercent = 0.0,
    this.weeklyChangePercent = 0.0,
    this.monthlyChangePercent = 0.0,
    this.threeMonthlyChangePercent = 0.0,
    this.sixMonthlyChangePercent = 0.0,
    this.yearlyChangePercent = 0.0,
    this.resolvedCategory,
    this.iconUrl,
    this.earliestDate,
    this.withholdingTaxRate,
  });

  MarketAssetInfo withResolvedCategory(AssetCategory category) {
    return MarketAssetInfo(
      symbol: symbol,
      name: name,
      currentPrice: currentPrice,
      purchaseDatePrice: purchaseDatePrice,
      dailyChangePercent: dailyChangePercent,
      weeklyChangePercent: weeklyChangePercent,
      monthlyChangePercent: monthlyChangePercent,
      threeMonthlyChangePercent: threeMonthlyChangePercent,
      sixMonthlyChangePercent: sixMonthlyChangePercent,
      yearlyChangePercent: yearlyChangePercent,
      resolvedCategory: category,
      iconUrl: iconUrl,
      earliestDate: earliestDate,
      withholdingTaxRate: withholdingTaxRate,
    );
  }

  MarketAssetInfo copyWith({
    String? symbol,
    String? name,
    double? currentPrice,
    double? purchaseDatePrice,
    double? dailyChangePercent,
    double? weeklyChangePercent,
    double? monthlyChangePercent,
    double? threeMonthlyChangePercent,
    double? sixMonthlyChangePercent,
    double? yearlyChangePercent,
    AssetCategory? resolvedCategory,
    String? iconUrl,
    DateTime? earliestDate,
    double? withholdingTaxRate,
  }) {
    return MarketAssetInfo(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDatePrice: purchaseDatePrice ?? this.purchaseDatePrice,
      dailyChangePercent: dailyChangePercent ?? this.dailyChangePercent,
      weeklyChangePercent: weeklyChangePercent ?? this.weeklyChangePercent,
      monthlyChangePercent: monthlyChangePercent ?? this.monthlyChangePercent,
      threeMonthlyChangePercent:
          threeMonthlyChangePercent ?? this.threeMonthlyChangePercent,
      sixMonthlyChangePercent:
          sixMonthlyChangePercent ?? this.sixMonthlyChangePercent,
      yearlyChangePercent: yearlyChangePercent ?? this.yearlyChangePercent,
      resolvedCategory: resolvedCategory ?? this.resolvedCategory,
      iconUrl: iconUrl ?? this.iconUrl,
      earliestDate: earliestDate ?? this.earliestDate,
      withholdingTaxRate: withholdingTaxRate ?? this.withholdingTaxRate,
    );
  }
}

class MarketDataService {
  static final Map<String, String> _logoCache = {};
  static final StorageService _storageService = StorageService();
  static bool _logoCacheLoaded = false;

  static double? _cachedUsdTryRate;
  static DateTime? _lastUsdTryFetch;

  static double? _cachedEurTryRate;
  static DateTime? _lastEurTryFetch;

  /// Güncel USD/TRY kurunu önbellekli olarak getirir
  static Future<double> getUsdTryRate() async {
    if (_cachedUsdTryRate != null &&
        _lastUsdTryFetch != null &&
        DateTime.now().difference(_lastUsdTryFetch!) < const Duration(minutes: 5)) {
      return _cachedUsdTryRate!;
    }

    try {
      final usdUrl =
          'https://query1.finance.yahoo.com/v8/finance/chart/USDTRY=X?interval=1d&range=5d';
      final usdResp =
          await AppHttpClient.get(usdUrl, timeout: const Duration(seconds: 4));
      if (usdResp != null && usdResp.statusCode == 200) {
        final usdData = jsonDecode(usdResp.body) as Map<String, dynamic>;
        final usdRes =
            (usdData['chart']?['result'] as List<dynamic>?)?.firstOrNull;
        final rate =
            (usdRes?['meta']?['regularMarketPrice'] as num?)?.toDouble();
        if (rate != null && rate > 0) {
          _cachedUsdTryRate = rate;
          _lastUsdTryFetch = DateTime.now();
          return rate;
        }
      }
    } catch (_) {}

    // Fallback: Truncgil
    try {
      final tInfo = await _fetchTruncgilSingle('USD', isCurrency: true);
      if (tInfo != null && tInfo.currentPrice > 0) {
        _cachedUsdTryRate = tInfo.currentPrice;
        _lastUsdTryFetch = DateTime.now();
        return tInfo.currentPrice;
      }
    } catch (_) {}

    return _cachedUsdTryRate ?? 38.0;
  }

  /// Güncel EUR/TRY kurunu önbellekli olarak getirir
  static Future<double> getEurTryRate() async {
    if (_cachedEurTryRate != null &&
        _lastEurTryFetch != null &&
        DateTime.now().difference(_lastEurTryFetch!) < const Duration(minutes: 5)) {
      return _cachedEurTryRate!;
    }

    try {
      final eurUrl =
          'https://query1.finance.yahoo.com/v8/finance/chart/EURTRY=X?interval=1d&range=5d';
      final eurResp =
          await AppHttpClient.get(eurUrl, timeout: const Duration(seconds: 4));
      if (eurResp != null && eurResp.statusCode == 200) {
        final eurData = jsonDecode(eurResp.body) as Map<String, dynamic>;
        final eurRes =
            (eurData['chart']?['result'] as List<dynamic>?)?.firstOrNull;
        final rate =
            (eurRes?['meta']?['regularMarketPrice'] as num?)?.toDouble();
        if (rate != null && rate > 0) {
          _cachedEurTryRate = rate;
          _lastEurTryFetch = DateTime.now();
          return rate;
        }
      }
    } catch (_) {}

    // Fallback: Truncgil
    try {
      final tInfo = await _fetchTruncgilSingle('EUR', isCurrency: true);
      if (tInfo != null && tInfo.currentPrice > 0) {
        _cachedEurTryRate = tInfo.currentPrice;
        _lastEurTryFetch = DateTime.now();
        return tInfo.currentPrice;
      }
    } catch (_) {}

    return _cachedEurTryRate ?? 41.0;
  }

  static Future<void> ensureLogoCacheLoaded() async {
    if (_logoCacheLoaded) return;
    _logoCacheLoaded = true;
    try {
      final cached = await _storageService.loadLogoCache();
      _logoCache.addAll(cached);
    } catch (_) {}
  }

  static void cacheLogo(String symbol, String url) {
    final clean = normalizeSymbol(symbol).replaceAll('.IS', '');
    if (clean.isNotEmpty && url.isNotEmpty) {
      _logoCache[clean] = url;
      _storageService.saveLogoCache(_logoCache);
    }
  }

  /// Fon unvanından veya kodundan alternatif logo URL adaylarını döndürür
  static List<String> resolveFundLogoCandidates(String fundCode, String fundTitle) {
    final t = fundTitle
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
    final code = fundCode.trim().toUpperCase();

    // 1. TEB Portföy / Türk Ekonomi Bankası
    if (t.contains('TEB') ||
        t.contains('TURK EKONOMI') ||
        t.contains('BNP') ||
        ['TPZ', 'TKP', 'TEP', 'TPF', 'TGE', 'TKF', 'TDF', 'TDB', 'TTA', 'TTB', 'TTC', 'TTD', 'TZL'].contains(code)) {
      return const [
        'https://cdn.worldvectorlogo.com/logos/teb.svg',
        'https://s3-symbol-logo.tradingview.com/paribas.svg',
      ];
    }

    // 2. İş Portföy / İş Bankası
    if (t.contains('IS PORTFOY') ||
        t.contains('IS BANKASI') ||
        ['TI2', 'TI3', 'TI4', 'TTE', 'TET', 'TLE', 'TLP', 'TMG', 'TAU', 'IST', 'IHK', 'IEY'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/is-bankasi.svg',
      ];
    }

    // 3. Ak Portföy / Akbank
    if (t.contains('AK PORTFOY') ||
        t.contains('AKBANK') ||
        ['AFT', 'AFA', 'AES', 'AFS', 'AGH', 'AK2', 'AK3', 'AK4', 'ALE', 'ALR', 'APB'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/akbank.svg',
      ];
    }

    // 4. Yapı Kredi Portföy
    if (t.contains('YAPI KREDI') ||
        t.contains('YAPI VE KREDI') ||
        ['YAC', 'YTD', 'YPG', 'YHK', 'YAS', 'YAY', 'YAZ', 'YEF', 'YBE'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/yapi-ve-kredi.svg',
      ];
    }

    // 5. Garanti Portföy / Garanti BBVA
    if (t.contains('GARANTI') ||
        ['GL1', 'GBV', 'GMR', 'GMA', 'GPY', 'GTA', 'GTL', 'GTZ', 'GPN', 'GPB', 'GZL', 'GKV', 'GKK', 'GAF', 'GOH', 'GPO', 'GNZ', 'GEL', 'GSY', 'GBL'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/garanti.svg',
      ];
    }

    // 6. QNB Finans Portföy
    if (t.contains('QNB') ||
        t.contains('FINANS') ||
        ['FNC', 'FBK', 'FYO', 'QFD', 'QFP', 'QFI', 'QFS', 'QPA'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/qnb-finansbank.svg',
      ];
    }

    // 7. Ziraat Portföy / Ziraat Bankası
    if (t.contains('ZIRAAT') ||
        ['ZPE', 'ZPF', 'ZRE', 'ZKP', 'ZEL', 'ZAS', 'ZCN'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/ziraat-gyo.svg',
      ];
    }

    // 8. Vakıf Portföy / Vakıfbank
    if (t.contains('VAKIF') ||
        ['VAK', 'VK6', 'VPU', 'VRB', 'VRT'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/vakiflar-bankasi.svg',
      ];
    }

    // 9. Halk Portföy / Halkbank
    if (t.contains('HALK') ||
        ['HVT', 'HLK', 'HDK', 'HSY'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/t-halk-bankasi.svg',
      ];
    }

    // 10. Kuveyt Türk / KT Portföy
    if (t.contains('KUVEYT') ||
        t.contains('KT PORTFOY') ||
        [
          'KUT', 'KZL', 'KPD', 'KTM', 'KTK', 'KLU', 'KPU', 'KGV', 'KTV',
          'KPC', 'KPK', 'KTL', 'KTR', 'KTS', 'KTT', 'KTU', 'DK1', 'EZM',
          'KAN', 'KAV', 'KBP', 'KBZ', 'KCV', 'KDE', 'KDK', 'KDL', 'KDS',
          'KDV', 'KDZ', 'KEI', 'KEO', 'KEU', 'KFZ', 'KGM', 'KHP', 'KHU'
        ].contains(code)) {
      return const [
        'assets/icons/kuveyt_turk.svg',
        'https://upload.wikimedia.org/wikipedia/commons/9/97/Kuveyt_T%C3%BCrk_Logo.svg',
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/97/Kuveyt_T%C3%BCrk_Logo.svg/250px-Kuveyt_T%C3%BCrk_Logo.svg.png',
        'https://portfoyapp.nycgamedevs.workers.dev/?url=https%3A%2F%2Fwww.kuveytturk.com.tr%2F_assets%2Fsvg%2Flogo.svg',
      ];
    }

    // 11. Deniz Portföy / Denizbank
    if (t.contains('DENIZ') ||
        ['DZT', 'DLY', 'DBH'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/deniz-gyo.svg',
      ];
    }

    // 12. Albaraka Portföy / Katılım
    if (t.contains('ALBARAKA') ||
        ['ALB', 'RBH'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/albaraka-turk.svg',
      ];
    }

    // 13. Oyak Portföy
    if (t.contains('OYAK') ||
        ['OYO', 'OYP', 'OKP'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/oyak-cimento.svg',
      ];
    }

    // 14. Gedik Portföy
    if (t.contains('GEDIK') ||
        ['GDK', 'GDP', 'GKP'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/gedik-yatirim.svg',
      ];
    }

    // 15. İnfo Portföy
    if (t.contains('INFO') ||
        ['INF', 'IFP'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/info-yatirim.svg',
      ];
    }

    // 16. Hedef Portföy
    if (t.contains('HEDEF') ||
        ['HDF', 'HKH', 'HMG', 'HYV'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/hedef-girisim.svg',
      ];
    }

    // 17. Tacirler Portföy
    if (t.contains('TACIRLER') ||
        ['TCD', 'TCB', 'TCA', 'TFI'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/tacirler-yatirim.svg',
      ];
    }

    // 18. Fiba Portföy / Fibabanka
    if (t.contains('FIBA') ||
        ['FIB', 'FPC', 'FPK', 'FPS', 'FBC'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/fibabanka.svg',
      ];
    }

    // 19. Global MD Portföy / Actus
    if (t.contains('GLOBAL') ||
        t.contains('ACTUS') ||
        ['GBL', 'ACT'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/global-yat-holding.svg',
      ];
    }

    // 20. Osmanlı Portföy
    if (t.contains('OSMANLI') ||
        ['OSM', 'OPB'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/osmanli-menkul.svg',
      ];
    }

    // 21. Ata Portföy
    if (t.contains('ATA') ||
        ['AAS', 'AED', 'AES'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/ata-gyo.svg',
      ];
    }

    // 22. Marmara Capital
    if (t.contains('MARMARA') || code == 'MAC') {
      return const [
        'https://s3-symbol-logo.tradingview.com/marmara-as.svg',
      ];
    }

    // 23. Azimut Portföy
    if (t.contains('AZIMUT') ||
        ['GSP', 'GEO', 'GZL'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/azimut.svg',
      ];
    }

    // 24. Ünlü Portföy
    if (t.contains('UNLU') ||
        ['UNL', 'UPD'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/unlu-yatirim-holding.svg',
      ];
    }

    // 25. TSKB Portföy
    if (t.contains('TSKB')) {
      return const [
        'https://s3-symbol-logo.tradingview.com/t-s-k-b.svg',
      ];
    }

    // 26. Nurol Portföy
    if (t.contains('NUROL')) {
      return const [
        'https://s3-symbol-logo.tradingview.com/nurol.svg',
      ];
    }

    // 27. A1 Portföy
    if (t.contains('A1') || ['ACF'].contains(code)) {
      return const [
        'https://s3-symbol-logo.tradingview.com/a1-capital-yatirim.svg',
      ];
    }

    // 28. Tera Portföy
    if (t.contains('TERA')) {
      return const [
        'https://s3-symbol-logo.tradingview.com/tera-yatirim-menkul-degerler.svg',
      ];
    }

    return const [];
  }

  /// Fon unvanından veya kodundan kurucu banka / aracı kurum logosunu tespit eder
  static String? resolveFundLogo(String fundCode, String fundTitle) {
    final list = resolveFundLogoCandidates(fundCode, fundTitle);
    return list.isNotEmpty ? list.first : null;
  }

  /// Bilinen varlıklar (Fonlar, Döviz, Emtia, Popüler Hisseler) için anlık logo tespiti
  static String? getKnownAssetLogo(String symbol, AssetCategory category, [String? name]) {
    final sym = symbol.trim().toUpperCase().replaceAll('.IS', '');
    if (_logoCache.containsKey(sym)) return _logoCache[sym];

    if (category == AssetCategory.fon) {
      final logo = resolveFundLogo(sym, name ?? '');
      if (logo != null) {
        _logoCache[sym] = logo;
        return logo;
      }
      return null;
    }

    if (category == AssetCategory.doviz) {
      final code = sym.replaceAll('/TRY', '').replaceAll('TRY', '').trim();
      switch (code) {
        case 'USD':
        case 'DOLAR':
          return 'https://s3-symbol-logo.tradingview.com/country/US.svg';
        case 'EUR':
        case 'EURO':
          return 'https://s3-symbol-logo.tradingview.com/country/EU.svg';
        case 'GBP':
        case 'STERLIN':
          return 'https://s3-symbol-logo.tradingview.com/country/GB.svg';
        case 'CHF':
          return 'https://s3-symbol-logo.tradingview.com/country/CH.svg';
        case 'CAD':
          return 'https://s3-symbol-logo.tradingview.com/country/CA.svg';
        case 'JPY':
          return 'https://s3-symbol-logo.tradingview.com/country/JP.svg';
        case 'SAR':
          return 'https://s3-symbol-logo.tradingview.com/country/SA.svg';
        case 'AUD':
          return 'https://s3-symbol-logo.tradingview.com/country/AU.svg';
        case 'RUB':
          return 'https://s3-symbol-logo.tradingview.com/country/RU.svg';
        default:
          return null;
      }
    }

    if (category == AssetCategory.emtia) {
      final lower = symbol.toLowerCase();
      if (lower.contains('altin') ||
          lower.contains('altın') ||
          lower.contains('ceyrek') ||
          lower.contains('çeyrek') ||
          lower.contains('yarim') ||
          lower.contains('yarım') ||
          lower.contains('tam') ||
          lower.contains('cumhuriyet') ||
          lower.contains('ons') ||
          lower.contains('bilezik') ||
          lower == 'xau' ||
          lower == 'gc=f' ||
          lower == 'gldtr') {
        return 'https://s3-symbol-logo.tradingview.com/metal/gold.svg';
      }
      if (lower.contains('gumus') ||
          lower.contains('gümüş') ||
          lower == 'xag' ||
          lower == 'si=f') {
        return 'https://s3-symbol-logo.tradingview.com/metal/silver.svg';
      }
      if (lower.contains('platin')) {
        return 'https://s3-symbol-logo.tradingview.com/metal/platinum.svg';
      }
      return 'https://s3-symbol-logo.tradingview.com/metal/gold.svg';
    }

    if (category == AssetCategory.kripto) {
      if (sym == 'BTC' || sym == 'BITCOIN') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC.svg';
      }
      if (sym == 'ETH' || sym == 'ETHEREUM') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCETH.svg';
      }
      if (sym == 'SOL' || sym == 'SOLANA') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCSOL.svg';
      }
      if (sym == 'BNB') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCBNB.svg';
      }
      if (sym == 'XRP') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCXRP.svg';
      }
      if (sym == 'AVAX') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCAVAX.svg';
      }
      if (sym == 'DOGE') {
        return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCDOGE.svg';
      }
      return 'https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC.svg';
    }

    // BIST ve küresel hisseler için anlık eşleşmeler
    const knownStocks = {
      'THYAO': 'https://s3-symbol-logo.tradingview.com/turk-hava-yollari.svg',
      'ASELS': 'https://s3-symbol-logo.tradingview.com/aselsan.svg',
      'GARAN': 'https://s3-symbol-logo.tradingview.com/garanti.svg',
      'EREGL': 'https://s3-symbol-logo.tradingview.com/eregli-demir.svg',
      'SISE': 'https://s3-symbol-logo.tradingview.com/sisecam.svg',
      'KCHOL': 'https://s3-symbol-logo.tradingview.com/koc.svg',
      'BIMAS': 'https://s3-symbol-logo.tradingview.com/magazalar.svg',
      'TUPRS': 'https://s3-symbol-logo.tradingview.com/tupras.svg',
      'AKBNK': 'https://s3-symbol-logo.tradingview.com/akbank.svg',
      'YKBNK': 'https://s3-symbol-logo.tradingview.com/yapi-ve-kredi.svg',
      'SAHOL': 'https://s3-symbol-logo.tradingview.com/sabanci.svg',
      'FROTO': 'https://s3-symbol-logo.tradingview.com/ford-otosan.svg',
      'TOASO': 'https://s3-symbol-logo.tradingview.com/tofas.svg',
      'ISCTR': 'https://s3-symbol-logo.tradingview.com/is-bankasi.svg',
      'PETKM': 'https://s3-symbol-logo.tradingview.com/petkim.svg',
      'ENKAI': 'https://s3-symbol-logo.tradingview.com/enka-insaat.svg',
      'TTKOM': 'https://s3-symbol-logo.tradingview.com/turk-telekom.svg',
      'TCELL': 'https://s3-symbol-logo.tradingview.com/turkcell.svg',
      'PGSUS': 'https://s3-symbol-logo.tradingview.com/pegasus.svg',
      'KOZAL': 'https://s3-symbol-logo.tradingview.com/koza-altin.svg',
      'KRDMD': 'https://s3-symbol-logo.tradingview.com/kardemir.svg',
      'AAPL': 'https://s3-symbol-logo.tradingview.com/apple.svg',
      'TSLA': 'https://s3-symbol-logo.tradingview.com/tesla.svg',
      'MSFT': 'https://s3-symbol-logo.tradingview.com/microsoft.svg',
      'NVDA': 'https://s3-symbol-logo.tradingview.com/nvidia.svg',
      'AMZN': 'https://s3-symbol-logo.tradingview.com/amazon.svg',
      'GOOG': 'https://s3-symbol-logo.tradingview.com/google.svg',
      'GOOGL': 'https://s3-symbol-logo.tradingview.com/google.svg',
      'META': 'https://s3-symbol-logo.tradingview.com/meta.svg',
      'BTC': 'https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC.svg',
      'ETH': 'https://s3-symbol-logo.tradingview.com/crypto/XTVCETH.svg',
    };

    if (knownStocks.containsKey(sym)) {
      return knownStocks[sym];
    }

    return null;
  }

  /// API destekliyorsa varlığın resmi logo / ikon URL'sini çeker
  static Future<String?> fetchAssetLogo(
      String symbol, AssetCategory category, [String? name]) async {
    await ensureLogoCacheLoaded();
    final known = getKnownAssetLogo(symbol, category, name);
    if (known != null) return known;

    // Fonlar için kurum eşleştirmesi
    if (category == AssetCategory.fon) {
      return resolveFundLogo(symbol, name ?? '');
    }

    final clean = normalizeSymbol(symbol).replaceAll('.IS', '');
    if (_logoCache.containsKey(clean)) return _logoCache[clean];

    try {
      final url =
          'https://symbol-search.tradingview.com/symbol_search/v3/?text=$clean';
      final response =
          await AppHttpClient.get(url, timeout: const Duration(seconds: 4));
      if (response == null || response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['symbols'] as List<dynamic>?;
      if (list == null || list.isEmpty) return null;

      dynamic match;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final s = (item['symbol'] as String?)?.toUpperCase();
          final ex = (item['exchange'] as String?)?.toUpperCase();
          if (s == clean && ex == 'BIST') {
            match = item;
            break;
          }
        }
      }

      if (match == null) {
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final s = (item['symbol'] as String?)?.toUpperCase();
            if (s == clean) {
              match = item;
              break;
            }
          }
        }
      }

      match ??= list.first;

      if (match is Map<String, dynamic>) {
        final logoid = match['logoid'] as String? ??
            (match['logo'] is Map ? match['logo']['logoid'] as String? : null);
        if (logoid != null && logoid.isNotEmpty) {
          final logoUrl = 'https://s3-symbol-logo.tradingview.com/$logoid.svg';
          cacheLogo(clean, logoUrl);
          return logoUrl;
        }

        final currLogo = match['currency-logoid'] as String?;
        if (currLogo != null && currLogo.isNotEmpty) {
          final logoUrl = 'https://s3-symbol-logo.tradingview.com/country/$currLogo.svg';
          cacheLogo(clean, logoUrl);
          return logoUrl;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ana sorgu metodu
  static Future<MarketAssetInfo?> fetchAssetData({
    required AssetCategory category,
    required String symbol,
    DateTime? purchaseDate,
  }) async {
    final cleanSymbol = symbol.trim();
    if (cleanSymbol.isEmpty) return null;

    try {
      MarketAssetInfo? result;
      switch (category) {
        case AssetCategory.fon:
          result = await _fetchTefasFund(cleanSymbol.toUpperCase(), purchaseDate);
          // Eğer TEFAS fonu ise (bilinen TEFAS fonu veya 3 harfli fon kodu) ve TEFAS yanıt vermediyse,
          // kesinlikle yabancı tekil hisseye (örn: GPN -> Global Payments Inc.) düşme!
          if (result == null) {
            final isTefasFund = AssetCatalogService.isKnownTefasFund(cleanSymbol) ||
                (cleanSymbol.length == 3 && !cleanSymbol.endsWith('.IS'));
            if (!isTefasFund) {
              result = await _fetchBistStock(cleanSymbol, purchaseDate);
            }
          }
          break;
        case AssetCategory.hisse:
          result = await _fetchBistStock(cleanSymbol, purchaseDate);
          // Eğer hisse olarak bulunamadıysa TEFAS fonu olarak kontrol et
          result ??= await _fetchTefasFund(cleanSymbol.toUpperCase(), purchaseDate);
          break;
        case AssetCategory.doviz:
          result = await _fetchCurrency(cleanSymbol, purchaseDate);
          break;
        case AssetCategory.emtia:
          result = await _fetchCommodity(cleanSymbol, purchaseDate);
          break;
        case AssetCategory.kripto:
          result = await _fetchCrypto(cleanSymbol, purchaseDate);
          break;
      }

      if (result != null) {
        final logo = await fetchAssetLogo(
            cleanSymbol, category, result.name);
        return result
            .withResolvedCategory(category)
            .copyWith(iconUrl: logo ?? result.iconUrl);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // 1. TEFAS FONLARI (Resmi TEFAS JSON API - Akıllı Kuyruk & Jitter ile)
  // -------------------------------------------------------------
  static Future<MarketAssetInfo?> _fetchTefasFund(
    String fundCode,
    DateTime? purchaseDate,
  ) async {
    final info = await TefasService.fetchFundPriceHistory(fundCode, periodMonths: 60);
    if (info == null) return null;

    final currentPrice = info.currentPrice;
    final fundTitle = info.name.isNotEmpty ? info.name : fundCode;
    final priceHistory = info.priceHistory;

    double? purchasePrice;
    if (purchaseDate != null && priceHistory.isNotEmpty) {
      purchasePrice = _findClosestPrice(priceHistory, purchaseDate);
    }

    // Dönemsel Değişim Oranları (%)
    final sortedDates = priceHistory.keys.toList()..sort();
    final daily = _calcChange(sortedDates, priceHistory, 1, currentPrice);
    final weekly = _calcChange(sortedDates, priceHistory, 7, currentPrice);
    final monthly = _calcChange(sortedDates, priceHistory, 30, currentPrice);
    final threeMonthly = _calcChange(sortedDates, priceHistory, 90, currentPrice);
    final sixMonthly = _calcChange(sortedDates, priceHistory, 180, currentPrice);
    final yearly = _calcChange(sortedDates, priceHistory, 365, currentPrice);

    final fundLogo = resolveFundLogo(fundCode, fundTitle);
    final stopajRate = defaultWithholdingTaxRate(AssetCategory.fon, fundTitle, fundCode);

    return MarketAssetInfo(
      symbol: fundCode,
      name: fundTitle,
      currentPrice: currentPrice,
      purchaseDatePrice: purchasePrice,
      iconUrl: fundLogo,
      dailyChangePercent: daily,
      weeklyChangePercent: weekly,
      monthlyChangePercent: monthly,
      threeMonthlyChangePercent: threeMonthly,
      sixMonthlyChangePercent: sixMonthly,
      yearlyChangePercent: yearly,
      earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
      withholdingTaxRate: stopajRate,
    );
  }

  static double defaultWithholdingTaxRate(
    AssetCategory category,
    String name, [
    String? symbol,
  ]) {
    if (category != AssetCategory.fon) return 0.0;
    final upper = name.toUpperCase();
    if (upper.contains('HİSSE SENEDİ YOĞUN') ||
        upper.contains('HİSSE YOĞUN') ||
        upper.contains('HISSE SENEDI YOGUN') ||
        upper.contains('HISSE YOGUN')) {
      return 0.0;
    }
    return 17.5;
  }

  static String normalizeSymbol(String input) {
    return input
        .trim()
        .replaceAll('İ', 'I')
        .replaceAll('i', 'I')
        .replaceAll('ı', 'I')
        .replaceAll('ş', 'S')
        .replaceAll('Ş', 'S')
        .replaceAll('ğ', 'G')
        .replaceAll('Ğ', 'G')
        .replaceAll('ç', 'C')
        .replaceAll('Ç', 'C')
        .replaceAll('ö', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('ü', 'U')
        .replaceAll('Ü', 'U')
        .toUpperCase();
  }

  // -------------------------------------------------------------
  // 2. BORSA İSTANBUL VE YABANCI HİSSELER (Yahoo Finance)
  // -------------------------------------------------------------
  static Future<MarketAssetInfo?> _fetchBistStock(
    String stockCode,
    DateTime? purchaseDate,
  ) async {
    final cleanCode = normalizeSymbol(stockCode);
    if (cleanCode.isEmpty) return null;

    // Önce BIST uzantısı ile sorgula (örn: THYAO.IS, ISCTR.IS)
    MarketAssetInfo? result = await _fetchYahooChart(
      cleanCode.endsWith('.IS') ? cleanCode : '$cleanCode.IS',
      displaySymbol: cleanCode.replaceAll('.IS', ''),
      purchaseDate: purchaseDate,
    );

    // Bulunamazsa doğrudan sembolle sorgula (örn: AAPL, TSLA, NVDA)
    if (result == null && !cleanCode.endsWith('.IS') && cleanCode.length >= 3) {
      result = await _fetchYahooChart(
        cleanCode,
        displaySymbol: cleanCode,
        purchaseDate: purchaseDate,
      );
    }

    return result;
  }

  static Future<MarketAssetInfo?> _fetchYahooChart(
    String yahooTicker, {
    required String displaySymbol,
    DateTime? purchaseDate,
  }) async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$yahooTicker?interval=1d&range=5y';
      final response =
          await AppHttpClient.get(url, timeout: const Duration(seconds: 5));
      if (response == null || response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (result == null) return null;

      final meta = result['meta'] as Map<String, dynamic>;
      final stockName = (meta['shortName'] as String?) ??
          (meta['longName'] as String?) ??
          displaySymbol;
      final currency = (meta['currency'] as String?)?.toUpperCase() ?? 'TRY';

      double fxRate = 1.0;
      if (currency == 'USD') {
        fxRate = await getUsdTryRate();
      } else if (currency == 'EUR') {
        fxRate = await getEurTryRate();
      }

      final timestamps = (result['timestamp'] as List<dynamic>?) ?? [];
      final quote = (result['indicators']?['quote'] as List<dynamic>?)?.firstOrNull;
      final closePrices = (quote?['close'] as List<dynamic>?) ?? [];

      final priceHistory = <DateTime, double>{};
      for (int i = 0; i < timestamps.length && i < closePrices.length; i++) {
        final ts = timestamps[i];
        final cp = closePrices[i];
        if (ts is num && cp is num) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000);
          priceHistory[DateTime(d.year, d.month, d.day)] = cp.toDouble() * fxRate;
        }
      }

      final sortedDates = priceHistory.keys.toList()..sort();
      double currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      if (currentPrice <= 0 && sortedDates.isNotEmpty) {
        currentPrice = (priceHistory[sortedDates.last] ?? 0.0) / fxRate;
      }
      if (currentPrice <= 0) return null;
      currentPrice = currentPrice * fxRate;

      double? purchasePrice;
      if (purchaseDate != null) {
        purchasePrice = _findClosestPrice(priceHistory, purchaseDate);
      }

      final metaDaily = (meta['regularMarketChangePercent'] as num?)?.toDouble();
      final daily = metaDaily != null
          ? double.parse(metaDaily.toStringAsFixed(2))
          : _calcChange(sortedDates, priceHistory, 1, currentPrice);

      final weekly = _calcChange(sortedDates, priceHistory, 7, currentPrice);
      final monthly = _calcChange(sortedDates, priceHistory, 30, currentPrice);
      final threeMonthly = _calcChange(sortedDates, priceHistory, 90, currentPrice);
      final sixMonthly = _calcChange(sortedDates, priceHistory, 180, currentPrice);
      final yearly = _calcChange(sortedDates, priceHistory, 365, currentPrice);

      return MarketAssetInfo(
        symbol: displaySymbol,
        name: stockName,
        currentPrice: currentPrice,
        purchaseDatePrice: purchasePrice,
        dailyChangePercent: daily,
        weeklyChangePercent: weekly,
        monthlyChangePercent: monthly,
        threeMonthlyChangePercent: threeMonthly,
        sixMonthlyChangePercent: sixMonthly,
        yearlyChangePercent: yearly,
        earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
      );
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // 3. DÖVİZ (USD, EUR, GBP vb.)
  // -------------------------------------------------------------
  static Future<MarketAssetInfo?> _fetchCurrency(
    String rawSymbol,
    DateTime? purchaseDate,
  ) async {
    String code = rawSymbol.replaceAll('/TRY', '').replaceAll('TRY', '').trim();
    code = normalizeSymbol(code);
    if (code == 'DOLAR') code = 'USD';
    if (code == 'EURO') code = 'EUR';
    if (code == 'STERLIN' || code == 'POUND') code = 'GBP';

    final yahooSym = '${code}TRY=X';
    final yahooResult = await _fetchYahooForex(yahooSym, code, purchaseDate);
    if (yahooResult != null) return yahooResult;

    return await _fetchTruncgilSingle(code, isCurrency: true);
  }

  static Future<MarketAssetInfo?> _fetchYahooForex(
    String yahooSym,
    String code,
    DateTime? purchaseDate,
  ) async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$yahooSym?interval=1d&range=5y';
      final response =
          await AppHttpClient.get(url, timeout: const Duration(seconds: 5));
      if (response == null || response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (result == null) return null;

      final meta = result['meta'] as Map<String, dynamic>;
      final timestamps = (result['timestamp'] as List<dynamic>?) ?? [];
      final quote = (result['indicators']?['quote'] as List<dynamic>?)?.firstOrNull;
      final closePrices = (quote?['close'] as List<dynamic>?) ?? [];

      final priceHistory = <DateTime, double>{};
      for (int i = 0; i < timestamps.length && i < closePrices.length; i++) {
        final ts = timestamps[i];
        final cp = closePrices[i];
        if (ts is num && cp is num) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000);
          priceHistory[DateTime(d.year, d.month, d.day)] = cp.toDouble();
        }
      }

      final sortedDates = priceHistory.keys.toList()..sort();
      double currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      if (currentPrice <= 0 && sortedDates.isNotEmpty) {
        currentPrice = priceHistory[sortedDates.last] ?? 0.0;
      }

      double? purchasePrice;
      if (purchaseDate != null) {
        purchasePrice = _findClosestPrice(priceHistory, purchaseDate);
      }

      final metaDaily = (meta['regularMarketChangePercent'] as num?)?.toDouble();
      final daily = metaDaily != null
          ? double.parse(metaDaily.toStringAsFixed(2))
          : _calcChange(sortedDates, priceHistory, 1, currentPrice);

      final weekly = _calcChange(sortedDates, priceHistory, 7, currentPrice);
      final monthly = _calcChange(sortedDates, priceHistory, 30, currentPrice);
      final threeMonthly = _calcChange(sortedDates, priceHistory, 90, currentPrice);
      final sixMonthly = _calcChange(sortedDates, priceHistory, 180, currentPrice);
      final yearly = _calcChange(sortedDates, priceHistory, 365, currentPrice);

      final displayName = _currencyName(code);

      return MarketAssetInfo(
        symbol: '$code/TRY',
        name: displayName,
        currentPrice: currentPrice,
        purchaseDatePrice: purchasePrice,
        dailyChangePercent: daily,
        weeklyChangePercent: weekly,
        monthlyChangePercent: monthly,
        threeMonthlyChangePercent: threeMonthly,
        sixMonthlyChangePercent: sixMonthly,
        yearlyChangePercent: yearly,
        earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
      );
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // 4. EMTİA (Gram Altın, Çeyrek Altın, Gümüş, Ons vb.)
  // -------------------------------------------------------------
  static Future<MarketAssetInfo?> _fetchCommodity(
    String rawSymbol,
    DateTime? purchaseDate,
  ) async {
    final sym = rawSymbol
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o');

    String? itemKey;
    String? itemName;

    if (sym.contains('altin.s1')) {
      return await _fetchBistStock('ALTIN.S1', purchaseDate);
    } else if (sym.contains('gumus') || sym == 'xag' || sym == 'si') {
      itemKey = 'gumus';
      itemName = 'Gümüş (Gram / TL)';
    } else if (sym.contains('ceyrek')) {
      itemKey = 'ceyrek-altin';
      itemName = 'Çeyrek Altın';
    } else if (sym.contains('yarim')) {
      itemKey = 'yarim-altin';
      itemName = 'Yarım Altın';
    } else if (sym.contains('tam')) {
      itemKey = 'tam-altin';
      itemName = 'Tam Altın';
    } else if (sym.contains('cumhuriyet') || sym.contains('ata')) {
      itemKey = 'cumhuriyet-altini';
      itemName = 'Cumhuriyet Altını';
    } else if (sym.contains('ons')) {
      itemKey = 'ons';
      itemName = 'Ons Altın (USD)';
    } else if (sym.contains('22') || sym.contains('bilezik')) {
      itemKey = '22-ayar-bilezik';
      itemName = '22 Ayar Bilezik';
    } else if (sym.contains('platin')) {
      itemKey = 'gram-platin';
      itemName = 'Gram Platin';
    } else if (sym.contains('altin') || sym.contains('gram') || sym == 'xau' || sym == 'gau') {
      itemKey = 'gram-altin';
      itemName = 'Gram Altın';
    } else {
      return null;
    }

    // 1. Canlı Kapalıçarşı / Piyasa Fiyatı
    final info = await _fetchTruncgilSingle(itemKey, isCurrency: false, fallbackName: itemName);

    // 2. Ons ve Döviz geçmişi üzerinden tam tarihsel grafik ve yüzdesel değişimler
    final history = await _fetchCommodityHistory(itemKey);

    double currentPrice = info?.currentPrice ?? 0.0;

    // Ons Altın USD cinsinden geldiğinde güncel kurla TL'ye çevrilir
    if (itemKey == 'ons') {
      final usdRate = await getUsdTryRate();
      if (currentPrice > 0) currentPrice *= usdRate;
      for (final key in history.keys.toList()) {
        history[key] = (history[key] ?? 0.0) * usdRate;
      }
    }

    final sortedDates = history.keys.toList()..sort();
    final latestHistoryPrice = sortedDates.isNotEmpty ? (history[sortedDates.last] ?? 0.0) : 0.0;

    if (currentPrice <= 0 && latestHistoryPrice > 0) {
      currentPrice = latestHistoryPrice;
    }

    double? purchasePrice;
    if (purchaseDate != null && history.isNotEmpty) {
      final pastBase = _findClosestPrice(history, purchaseDate);
      if (pastBase != null) {
        if (latestHistoryPrice > 0 && currentPrice > 0) {
          final ratio = currentPrice / latestHistoryPrice;
          purchasePrice = double.parse((pastBase * ratio).toStringAsFixed(2));
        } else {
          purchasePrice = pastBase;
        }
      }
    }

    double daily = info?.dailyChangePercent ?? 0.0;
    double weekly = 0.0;
    double monthly = 0.0;
    double threeMonthly = 0.0;
    double sixMonthly = 0.0;
    double yearly = 0.0;

    if (history.isNotEmpty && latestHistoryPrice > 0) {
      if (daily == 0.0) {
        daily = _calcChange(sortedDates, history, 1, latestHistoryPrice);
      }
      weekly = _calcChange(sortedDates, history, 7, latestHistoryPrice);
      monthly = _calcChange(sortedDates, history, 30, latestHistoryPrice);
      threeMonthly = _calcChange(sortedDates, history, 90, latestHistoryPrice);
      sixMonthly = _calcChange(sortedDates, history, 180, latestHistoryPrice);
      yearly = _calcChange(sortedDates, history, 365, latestHistoryPrice);
    }

    return MarketAssetInfo(
      symbol: rawSymbol.toUpperCase(),
      name: info?.name ?? itemName,
      currentPrice: currentPrice,
      purchaseDatePrice: purchasePrice,
      dailyChangePercent: daily,
      weeklyChangePercent: weekly,
      monthlyChangePercent: monthly,
      threeMonthlyChangePercent: threeMonthly,
      sixMonthlyChangePercent: sixMonthly,
      yearlyChangePercent: yearly,
      earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
    );
  }

  // Emtia için tarihsel fiyat serisi oluşturucu
  static Future<Map<DateTime, double>> _fetchCommodityHistory(String itemKey) async {
    try {
      final isSilver = itemKey == 'gumus';
      final isOns = itemKey == 'ons';
      final commoditySym = isSilver ? 'SI=F' : 'GC=F';

      final futuresUrl =
          'https://query1.finance.yahoo.com/v8/finance/chart/$commoditySym?interval=1d&range=5y';
      final respFutures = await AppHttpClient.get(futuresUrl, timeout: const Duration(seconds: 5));
      if (respFutures == null || respFutures.statusCode != 200) return {};

      final dataFutures = jsonDecode(respFutures.body) as Map<String, dynamic>;
      final resFutures = (dataFutures['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (resFutures == null) return {};

      final tsFutures = (resFutures['timestamp'] as List<dynamic>?) ?? [];
      final closesFutures = (resFutures['indicators']?['quote']?[0]?['close'] as List<dynamic>?) ?? [];

      final Map<DateTime, double> futuresMap = {};
      for (int i = 0; i < tsFutures.length && i < closesFutures.length; i++) {
        if (tsFutures[i] is num && closesFutures[i] is num) {
          final d = DateTime.fromMillisecondsSinceEpoch((tsFutures[i] as int) * 1000);
          futuresMap[DateTime(d.year, d.month, d.day)] = (closesFutures[i] as num).toDouble();
        }
      }

      if (isOns) {
        return futuresMap;
      }

      // Gram bazlı TL hesabı için USD/TRY kuru geçmişi
      final usdUrl =
          'https://query1.finance.yahoo.com/v8/finance/chart/USDTRY=X?interval=1d&range=5y';
      final respUsd = await AppHttpClient.get(usdUrl, timeout: const Duration(seconds: 5));
      if (respUsd == null || respUsd.statusCode != 200) return {};

      final dataUsd = jsonDecode(respUsd.body) as Map<String, dynamic>;
      final resUsd = (dataUsd['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (resUsd == null) return {};

      final tsUsd = (resUsd['timestamp'] as List<dynamic>?) ?? [];
      final closesUsd = (resUsd['indicators']?['quote']?[0]?['close'] as List<dynamic>?) ?? [];

      final Map<DateTime, double> usdMap = {};
      for (int i = 0; i < tsUsd.length && i < closesUsd.length; i++) {
        if (tsUsd[i] is num && closesUsd[i] is num) {
          final d = DateTime.fromMillisecondsSinceEpoch((tsUsd[i] as int) * 1000);
          usdMap[DateTime(d.year, d.month, d.day)] = (closesUsd[i] as num).toDouble();
        }
      }

      final Map<DateTime, double> resultMap = {};
      double lastKnownUsd = 40.0;

      for (final entry in futuresMap.entries) {
        final day = entry.key;
        final onsPrice = entry.value;
        final usd = usdMap[day] ??
            usdMap[day.subtract(const Duration(days: 1))] ??
            usdMap[day.subtract(const Duration(days: 2))] ??
            usdMap[day.subtract(const Duration(days: 3))] ??
            lastKnownUsd;
        lastKnownUsd = usd;

        // 1 Ons = 31.1034768 gram
        final gramPrice = (onsPrice / 31.1034768) * usd;
        resultMap[day] = double.parse(gramPrice.toStringAsFixed(2));
      }

      return resultMap;
    } catch (_) {
      return {};
    }
  }

  // Truncgil API'den anlık veri çekme
  static Future<MarketAssetInfo?> _fetchTruncgilSingle(
    String key, {
    required bool isCurrency,
    String? fallbackName,
  }) async {
    try {
      final response = await AppHttpClient.get(
        'https://finans.truncgil.com/today.json',
        timeout: const Duration(seconds: 4),
      );
      if (response == null || response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final item = data[key] as Map<String, dynamic>?;
      if (item == null) return null;

      final rawSatis = item['Satış'] as String? ?? '';
      // Para birimi simgelerini ($ € ₺ TL) temizle
      final cleanSatis = rawSatis
          .replaceAll(RegExp(r'[^0-9,\.]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final currentPrice = double.tryParse(cleanSatis) ?? 0.0;

      final degisimStr = (item['Değişim'] as String?)
              ?.replaceAll('%', '')
              .replaceAll(',', '.')
              .trim() ??
          '0';
      final dailyChange = double.tryParse(degisimStr) ?? 0.0;

      final name = fallbackName ?? (isCurrency ? _currencyName(key) : key);

      return MarketAssetInfo(
        symbol: isCurrency ? '$key/TRY' : key.toUpperCase(),
        name: name,
        currentPrice: currentPrice,
        dailyChangePercent: dailyChange,
      );
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // 5. KRİPTO PARA (BTC, ETH, SOL vb. - Binance & Yahoo Finance)
  // -------------------------------------------------------------
  static Future<MarketAssetInfo?> _fetchCrypto(
    String rawSymbol,
    DateTime? purchaseDate,
  ) async {
    final clean = rawSymbol
        .replaceAll('/TRY', '')
        .replaceAll('TRY', '')
        .replaceAll('/USDT', '')
        .replaceAll('USDT', '')
        .replaceAll('/USD', '')
        .replaceAll('USD', '')
        .trim();
    String sym = normalizeSymbol(clean).toUpperCase();
    String name = sym;

    if (sym == 'BITCOIN' || sym == 'BTC') {
      sym = 'BTC';
      name = 'Bitcoin';
    } else if (sym == 'ETHEREUM' || sym == 'ETH') {
      sym = 'ETH';
      name = 'Ethereum';
    } else if (sym == 'SOLANA' || sym == 'SOL') {
      sym = 'SOL';
      name = 'Solana';
    } else if (sym == 'RIPPLE' || sym == 'XRP') {
      sym = 'XRP';
      name = 'XRP';
    } else if (sym == 'BINANCE' || sym == 'BNB') {
      sym = 'BNB';
      name = 'BNB';
    } else if (sym == 'AVALANCHE' || sym == 'AVAX') {
      sym = 'AVAX';
      name = 'Avalanche';
    } else if (sym == 'DOGECOIN' || sym == 'DOGE') {
      sym = 'DOGE';
      name = 'Dogecoin';
    }

    // 1. Binance TRY çifti (Gerçek zamanlı TL fiyatı ve klines geçmişi)
    try {
      final pair = '${sym}TRY';
      final tickerUri =
          'https://api.binance.com/api/v3/ticker/24hr?symbol=$pair';
      final tickerResp =
          await AppHttpClient.get(tickerUri, timeout: const Duration(seconds: 4));

      if (tickerResp != null && tickerResp.statusCode == 200) {
        final tickerData = jsonDecode(tickerResp.body) as Map<String, dynamic>;
        final currentPrice =
            double.tryParse(tickerData['lastPrice']?.toString() ?? '') ?? 0.0;
        final dailyChange = double.tryParse(
                tickerData['priceChangePercent']?.toString() ?? '') ??
            0.0;

        if (currentPrice > 0) {
          final priceHistory = <DateTime, double>{};
          try {
            final klinesUri =
                'https://api.binance.com/api/v3/klines?symbol=$pair&interval=1d&limit=1000';
            final klinesResp =
                await AppHttpClient.get(klinesUri, timeout: const Duration(seconds: 4));
            if (klinesResp != null && klinesResp.statusCode == 200) {
              final klinesList = jsonDecode(klinesResp.body) as List<dynamic>;
              for (final item in klinesList) {
                if (item is List && item.length >= 5) {
                  final ts = item[0] as num?;
                  final closeP = double.tryParse(item[4].toString());
                  if (ts != null && closeP != null) {
                    final d = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
                    priceHistory[DateTime(d.year, d.month, d.day)] = closeP;
                  }
                }
              }
            }
          } catch (_) {}

          double? purchasePrice;
          if (purchaseDate != null && priceHistory.isNotEmpty) {
            purchasePrice = _findClosestPrice(priceHistory, purchaseDate);
          }

          final sortedDates = priceHistory.keys.toList()..sort();
          final weekly = _calcChange(sortedDates, priceHistory, 7, currentPrice);
          final monthly =
              _calcChange(sortedDates, priceHistory, 30, currentPrice);
          final threeMonthly =
              _calcChange(sortedDates, priceHistory, 90, currentPrice);
          final sixMonthly =
              _calcChange(sortedDates, priceHistory, 180, currentPrice);
          final yearly =
              _calcChange(sortedDates, priceHistory, 365, currentPrice);

          final logo = getKnownAssetLogo(sym, AssetCategory.kripto, name);

          return MarketAssetInfo(
            symbol: sym,
            name: name,
            currentPrice: currentPrice,
            purchaseDatePrice: purchasePrice,
            dailyChangePercent: double.parse(dailyChange.toStringAsFixed(2)),
            weeklyChangePercent: weekly,
            monthlyChangePercent: monthly,
            threeMonthlyChangePercent: threeMonthly,
            sixMonthlyChangePercent: sixMonthly,
            yearlyChangePercent: yearly,
            iconUrl: logo,
            resolvedCategory: AssetCategory.kripto,
            earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback: Yahoo Finance ($sym-USD) * USDTRY
    return await _fetchYahooCrypto(sym, name, purchaseDate);
  }

  static Future<MarketAssetInfo?> _fetchYahooCrypto(
    String sym,
    String name,
    DateTime? purchaseDate,
  ) async {
    try {
      final yahooSym = '$sym-USD';
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$yahooSym?interval=1d&range=5y';
      final response =
          await AppHttpClient.get(url, timeout: const Duration(seconds: 4));
      if (response == null || response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (result == null) return null;

      final meta = result['meta'] as Map<String, dynamic>;
      final timestamps = (result['timestamp'] as List<dynamic>?) ?? [];
      final quote =
          (result['indicators']?['quote'] as List<dynamic>?)?.firstOrNull;
      final closePrices = (quote?['close'] as List<dynamic>?) ?? [];

      final cryptoUsdHistory = <DateTime, double>{};
      for (int i = 0; i < timestamps.length && i < closePrices.length; i++) {
        final ts = timestamps[i];
        final cp = closePrices[i];
        if (ts is num && cp is num) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000);
          cryptoUsdHistory[DateTime(d.year, d.month, d.day)] = cp.toDouble();
        }
      }

      // USDTRY kuru
      final usdTryRate = await getUsdTryRate();

      final priceHistory = <DateTime, double>{};
      for (final entry in cryptoUsdHistory.entries) {
        priceHistory[entry.key] = entry.value * usdTryRate;
      }

      final sortedDates = priceHistory.keys.toList()..sort();
      double currentPriceUsd =
          (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      if (currentPriceUsd <= 0 && cryptoUsdHistory.isNotEmpty) {
        currentPriceUsd = cryptoUsdHistory[sortedDates.last] ?? 0.0;
      }
      if (currentPriceUsd <= 0) return null;

      final currentPrice = currentPriceUsd * usdTryRate;

      double? purchasePrice;
      if (purchaseDate != null) {
        purchasePrice = _findClosestPrice(priceHistory, purchaseDate);
      }

      final metaDaily =
          (meta['regularMarketChangePercent'] as num?)?.toDouble();
      final daily = metaDaily != null
          ? double.parse(metaDaily.toStringAsFixed(2))
          : _calcChange(sortedDates, priceHistory, 1, currentPrice);

      final weekly = _calcChange(sortedDates, priceHistory, 7, currentPrice);
      final monthly = _calcChange(sortedDates, priceHistory, 30, currentPrice);
      final threeMonthly =
          _calcChange(sortedDates, priceHistory, 90, currentPrice);
      final sixMonthly =
          _calcChange(sortedDates, priceHistory, 180, currentPrice);
      final yearly = _calcChange(sortedDates, priceHistory, 365, currentPrice);

      final logo = getKnownAssetLogo(sym, AssetCategory.kripto, name);

      return MarketAssetInfo(
        symbol: sym,
        name: name,
        currentPrice: currentPrice,
        purchaseDatePrice: purchasePrice,
        dailyChangePercent: daily,
        weeklyChangePercent: weekly,
        monthlyChangePercent: monthly,
        threeMonthlyChangePercent: threeMonthly,
        sixMonthlyChangePercent: sixMonthly,
        yearlyChangePercent: yearly,
        iconUrl: logo,
        resolvedCategory: AssetCategory.kripto,
        earliestDate: sortedDates.isNotEmpty ? sortedDates.first : null,
      );
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // YARDIMCI HESAPLAMALAR
  // -------------------------------------------------------------
  static double? _findClosestPrice(
    Map<DateTime, double> history,
    DateTime targetDate,
  ) {
    if (history.isEmpty) return null;
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (history.containsKey(target)) {
      return history[target];
    }

    // Hedef tarihten önceki en yakın iş gününü ara (en fazla 14 gün geriye git)
    for (int i = 1; i <= 14; i++) {
      final prev = target.subtract(Duration(days: i));
      if (history.containsKey(prev)) {
        return history[prev];
      }
    }

    // İleriye doğru en yakın iş gününü ara
    for (int i = 1; i <= 14; i++) {
      final next = target.add(Duration(days: i));
      if (history.containsKey(next)) {
        return history[next];
      }
    }

    return null;
  }

  static double _calcChange(
    List<DateTime> sortedDates,
    Map<DateTime, double> history,
    int daysAgo,
    double currentPrice,
  ) {
    if (sortedDates.isEmpty || currentPrice <= 0) return 0.0;
    // Haftasonu sapmasını önlemek için en son işlem tarihinden geriye git
    final baseDate = sortedDates.last;
    final targetDate = baseDate.subtract(Duration(days: daysAgo));
    final pastPrice = _findClosestPrice(history, targetDate);
    if (pastPrice == null || pastPrice <= 0) return 0.0;
    final change = ((currentPrice - pastPrice) / pastPrice) * 100;
    return double.parse(change.toStringAsFixed(2));
  }

  static String _currencyName(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'Amerikan Doları';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'İngiliz Sterlini';
      case 'CHF':
        return 'İsviçre Frangı';
      case 'CAD':
        return 'Kanada Doları';
      case 'JPY':
        return 'Japon Yeni';
      case 'SAR':
        return 'Suudi Arabistan Riyali';
      case 'AUD':
        return 'Avustralya Doları';
      case 'RUB':
        return 'Rus Rublesi';
      default:
        return '$code / TL';
    }
  }
}
