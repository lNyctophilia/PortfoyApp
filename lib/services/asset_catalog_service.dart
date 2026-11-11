import 'dart:convert';
import '../core/network/app_http_client.dart';
import '../models/asset_category.dart';
import 'market_data_service.dart';
import 'tefas_service.dart';

class AssetSuggestion {
  final String symbol;
  final String name;
  final AssetCategory category;
  final String? iconUrl;
  final String? subtitle;
  final bool isByf;

  const AssetSuggestion({
    required this.symbol,
    required this.name,
    required this.category,
    this.iconUrl,
    this.subtitle,
    this.isByf = false,
  });
}

class AssetCatalogService {

  /// Fon unvanından kurumsal altyazı türetir
  static String resolveFundSubtitle(String fundName) {
    final upper = fundName
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
    if (upper.contains('KUVEYT')) return 'Kuveyt Türk • Katılım Fonu';
    if (upper.contains('ALBARAKA')) return 'Albaraka • Katılım Fonu';
    if (upper.contains('GARANTI')) return 'Garanti BBVA • Fon';
    if (upper.contains('IS PORTFOY')) return 'İş Portföy • Fon';
    if (upper.contains('AK PORTFOY')) return 'Ak Portföy • Fon';
    if (upper.contains('YAPI KREDI')) return 'Yapı Kredi • Fon';
    if (upper.contains('ZIRAAT')) return 'Ziraat • Fon';
    if (upper.contains('VAKIF')) return 'Vakıf Portföy • Fon';
    if (upper.contains('TEB')) return 'TEB Portföy • Fon';
    if (upper.contains('QNB') || upper.contains('FINANS')) return 'QNB Finans • Fon';
    if (upper.contains('TACIRLER')) return 'Tacirler • Fon';
    if (upper.contains('HEDEF')) return 'Hedef Portföy • Fon';
    if (upper.contains('MARMARA') || upper.contains('MAC')) return 'Marmara Capital • Fon';
    if (upper.contains('ISTANBUL PORTFOY')) return 'İstanbul Portföy • Fon';
    if (upper.contains('OYAK')) return 'Oyak Portföy • Fon';
    if (upper.contains('GEDIK')) return 'Gedik Portföy • Fon';
    return 'TEFAS • Yatırım Fonu';
  }

  // -------------------------------------------------------------
  // 1. POPÜLER BIST & GLOBAL HİSSELERİ (Yerel Hızlı Arama)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownStocks = [
    // Popüler Borsa Yatırım Fonları (BYF / ETF)
    {'symbol': 'GLDTR', 'name': 'QNB Portföy Altın Katılım Borsa Yatırım Fonu', 'sub': 'BIST • BYF/Altın', 'isByf': 'true'},
    {'symbol': 'ZGOLD', 'name': 'Ziraat Portföy Altın Borsa Yatırım Fonu', 'sub': 'BIST • BYF/Altın', 'isByf': 'true'},
    {'symbol': 'SPY', 'name': 'SPDR S&P 500 ETF Trust', 'sub': 'NYSE • BYF/ETF', 'isByf': 'true'},
    {'symbol': 'QQQ', 'name': 'Invesco QQQ Trust (Nasdaq 100 ETF)', 'sub': 'NASDAQ • BYF/ETF', 'isByf': 'true'},
    {'symbol': 'VOO', 'name': 'Vanguard S&P 500 ETF', 'sub': 'NYSE • BYF/ETF', 'isByf': 'true'},

    // BIST 30 & Popüler BIST
    {'symbol': 'THYAO', 'name': 'Türk Hava Yolları', 'sub': 'BIST • Havacılık'},
    {'symbol': 'ASELS', 'name': 'Aselsan Elektronik', 'sub': 'BIST • Savunma Sanayii'},
    {'symbol': 'EREGL', 'name': 'Ereğli Demir Çelik', 'sub': 'BIST • Demir & Çelik'},
    {'symbol': 'KCHOL', 'name': 'Koç Holding', 'sub': 'BIST • Holding'},
    {'symbol': 'SAHOL', 'name': 'Sabancı Holding', 'sub': 'BIST • Holding'},
    {'symbol': 'TUPRS', 'name': 'Tüpraş Türkiye Petrol Rafinerileri', 'sub': 'BIST • Petrol & Rafineri'},
    {'symbol': 'SISE', 'name': 'Şişecam', 'sub': 'BIST • Cam Sanayii'},
    {'symbol': 'BIMAS', 'name': 'BİM Birleşik Mağazalar', 'sub': 'BIST • Perakende Ticaret'},
    {'symbol': 'AKBNK', 'name': 'Akbank', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'ISCTR', 'name': 'Türkiye İş Bankası (C)', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'GARAN', 'name': 'Garanti BBVA', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'YKBNK', 'name': 'Yapı ve Kredi Bankası', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'FROTO', 'name': 'Ford Otosan', 'sub': 'BIST • Otomotiv'},
    {'symbol': 'TOASO', 'name': 'Tofaş Türk Otomobil Fabrikası', 'sub': 'BIST • Otomotiv'},
    {'symbol': 'PETKM', 'name': 'Petkim Petrokimya', 'sub': 'BIST • Kimya'},
    {'symbol': 'PGSUS', 'name': 'Pegasus Hava Taşımacılığı', 'sub': 'BIST • Havacılık'},
    {'symbol': 'ENKAI', 'name': 'Enka İnşaat', 'sub': 'BIST • İnşaat & Taahhüt'},
    {'symbol': 'TTKOM', 'name': 'Türk Telekom', 'sub': 'BIST • Telekomünikasyon'},
    {'symbol': 'TCELL', 'name': 'Turkcell İletişim', 'sub': 'BIST • Telekomünikasyon'},
    {'symbol': 'KOZAL', 'name': 'Koza Altın İşletmeleri', 'sub': 'BIST • Madencilik Altın'},
    {'symbol': 'KRDMD', 'name': 'Kardemir Karabük Demir Çelik (D)', 'sub': 'BIST • Demir & Çelik'},
    {'symbol': 'ASTOR', 'name': 'Astor Enerji', 'sub': 'BIST • Elektrik & Enerji'},
    {'symbol': 'KONTR', 'name': 'Kontrolmatik Teknoloji', 'sub': 'BIST • Teknoloji Mühendislik'},
    {'symbol': 'SMRTG', 'name': 'Smart Güneş Enerjisi Teknolojileri', 'sub': 'BIST • Yenilenebilir Enerji'},
    {'symbol': 'ALARK', 'name': 'Alarko Holding', 'sub': 'BIST • Holding & Enerji'},
    {'symbol': 'ODAS', 'name': 'Odaş Elektrik Üretim', 'sub': 'BIST • Elektrik'},
    {'symbol': 'EKGYO', 'name': 'Emlak Konut GYO', 'sub': 'BIST • Gayrimenkul'},
    {'symbol': 'MGROS', 'name': 'Migros Ticaret', 'sub': 'BIST • Perakende Ticaret'},
    {'symbol': 'SOKM', 'name': 'Şok Marketler', 'sub': 'BIST • Perakende Ticaret'},
    {'symbol': 'VAKBN', 'name': 'Türkiye Vakıflar Bankası', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'HALKB', 'name': 'Türkiye Halk Bankası', 'sub': 'BIST • Bankacılık'},
    {'symbol': 'HEKTS', 'name': 'Hektaş Ticaret', 'sub': 'BIST • Tarım & Kimya'},
    {'symbol': 'SASA', 'name': 'Sasa Polyester Sanayi', 'sub': 'BIST • Kimya Tekstil'},
    {'symbol': 'ARCLK', 'name': 'Arçelik', 'sub': 'BIST • Beyaz Eşya'},
    {'symbol': 'VESTL', 'name': 'Vestel Elektronik', 'sub': 'BIST • Elektronik'},
    {'symbol': 'VESBE', 'name': 'Vestel Beyaz Eşya', 'sub': 'BIST • Beyaz Eşya'},
    {'symbol': 'CCOLA', 'name': 'Coca-Cola İçecek', 'sub': 'BIST • İçecek'},
    {'symbol': 'DOAS', 'name': 'Doğuş Otomotiv', 'sub': 'BIST • Otomotiv'},
    {'symbol': 'TAVHL', 'name': 'TAV Havalimanları Holding', 'sub': 'BIST • Havacılık Hizmetleri'},
    {'symbol': 'OYAKC', 'name': 'Oyak Çimento', 'sub': 'BIST • Çimento'},
    {'symbol': 'BRSAN', 'name': 'Borusan Boru Sanayi', 'sub': 'BIST • Metal Boru'},
    {'symbol': 'MTRKS', 'name': 'Matriks Bilgi Dağıtım', 'sub': 'BIST • Finansal Yazılım'},

    // ABD / Global Hisseler
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'sub': 'NASDAQ • Teknoloji'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'sub': 'NASDAQ • Yazılım & Bulut'},
    {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'sub': 'NASDAQ • Yarı İletken Yapay Zeka'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'sub': 'NASDAQ • Elektrikli Araç'},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'sub': 'NASDAQ • E-Ticaret & Bulut'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc. (Google)', 'sub': 'NASDAQ • İnternet & Yapay Zeka'},
    {'symbol': 'META', 'name': 'Meta Platforms (Facebook)', 'sub': 'NASDAQ • Sosyal Medya'},
    {'symbol': 'NFLX', 'name': 'Netflix Inc.', 'sub': 'NASDAQ • Eğlence'},
    {'symbol': 'AMD', 'name': 'Advanced Micro Devices (AMD)', 'sub': 'NASDAQ • Yarı İletken'},
    {'symbol': 'PLTR', 'name': 'Palantir Technologies', 'sub': 'NYSE • Veri Analitiği AI'},
  ];

  // -------------------------------------------------------------
  // 3. POPÜLER KRİPTO PARALAR (Yerel Hızlı Arama)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownCryptos = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'sub': 'Kripto • Piyasa Değeri #1'},
    {'symbol': 'ETH', 'name': 'Ethereum', 'sub': 'Kripto • Akıllı Sözleşmeler'},
    {'symbol': 'SOL', 'name': 'Solana', 'sub': 'Kripto • Yüksek Hızlı Layer 1'},
    {'symbol': 'BNB', 'name': 'BNB (Binance Coin)', 'sub': 'Kripto • BNB Chain'},
    {'symbol': 'XRP', 'name': 'XRP (Ripple)', 'sub': 'Kripto • Ödemeler'},
    {'symbol': 'DOGE', 'name': 'Dogecoin', 'sub': 'Kripto • Memecoin'},
    {'symbol': 'AVAX', 'name': 'Avalanche', 'sub': 'Kripto • Layer 1 DeFi'},
    {'symbol': 'ADA', 'name': 'Cardano', 'sub': 'Kripto • PoS Blockchain'},
    {'symbol': 'SUI', 'name': 'Sui Network', 'sub': 'Kripto • Move Tabanlı L1'},
    {'symbol': 'PEPE', 'name': 'Pepe', 'sub': 'Kripto • Memecoin'},
    {'symbol': 'SHIB', 'name': 'Shiba Inu', 'sub': 'Kripto • Memecoin Ecosystem'},
    {'symbol': 'LINK', 'name': 'Chainlink', 'sub': 'Kripto • Oracle Network'},
    {'symbol': 'DOT', 'name': 'Polkadot', 'sub': 'Kripto • Multi-Chain'},
    {'symbol': 'NEAR', 'name': 'NEAR Protocol', 'sub': 'Kripto • Sharding Layer 1'},
    {'symbol': 'TRX', 'name': 'TRON', 'sub': 'Kripto • Stablecoin Ağı'},
    {'symbol': 'LTC', 'name': 'Litecoin', 'sub': 'Kripto • P2P Para'},
    {'symbol': 'BCH', 'name': 'Bitcoin Cash', 'sub': 'Kripto • P2P Para'},
    {'symbol': 'POL', 'name': 'Polygon (POL/MATIC)', 'sub': 'Kripto • Ethereum L2'},
    {'symbol': 'UNI', 'name': 'Uniswap', 'sub': 'Kripto • DEX Lideri'},
    {'symbol': 'ATOM', 'name': 'Cosmos Hub', 'sub': 'Kripto • Interoperability'},
    {'symbol': 'RENDER', 'name': 'Render', 'sub': 'Kripto • GPU Rendering AI'},
    {'symbol': 'FET', 'name': 'Artificial Superintelligence Alliance', 'sub': 'Kripto • Yapay Zeka AI'},
    {'symbol': 'KAS', 'name': 'Kaspa', 'sub': 'Kripto • PoW BlockDAG'},
    {'symbol': 'TON', 'name': 'Toncoin', 'sub': 'Kripto • Telegram Ecosystem'},
    {'symbol': 'APT', 'name': 'Aptos', 'sub': 'Kripto • Move Layer 1'},
    {'symbol': 'ARB', 'name': 'Arbitrum', 'sub': 'Kripto • Ethereum Optimistic L2'},
    {'symbol': 'OP', 'name': 'Optimism', 'sub': 'Kripto • OP Stack L2'},
    {'symbol': 'TIA', 'name': 'Celestia', 'sub': 'Kripto • Modüler Veri'},
    {'symbol': 'INJ', 'name': 'Injective', 'sub': 'Kripto • Finans Odaklı L1'},
  ];

  // -------------------------------------------------------------
  // 4. EMTİA (Kıymetli Madenler)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownCommodities = [
    {'symbol': 'GRAM-ALTIN', 'name': 'Gram Altın', 'sub': 'Kapalıçarşı • Gram / TL'},
    {'symbol': 'CEYREK-ALTIN', 'name': 'Çeyrek Altın', 'sub': 'Darphane • 1.75 gr 22 Ayar'},
    {'symbol': 'YARIM-ALTIN', 'name': 'Yarım Altın', 'sub': 'Darphane • 3.50 gr 22 Ayar'},
    {'symbol': 'TAM-ALTIN', 'name': 'Tam Altın', 'sub': 'Darphane • 7.00 gr 22 Ayar'},
    {'symbol': 'CUMHURIYET-ALTINI', 'name': 'Cumhuriyet Altını (Ata)', 'sub': 'Darphane • 7.216 gr 22 Ayar'},
    {'symbol': '22-AYAR-BILEZIK', 'name': '22 Ayar Bilezik (Gram)', 'sub': 'Kapalıçarşı • Gram / TL'},
    {'symbol': 'ONS', 'name': 'Ons Altın (USD)', 'sub': 'Global Piyasa • 31.10 gr USD'},
    {'symbol': 'GUMUS', 'name': 'Gümüş (Gram / TL)', 'sub': 'Kapalıçarşı • Gram Gümüş'},
    {'symbol': 'PLATIN', 'name': 'Gram Platin', 'sub': 'Piyasa • Gram Platin'},
    {'symbol': 'ALTIN.S1', 'name': 'Darphane Altın Sertifikası', 'sub': 'Borsa İstanbul • 0.01 gr Altın'},
  ];

  // -------------------------------------------------------------
  // 5. DÖVİZ (Para Birimleri)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownCurrencies = [
    {'symbol': 'USD', 'name': 'Amerikan Doları', 'sub': 'TCMB / Serbest Piyasa • USD/TRY'},
    {'symbol': 'EUR', 'name': 'Euro', 'sub': 'TCMB / Serbest Piyasa • EUR/TRY'},
    {'symbol': 'GBP', 'name': 'İngiliz Sterlini', 'sub': 'TCMB / Serbest Piyasa • GBP/TRY'},
    {'symbol': 'CHF', 'name': 'İsviçre Frangı', 'sub': 'TCMB / Serbest Piyasa • CHF/TRY'},
    {'symbol': 'CAD', 'name': 'Kanada Doları', 'sub': 'TCMB / Serbest Piyasa • CAD/TRY'},
    {'symbol': 'JPY', 'name': 'Japon Yeni (100)', 'sub': 'TCMB / Serbest Piyasa • JPY/TRY'},
    {'symbol': 'SAR', 'name': 'Suudi Arabistan Riyali', 'sub': 'TCMB / Serbest Piyasa • SAR/TRY'},
    {'symbol': 'AUD', 'name': 'Avustralya Doları', 'sub': 'TCMB / Serbest Piyasa • AUD/TRY'},
    {'symbol': 'RUB', 'name': 'Rus Rublesi', 'sub': 'TCMB / Serbest Piyasa • RUB/TRY'},
    {'symbol': 'KWD', 'name': 'Kuveyt Dinarı', 'sub': 'TCMB / Serbest Piyasa • KWD/TRY'},
    {'symbol': 'AED', 'name': 'BAE Dirhemi', 'sub': 'TCMB / Serbest Piyasa • AED/TRY'},
  ];

  /// Türkçe karakter duyarsız arama normalizasyonu
  static String _cleanText(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  /// TEFAS fonu mu kontrolü (GPN, KUT, TPZ vb. veya TEFAS formatında 3 karakterli fon kodları)
  static bool isKnownTefasFund(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return false;
    if (TefasService.isCachedFund(sym)) return true;
    if (sym == 'GPN' || sym == 'KUT' || sym == 'TPZ' || sym == 'TI2' || sym == 'KZL') return true;
    const nonFunds = {
      'USD', 'EUR', 'GBP', 'CHF', 'CAD', 'JPY', 'RUB', 'SAR', 'AUD', 'AED', 'KWD',
      'BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'ADA', 'DOT', 'TRX', 'LTC', 'BCH', 'UNI',
      'ONS', 'BYF', 'ETF', 'SPY', 'QQQ', 'VOO', 'AMD'
    };
    return RegExp(r'^[A-Z0-9]{3}$').hasMatch(sym) && !nonFunds.contains(sym);
  }

  /// Bilinen sabit katalogdan sembol tam eşleşmesi bulur
  static AssetSuggestion? findCurated(String symbol, [AssetCategory? category]) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return null;

    // 1. Hisseler
    if (category == null || category == AssetCategory.hisse) {
      for (final s in _knownStocks) {
        if (s['symbol']!.toUpperCase() == sym) {
          final isByf = s['isByf'] == 'true';
          final itemCat = isByf ? AssetCategory.fon : AssetCategory.hisse;
          if (category != null && category != itemCat) continue;
          return AssetSuggestion(
            symbol: s['symbol']!,
            name: s['name']!,
            category: itemCat,
            iconUrl: MarketDataService.getKnownAssetLogo(s['symbol']!, itemCat, s['name']),
            subtitle: s['sub'],
            isByf: isByf,
          );
        }
      }
    }

    // 2. Fonlar (TefasService önbelleğinde varsa)
    if (category == null || category == AssetCategory.fon) {
      final cachedFund = TefasService.getCachedFund(sym);
      if (cachedFund != null) {
        return AssetSuggestion(
          symbol: cachedFund.code,
          name: cachedFund.name,
          category: AssetCategory.fon,
          iconUrl: MarketDataService.resolveFundLogo(cachedFund.code, cachedFund.name),
          subtitle: resolveFundSubtitle(cachedFund.name),
        );
      }
    }

    // 3. Kriptolar
    for (final c in _knownCryptos) {
      if (c['symbol']!.toUpperCase() == sym) {
        return AssetSuggestion(
          symbol: c['symbol']!,
          name: c['name']!,
          category: AssetCategory.kripto,
          iconUrl: MarketDataService.getKnownAssetLogo(c['symbol']!, AssetCategory.kripto, c['name']),
          subtitle: c['sub'],
        );
      }
    }

    // 4. Emtia
    for (final cm in _knownCommodities) {
      if (cm['symbol']!.toUpperCase() == sym) {
        return AssetSuggestion(
          symbol: cm['symbol']!,
          name: cm['name']!,
          category: AssetCategory.emtia,
          iconUrl: MarketDataService.getKnownAssetLogo(cm['symbol']!, AssetCategory.emtia, cm['name']),
          subtitle: cm['sub'],
        );
      }
    }

    // 5. Döviz
    for (final cu in _knownCurrencies) {
      if (cu['symbol']!.toUpperCase() == sym) {
        return AssetSuggestion(
          symbol: cu['symbol']!,
          name: cu['name']!,
          category: AssetCategory.doviz,
          iconUrl: MarketDataService.getKnownAssetLogo(cu['symbol']!, AssetCategory.doviz, cu['name']),
          subtitle: cu['sub'],
        );
      }
    }

    return null;
  }

  /// Kategoriye göre veya tüm kategorilerde varlık ara ve öneri listesi üret
  static Future<List<AssetSuggestion>> search({
    AssetCategory? category,
    required String query,
  }) async {
    final cleanQ = _cleanText(query);
    if (cleanQ.isEmpty) {
      return [];
    }

    if (category != null) {
      switch (category) {
        case AssetCategory.fon:
          return _searchFunds(cleanQ);
        case AssetCategory.hisse:
          return _searchStocks(cleanQ);
        case AssetCategory.kripto:
          return _searchCryptos(cleanQ);
        case AssetCategory.emtia:
          return _searchCommodities(cleanQ);
        case AssetCategory.doviz:
          return _searchCurrencies(cleanQ);
      }
    }

    // category == null: tüm kategorilerde eşzamanlı ara
    final searchFutures = await Future.wait([
      _searchFunds(cleanQ),
      _searchStocks(cleanQ),
      _searchCryptos(cleanQ),
      _searchCommodities(cleanQ),
      _searchCurrencies(cleanQ),
    ]);

    final combined = <AssetSuggestion>[];
    final seen = <String>{};

    for (final list in searchFutures) {
      for (final item in list) {
        final key = '${item.category.name}_${item.isByf}_${item.symbol.trim().toUpperCase()}';
        if (!seen.contains(key)) {
          seen.add(key);
          combined.add(item);
        }
      }
    }

    // Alaka düzeyine göre sırala:
    // 1. Sembol tam eşleşme
    // 2. Sembol ile başlayanlar
    // 3. İsim başlangıç eşleşmesi
    // 4. İçerenler
    combined.sort((a, b) {
      final aSym = _cleanText(a.symbol);
      final bSym = _cleanText(b.symbol);
      final aName = _cleanText(a.name);
      final bName = _cleanText(b.name);

      final aExact = aSym == cleanQ;
      final bExact = bSym == cleanQ;
      if (aExact != bExact) return aExact ? -1 : 1;

      final aSymStarts = aSym.startsWith(cleanQ);
      final bSymStarts = bSym.startsWith(cleanQ);
      if (aSymStarts != bSymStarts) return aSymStarts ? -1 : 1;

      final aNameStarts = aName.startsWith(cleanQ);
      final bNameStarts = bName.startsWith(cleanQ);
      if (aNameStarts != bNameStarts) return aNameStarts ? -1 : 1;

      return 0;
    });

    return combined.take(35).toList();
  }

  /// Tahvil (bond), Eurobond, ISIN kodları ve tezgahüstü borçlanma araçlarını filtreler
  static bool _isInvalidStockOrDebtInstrument(
    String sym,
    String? type,
    String desc,
    String? ex,
  ) {
    if (sym.isEmpty) return true;

    // 1. Tür kontrolü: Yalnızca hisse (stock) ve borsa yatırım fonu (fund/etf) kabul edilir.
    // Tahviller (bond), Eurobondlar, vadeli işlemler (futures), CFD, varant (warrant),
    // yapılandırılmış borçlanma ürünleri (structured) ve endeksler kesinlikle elenir.
    final t = type?.toLowerCase();
    if (t != null && t != 'stock' && t != 'fund' && t != 'etf') {
      return true;
    }

    // 2. ISIN / Borçlanma kodu Regex filtresi:
    // Örn: ES34330702, XS2384355520, US0378331005 veya 6+ haneli karmaşık tahvil kodları
    if (RegExp(r'^[A-Z]{2}\d{6,}').hasMatch(sym) ||
        RegExp(r'^[A-Z]{2}[0-9A-Z]{10}$').hasMatch(sym) ||
        RegExp(r'^\d{5,}$').hasMatch(sym)) {
      return true;
    }

    // 3. Açıklama metni filtresi (Tahvil, bono, faiz kuponu içeren enstrümanlar)
    final d = desc.toLowerCase();
    if (d.contains('bond') ||
        d.contains('regs') ||
        d.contains('144a') ||
        d.contains('treasury') ||
        d.contains('tahvil') ||
        d.contains('bono') ||
        d.contains('obligation') ||
        RegExp(r'\d+\.?\d*%\s+\d{2}-[a-z]{3}-\d{2,4}').hasMatch(d)) {
      return true;
    }

    // 4. Borsa (Exchange) filtresi:
    // Yalnızca SPK / regüle resmi ana borsaları kabul et; tezgahüstü borçlanma platformlarını ele
    if (ex != null && ex.isNotEmpty) {
      const allowedExchanges = {
        'BIST',
        'NASDAQ',
        'NYSE',
        'AMEX',
        'EURONEXT',
        'LSE',
        'XETRA',
        'FWB',
        'TSX',
        'SIX',
      };
      if (!allowedExchanges.contains(ex.toUpperCase())) {
        return true;
      }
    }

    return false;
  }

  // Fon arama (TEFAS Resmi JSON API'sinden Canlı ve Dinamik Arama)
  static Future<List<AssetSuggestion>> _searchFunds(String q) async {
    final cleanQ = q.trim();
    if (cleanQ.isEmpty) return const [];

    final tefasResults = await TefasService.searchFunds(cleanQ);

    return tefasResults.map((f) {
      final logo = MarketDataService.resolveFundLogo(f.code, f.name);
      return AssetSuggestion(
        symbol: f.code,
        name: f.name,
        category: AssetCategory.fon,
        iconUrl: logo,
        subtitle: resolveFundSubtitle(f.name),
      );
    }).take(25).toList();
  }

  // Hisse arama (Yerel BIST/Global + TradingView Canlı Arama)
  static Future<List<AssetSuggestion>> _searchStocks(String q) async {
    final results = <AssetSuggestion>[];
    final seen = <String>{};

    // 1. Yerel listeden filtrele
    for (final item in _knownStocks) {
      final sym = item['symbol']!;
      final name = item['name']!;
      final sub = item['sub']!;
      final isByf = item['isByf'] == 'true';

      if (q.isEmpty ||
          _cleanText(sym).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        seen.add(sym.toUpperCase());
        final itemCat = isByf ? AssetCategory.fon : AssetCategory.hisse;
        final logo = MarketDataService.getKnownAssetLogo(sym, itemCat, name);
        results.add(AssetSuggestion(
          symbol: sym,
          name: name,
          category: itemCat,
          iconUrl: logo,
          subtitle: sub,
          isByf: isByf,
        ));
      }
    }

    // 2. Canlı TradingView BIST ve Global Arama
    if (q.isNotEmpty && q.length >= 2) {
      try {
        final url =
            'https://symbol-search.tradingview.com/symbol_search/v3/?text=${Uri.encodeComponent(q)}&exchange=BIST';
        final resp = await AppHttpClient.get(url, timeout: const Duration(seconds: 5));
        if (resp != null && resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['symbols'] as List<dynamic>? ?? [];

          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
              final type = item['type'] as String?;
              final desc = (item['description'] as String?) ?? sym;
              final ex = item['exchange'] as String? ?? 'BIST';

              if (_isInvalidStockOrDebtInstrument(sym, type, desc, ex)) {
                continue;
              }
              if (seen.contains(sym)) continue;
              seen.add(sym);

              final curated = findCurated(sym, AssetCategory.hisse);
              if (curated != null) {
                results.add(curated);
                continue;
              }

              final logoid = item['logoid'] as String?;

              AssetCategory itemCat = AssetCategory.hisse;
              String sub = '$ex • Hisse';
              bool isByf = false;
              final tLower = type?.toLowerCase();
              if (tLower == 'fund' || tLower == 'etf') {
                itemCat = AssetCategory.fon;
                sub = '$ex • BYF/ETF';
                isByf = true;
              }

              final logoUrl = (logoid != null && logoid.isNotEmpty)
                  ? 'https://s3-symbol-logo.tradingview.com/$logoid.svg'
                  : MarketDataService.getKnownAssetLogo(sym, itemCat, desc);

              results.add(AssetSuggestion(
                symbol: sym,
                name: desc,
                category: itemCat,
                iconUrl: logoUrl,
                subtitle: sub,
                isByf: isByf,
              ));
            }
          }
        }
      } catch (_) {}

      // Global hisseler için TradingView genel arama
      if (results.length < 5) {
        try {
          final url =
              'https://symbol-search.tradingview.com/symbol_search/v3/?text=${Uri.encodeComponent(q)}';
          final resp = await AppHttpClient.get(url, timeout: const Duration(seconds: 5));
          if (resp != null && resp.statusCode == 200) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final list = data['symbols'] as List<dynamic>? ?? [];

            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
                final type = item['type'] as String?;
                final desc = (item['description'] as String?) ?? sym;
                final ex = item['exchange'] as String? ?? 'Yabancı';

                if (_isInvalidStockOrDebtInstrument(sym, type, desc, ex)) {
                  continue;
                }
                if (seen.contains(sym)) continue;
                seen.add(sym);

                final curated = findCurated(sym, AssetCategory.hisse);
                if (curated != null) {
                  results.add(curated);
                  continue;
                }

                final logoid = item['logoid'] as String?;

                AssetCategory itemCat = AssetCategory.hisse;
                String sub = '$ex • Hisse';
                bool isByf = false;
                final tLower = type?.toLowerCase();
                if (tLower == 'fund' || tLower == 'etf') {
                  itemCat = AssetCategory.fon;
                  sub = '$ex • BYF/ETF';
                  isByf = true;
                }

                final logoUrl = (logoid != null && logoid.isNotEmpty)
                    ? 'https://s3-symbol-logo.tradingview.com/$logoid.svg'
                    : MarketDataService.getKnownAssetLogo(sym, itemCat, desc);

                results.add(AssetSuggestion(
                  symbol: sym,
                  name: desc,
                  category: itemCat,
                  iconUrl: logoUrl,
                  subtitle: sub,
                  isByf: isByf,
                ));
              }
            }
          }
        } catch (_) {}
      }
    }

    return results.take(15).toList();
  }

  // Kripto Para arama
  static Future<List<AssetSuggestion>> _searchCryptos(String q) async {
    final results = <AssetSuggestion>[];
    final seen = <String>{};

    for (final item in _knownCryptos) {
      final sym = item['symbol']!;
      final name = item['name']!;
      final sub = item['sub']!;

      if (q.isEmpty ||
          _cleanText(sym).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        seen.add(sym.toUpperCase());
        final logo = MarketDataService.getKnownAssetLogo(sym, AssetCategory.kripto, name);
        results.add(AssetSuggestion(
          symbol: sym,
          name: name,
          category: AssetCategory.kripto,
          iconUrl: logo,
          subtitle: sub,
        ));
      }
    }

    // TradingView kripto araması
    if (q.isNotEmpty && q.length >= 2 && results.length < 8) {
      try {
        final url =
            'https://symbol-search.tradingview.com/symbol_search/v3/?text=${Uri.encodeComponent(q)}&search_type=crypto';
        final resp = await AppHttpClient.get(url, timeout: const Duration(seconds: 4));
        if (resp != null && resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['symbols'] as List<dynamic>? ?? [];

          for (final item in list) {
            if (item is Map<String, dynamic>) {
              String sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
              sym = sym
                  .replaceAll('USD', '')
                  .replaceAll('USDT', '')
                  .replaceAll('TRY', '');
              if (sym.contains('.')) sym = sym.split('.').first;
              final desc = (item['description'] as String?) ?? sym;
              final logoid = item['logoid'] as String?;

              if (sym.isNotEmpty && !seen.contains(sym)) {
                seen.add(sym);
                final logoUrl = (logoid != null && logoid.isNotEmpty)
                    ? 'https://s3-symbol-logo.tradingview.com/$logoid.svg'
                    : MarketDataService.getKnownAssetLogo(sym, AssetCategory.kripto, desc);

                results.add(AssetSuggestion(
                  symbol: sym,
                  name: desc,
                  category: AssetCategory.kripto,
                  iconUrl: logoUrl,
                  subtitle: 'Kripto Para',
                ));
              }
            }
          }
        }
      } catch (_) {}
    }

    return results.take(15).toList();
  }

  // Emtia arama
  static Future<List<AssetSuggestion>> _searchCommodities(String q) async {
    final results = <AssetSuggestion>[];

    for (final item in _knownCommodities) {
      final sym = item['symbol']!;
      final name = item['name']!;
      final sub = item['sub']!;

      if (q.isEmpty ||
          _cleanText(sym).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        final logo = MarketDataService.getKnownAssetLogo(sym, AssetCategory.emtia, name);
        results.add(AssetSuggestion(
          symbol: sym,
          name: name,
          category: AssetCategory.emtia,
          iconUrl: logo,
          subtitle: sub,
        ));
      }
    }

    return results;
  }

  // Döviz arama
  static Future<List<AssetSuggestion>> _searchCurrencies(String q) async {
    final results = <AssetSuggestion>[];

    for (final item in _knownCurrencies) {
      final sym = item['symbol']!;
      final name = item['name']!;
      final sub = item['sub']!;

      if (q.isEmpty ||
          _cleanText(sym).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        final logo = MarketDataService.getKnownAssetLogo(sym, AssetCategory.doviz, name);
        results.add(AssetSuggestion(
          symbol: sym,
          name: name,
          category: AssetCategory.doviz,
          iconUrl: logo,
          subtitle: sub,
        ));
      }
    }

    return results;
  }
}
