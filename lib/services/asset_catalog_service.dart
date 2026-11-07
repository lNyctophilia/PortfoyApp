import 'dart:convert';
import '../core/network/app_http_client.dart';
import '../models/asset_category.dart';
import 'market_data_service.dart';

class AssetSuggestion {
  final String symbol;
  final String name;
  final AssetCategory category;
  final String? iconUrl;
  final String? subtitle;

  const AssetSuggestion({
    required this.symbol,
    required this.name,
    required this.category,
    this.iconUrl,
    this.subtitle,
  });
}

class AssetCatalogService {

  // -------------------------------------------------------------
  // 1. POPÜLER TEFAS FONLARI KATALOĞU (100+ Fon)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownFunds = [
    // İş Portföy
    {'code': 'TI2', 'name': 'İş Portföy Hisse Senedi (TL) Fonu (Hisse Senedi Yoğun Fon)', 'sub': 'İş Portföy • Hisse Yoğun'},
    {'code': 'TI3', 'name': 'İş Portföy BIST 30 Endeksi Hisse Senedi (TL) Fonu', 'sub': 'İş Portföy • BIST 30'},
    {'code': 'TTE', 'name': 'İş Portföy BIST Teknoloji Ağırlıklı Sınırlamalı Hisse Senedi Fonu', 'sub': 'İş Portföy • Teknoloji'},
    {'code': 'TLE', 'name': 'İş Portföy Altın Fonu', 'sub': 'İş Portföy • Kıymetli Maden'},
    {'code': 'TAU', 'name': 'İş Portföy BIST Banka Endeksi Hisse Senedi Fonu', 'sub': 'İş Portföy • Bankacılık'},
    {'code': 'TMG', 'name': 'İş Portföy Yabancı Hisse Senedi Fonu', 'sub': 'İş Portföy • Yabancı Hisse'},
    {'code': 'TET', 'name': 'İş Portföy Elektrikli Araçlar Karma Fon', 'sub': 'İş Portföy • Tematik'},
    {'code': 'TLP', 'name': 'İş Portföy Para Piyasası (TL) Fonu', 'sub': 'İş Portföy • Para Piyasası'},
    {'code': 'IST', 'name': 'İş Portföy İhracatçı Şirketler Hisse Senedi Fonu', 'sub': 'İş Portföy • İhracat'},
    {'code': 'IHK', 'name': 'İş Portföy İş\'te Kadın Hisse Senedi Fonu', 'sub': 'İş Portföy • Hisse Yoğun'},
    {'code': 'IEY', 'name': 'İş Portföy Eurobond (Amerikan Doları) Borçlanma Araçları Fonu', 'sub': 'İş Portföy • Eurobond'},

    // Ak Portföy
    {'code': 'AFT', 'name': 'Ak Portföy Yeni Teknolojiler Yabancı Hisse Senedi Fonu', 'sub': 'Ak Portföy • Yabancı Teknoloji'},
    {'code': 'AFA', 'name': 'Ak Portföy Amerika Yabancı Hisse Senedi Fonu', 'sub': 'Ak Portföy • ABD Piyasaları'},
    {'code': 'AFS', 'name': 'Ak Portföy Sağlık Sektörü Yabancı Hisse Senedi Fonu', 'sub': 'Ak Portföy • Sağlık'},
    {'code': 'AES', 'name': 'Ak Portföy Petrol Yabancı BYF Fon Sepeti Fonu', 'sub': 'Ak Portföy • Emtia Petrol'},
    {'code': 'AGH', 'name': 'Ak Portföy BIST 100 Dışı Şirketler Hisse Senedi Fonu', 'sub': 'Ak Portföy • Yan Tahtalar'},
    {'code': 'AK2', 'name': 'Ak Portföy Hisse Senedi Fonu (Hisse Senedi Yoğun Fon)', 'sub': 'Ak Portföy • Hisse Yoğun'},
    {'code': 'AK3', 'name': 'Ak Portföy BIST 30 Endeksi Hisse Senedi Fonu', 'sub': 'Ak Portföy • BIST 30'},
    {'code': 'ALE', 'name': 'Ak Portföy Altın Fonu', 'sub': 'Ak Portföy • Altın'},
    {'code': 'ALR', 'name': 'Ak Portföy Serbest Fon', 'sub': 'Ak Portföy • Serbest'},
    {'code': 'APB', 'name': 'Ak Portföy Para Piyasası Fonu', 'sub': 'Ak Portföy • Para Piyasası'},

    // Yapı Kredi Portföy
    {'code': 'YAS', 'name': 'Yapı Kredi Portföy Koç Holding İştirakleri Hisse Senedi Fonu', 'sub': 'Yapı Kredi • Koç İştirakleri'},
    {'code': 'YAC', 'name': 'Yapı Kredi Portföy İkinci Değişken Fon', 'sub': 'Yapı Kredi • Değişken'},
    {'code': 'YTD', 'name': 'Yapı Kredi Portföy BIST Teknoloji Ağırlıklı Sınırlamalı Fon', 'sub': 'Yapı Kredi • Teknoloji'},
    {'code': 'YPG', 'name': 'Yapı Kredi Portföy Altın Fonu', 'sub': 'Yapı Kredi • Altın'},
    {'code': 'YHK', 'name': 'Yapı Kredi Portföy Hisse Senedi Fonu', 'sub': 'Yapı Kredi • Hisse Yoğun'},
    {'code': 'YAY', 'name': 'Yapı Kredi Portföy Yabancı Teknoloji Sektörü Hisse Senedi Fonu', 'sub': 'Yapı Kredi • Yabancı Teknoloji'},
    {'code': 'YAZ', 'name': 'Yapı Kredi Portföy Eurobond Borçlanma Araçları Fonu', 'sub': 'Yapı Kredi • Eurobond'},
    {'code': 'YBE', 'name': 'Yapı Kredi Portföy Eurobond Dolar Borçlanma Araçları Fonu', 'sub': 'Yapı Kredi • Eurobond'},

    // Garanti Portföy
    {'code': 'GMR', 'name': 'Garanti Portföy İkinci Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'Garanti • Hisse Yoğun'},
    {'code': 'GTA', 'name': 'Garanti Portföy Altın Fonu', 'sub': 'Garanti • Altın'},
    {'code': 'GBV', 'name': 'Garanti Portföy BIST 100 Dışı Şirketler Hisse Senedi Fonu', 'sub': 'Garanti • BIST Dışı'},
    {'code': 'GL1', 'name': 'Garanti Portföy Hisse Senedi Fonu', 'sub': 'Garanti • Hisse Yoğun'},
    {'code': 'GTL', 'name': 'Garanti Portföy Para Piyasası Fonu', 'sub': 'Garanti • Para Piyasası'},
    {'code': 'GMA', 'name': 'Garanti Portföy Birinci Değişken Fon', 'sub': 'Garanti • Değişken'},
    {'code': 'GPY', 'name': 'Garanti Portföy İhracatçı Şirketler Hisse Senedi Fonu', 'sub': 'Garanti • İhracat'},

    // Ziraat Portföy
    {'code': 'ZPE', 'name': 'Ziraat Portföy Katılım Endeksi Hisse Senedi Fonu', 'sub': 'Ziraat • Katılım Hisse'},
    {'code': 'ZPF', 'name': 'Ziraat Portföy Altın Katılım Fonu', 'sub': 'Ziraat • Altın Katılım'},
    {'code': 'ZRE', 'name': 'Ziraat Portföy BIST 30 Endeksi Hisse Senedi Fonu', 'sub': 'Ziraat • BIST 30'},
    {'code': 'ZKP', 'name': 'Ziraat Portföy Kısa Vadeli Kira Sertifikaları Fonu', 'sub': 'Ziraat • Kira Sertifikası'},
    {'code': 'ZEL', 'name': 'Ziraat Portföy Para Piyasası Fonu', 'sub': 'Ziraat • Para Piyasası'},
    {'code': 'ZAS', 'name': 'Ziraat Portföy BIST Banka Dışı Likit 10 Fonu', 'sub': 'Ziraat • Likit 10'},

    // Tacirler Portföy
    {'code': 'TCD', 'name': 'Tacirler Portföy Değişken Fon', 'sub': 'Tacirler • Değişken'},
    {'code': 'TKF', 'name': 'Tacirler Portföy Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'Tacirler • Hisse Yoğun'},

    // İstanbul Portföy
    {'code': 'IIH', 'name': 'İstanbul Portföy Üçüncü Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'İstanbul Portföy • Hisse Yoğun'},
    {'code': 'IRF', 'name': 'İstanbul Portföy Serbest Fon', 'sub': 'İstanbul Portföy • Serbest'},
    {'code': 'IJT', 'name': 'İstanbul Portföy Yabancı Teknoloji Hisse Senedi Fonu', 'sub': 'İstanbul Portföy • Teknoloji'},

    // Marmara Capital
    {'code': 'MAC', 'name': 'Marmara Capital Portföy Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'Marmara Capital • Hisse Yoğun'},

    // Hedef Portföy
    {'code': 'NNF', 'name': 'Hedef Portföy Birinci Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'Hedef Portföy • Hisse Yoğun'},
    {'code': 'HHK', 'name': 'Hedef Portföy Katılım Hisse Senedi Fonu', 'sub': 'Hedef Portföy • Katılım'},

    // QNB Finans Portföy
    {'code': 'FNC', 'name': 'QNB Finansinvest BIST 30 Endeksi Hisse Senedi Fonu', 'sub': 'QNB Finans • BIST 30'},
    {'code': 'FBK', 'name': 'QNB Portföy İkinci Değişken Fon', 'sub': 'QNB Finans • Değişken'},

    // Vakıf Portföy
    {'code': 'VK6', 'name': 'Vakıf Portföy Katılım Fonu', 'sub': 'Vakıf Portföy • Katılım'},
    {'code': 'VAK', 'name': 'Vakıf Portföy Hisse Senedi Fonu', 'sub': 'Vakıf Portföy • Hisse Yoğun'},
    {'code': 'VPU', 'name': 'Vakıf Portföy Para Piyasası Fonu', 'sub': 'Vakıf Portföy • Para Piyasası'},

    // TEB Portföy
    {'code': 'TKP', 'name': 'TEB Portföy Hisse Senedi Fonu (Hisse Senedi Yoğun)', 'sub': 'TEB Portföy • Hisse Yoğun'},
    {'code': 'TEP', 'name': 'TEB Portföy Birinci Para Piyasası Fonu', 'sub': 'TEB Portföy • Para Piyasası'},

    // Oyak Portföy
    {'code': 'OYP', 'name': 'Oyak Portföy Birinci Hisse Senedi Fonu', 'sub': 'Oyak Portföy • Hisse Yoğun'},
    {'code': 'OKP', 'name': 'Oyak Portföy Katılım Hisse Senedi Fonu', 'sub': 'Oyak Portföy • Katılım'},

    // Gedik Portföy
    {'code': 'GDK', 'name': 'Gedik Portföy İkinci Hisse Senedi Fonu', 'sub': 'Gedik Portföy • Hisse Yoğun'},
    {'code': 'GKP', 'name': 'Gedik Portföy Karma Fon', 'sub': 'Gedik Portföy • Karma'},

    // BV Portföy
    {'code': 'BIO', 'name': 'BV Portföy İnovasyon ve Teknoloji Değişken Fon', 'sub': 'BV Portföy • İnovasyon Teknoloji'},
  ];

  // -------------------------------------------------------------
  // 2. POPÜLER BIST & GLOBAL HİSSELERİ (Yerel Hızlı Arama)
  // -------------------------------------------------------------
  static const List<Map<String, String>> _knownStocks = [
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
      _searchStocks(cleanQ),
      _searchFunds(cleanQ),
      _searchCryptos(cleanQ),
      _searchCommodities(cleanQ),
      _searchCurrencies(cleanQ),
    ]);

    final combined = <AssetSuggestion>[];
    for (final list in searchFutures) {
      combined.addAll(list);
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

  // Fon arama
  static Future<List<AssetSuggestion>> _searchFunds(String q) async {
    final results = <AssetSuggestion>[];

    for (final item in _knownFunds) {
      final code = item['code']!;
      final name = item['name']!;
      final sub = item['sub']!;

      if (q.isEmpty ||
          _cleanText(code).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        final logo = MarketDataService.resolveFundLogo(code, name);
        results.add(AssetSuggestion(
          symbol: code,
          name: name,
          category: AssetCategory.fon,
          iconUrl: logo,
          subtitle: sub,
        ));
      }
    }

    // Kullanıcı 3 harfli yeni bir fon kodu yazdıysa ve listede yoksa TEFAS'tan kontrol et
    final cleanUpper = q.toUpperCase();
    if (cleanUpper.length == 3 &&
        !results.any((r) => r.symbol.toUpperCase() == cleanUpper)) {
      try {
        final payload = jsonEncode({
          'fonKodu': cleanUpper,
          'dil': 'TR',
          'periyod': 5,
        });
        final resp = await AppHttpClient.post(
          'https://www.tefas.gov.tr/api/funds/fonFiyatBilgiGetir',
          headers: {'Content-Type': 'application/json'},
          body: payload,
          timeout: const Duration(seconds: 4),
        );
        if (resp != null && resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['resultList'] as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            final latest = list.last as Map<String, dynamic>;
            final title = latest['fonUnvan'] as String? ?? cleanUpper;
            final logo = MarketDataService.resolveFundLogo(cleanUpper, title);
            results.insert(
              0,
              AssetSuggestion(
                symbol: cleanUpper,
                name: title,
                category: AssetCategory.fon,
                iconUrl: logo,
                subtitle: 'TEFAS • Yatırım Fonu',
              ),
            );
          }
        }
      } catch (_) {}
    }

    return results.take(15).toList();
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

      if (q.isEmpty ||
          _cleanText(sym).contains(q) ||
          _cleanText(name).contains(q) ||
          _cleanText(sub).contains(q)) {
        seen.add(sym.toUpperCase());
        final logo = MarketDataService.getKnownAssetLogo(sym, AssetCategory.hisse, name);
        results.add(AssetSuggestion(
          symbol: sym,
          name: name,
          category: AssetCategory.hisse,
          iconUrl: logo,
          subtitle: sub,
        ));
      }
    }

    // 2. Canlı TradingView BIST ve Global Arama
    if (q.isNotEmpty && q.length >= 2) {
      try {
        final url =
            'https://symbol-search.tradingview.com/symbol_search/v3/?text=${Uri.encodeComponent(q)}&exchange=BIST';
        final resp = await AppHttpClient.get(url, timeout: const Duration(seconds: 4));
        if (resp != null && resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['symbols'] as List<dynamic>? ?? [];

          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final type = (item['type'] as String?)?.toLowerCase();
              if (type == 'stock' || type == 'fund' || type == 'dr') {
                final sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
                final desc = (item['description'] as String?) ?? sym;
                final logoid = item['logoid'] as String?;
                if (sym.isNotEmpty && !seen.contains(sym)) {
                  seen.add(sym);
                  final logoUrl = (logoid != null && logoid.isNotEmpty)
                      ? 'https://s3-symbol-logo.tradingview.com/$logoid.svg'
                      : MarketDataService.getKnownAssetLogo(sym, AssetCategory.hisse, desc);

                  results.add(AssetSuggestion(
                    symbol: sym,
                    name: desc,
                    category: AssetCategory.hisse,
                    iconUrl: logoUrl,
                    subtitle: 'BIST • ${item['exchange'] ?? 'Hisse'}',
                  ));
                }
              }
            }
          }
        }
      } catch (_) {}

      // Global hisseler için TradingView genel arama
      if (results.length < 5) {
        try {
          final url =
              'https://symbol-search.tradingview.com/symbol_search/v3/?text=${Uri.encodeComponent(q)}';
          final resp = await AppHttpClient.get(url, timeout: const Duration(seconds: 4));
          if (resp != null && resp.statusCode == 200) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final list = data['symbols'] as List<dynamic>? ?? [];

            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final type = (item['type'] as String?)?.toLowerCase();
                if (type == 'stock') {
                  final sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
                  final desc = (item['description'] as String?) ?? sym;
                  final ex = item['exchange'] as String? ?? 'Yabancı';
                  final logoid = item['logoid'] as String?;
                  if (sym.isNotEmpty && !seen.contains(sym)) {
                    seen.add(sym);
                    final logoUrl = (logoid != null && logoid.isNotEmpty)
                        ? 'https://s3-symbol-logo.tradingview.com/$logoid.svg'
                        : MarketDataService.getKnownAssetLogo(sym, AssetCategory.hisse, desc);

                    results.add(AssetSuggestion(
                      symbol: sym,
                      name: desc,
                      category: AssetCategory.hisse,
                      iconUrl: logoUrl,
                      subtitle: '$ex • Hisse',
                    ));
                  }
                }
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
