import 'dart:convert';
import 'dart:io';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';

class StorageService {
  static const String _fileName = 'portfolios_data.json';

  static const String _logoCacheFileName = 'logo_cache.json';

  Future<File> _getFile() async {
    Directory targetDir;
    try {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        targetDir = Directory('$appData\\PortfoyApp');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else {
        targetDir = Directory.current;
      }
    } catch (_) {
      targetDir = Directory.current;
    }
    return File('${targetDir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<File> _getLogoCacheFile() async {
    Directory targetDir;
    try {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        targetDir = Directory('$appData\\PortfoyApp');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else {
        targetDir = Directory.current;
      }
    } catch (_) {
      targetDir = Directory.current;
    }
    return File('${targetDir.path}${Platform.pathSeparator}$_logoCacheFileName');
  }

  Future<Map<String, String>> loadLogoCache() async {
    try {
      final file = await _getLogoCacheFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final Map<String, dynamic> raw = jsonDecode(content) as Map<String, dynamic>;
          return raw.map((k, v) => MapEntry(k, v.toString()));
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveLogoCache(Map<String, String> cache) async {
    try {
      final file = await _getLogoCacheFile();
      final content = const JsonEncoder.withIndent('  ').convert(cache);
      await file.writeAsString(content);
    } catch (_) {}
  }

  Future<List<Portfolio>> loadPortfolios() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
          return jsonList
              .map((item) => Portfolio.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // Fallback on error
    }
    return _getInitialSamplePortfolios();
  }

  Future<void> savePortfolios(List<Portfolio> portfolios) async {
    try {
      final file = await _getFile();
      final jsonList = portfolios.map((p) => p.toJson()).toList();
      final content = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(content);
    } catch (e) {
      // Ignore write errors or log
    }
  }

  List<Portfolio> _getInitialSamplePortfolios() {
    final now = DateTime.now();

    return [
      Portfolio(
        id: 'port-1',
        name: 'Teknoloji & Büyüme Portföyü',
        description: 'Teknoloji ağırlıklı fonlar ve BIST teknoloji hisseleri',
        createdAt: now.subtract(const Duration(days: 180)),
        assets: [
          PortfolioAsset(
            id: 'asset-101',
            name: 'İş Portföy BIST Teknoloji Ağırlıklı Fon',
            symbol: 'TTE',
            category: AssetCategory.fon,
            purchaseDate: now.subtract(const Duration(days: 120)),
            purchasePrice: 1.45,
            quantity: 35000,
            currentPrice: 2.18,
            dailyChangePercent: 1.42,
            weeklyChangePercent: 3.85,
            monthlyChangePercent: 8.90,
            threeMonthlyChangePercent: 24.50,
            sixMonthlyChangePercent: 46.80,
            yearlyChangePercent: 78.40,
          ),
          PortfolioAsset(
            id: 'asset-102',
            name: 'Ak Portföy Yeni Teknolojiler Yabancı BYF Fonu',
            symbol: 'AFT',
            category: AssetCategory.fon,
            purchaseDate: now.subtract(const Duration(days: 90)),
            purchasePrice: 0.32,
            quantity: 80000,
            currentPrice: 0.44,
            dailyChangePercent: 0.85,
            weeklyChangePercent: 2.10,
            monthlyChangePercent: 6.30,
            threeMonthlyChangePercent: 18.20,
            sixMonthlyChangePercent: 38.40,
            yearlyChangePercent: 62.50,
          ),
          PortfolioAsset(
            id: 'asset-103',
            name: 'Aselsan Elektronik Sanayi',
            symbol: 'ASELS',
            category: AssetCategory.hisse,
            purchaseDate: now.subtract(const Duration(days: 60)),
            purchasePrice: 58.50,
            quantity: 450,
            currentPrice: 72.80,
            dailyChangePercent: 2.15,
            weeklyChangePercent: 4.60,
            monthlyChangePercent: 12.40,
            threeMonthlyChangePercent: 32.10,
            sixMonthlyChangePercent: 64.50,
            yearlyChangePercent: 94.20,
          ),
          PortfolioAsset(
            id: 'asset-104',
            name: 'Amerikan Doları',
            symbol: 'USD/TRY',
            category: AssetCategory.doviz,
            purchaseDate: now.subtract(const Duration(days: 150)),
            purchasePrice: 32.20,
            quantity: 600,
            currentPrice: 36.40,
            dailyChangePercent: 0.12,
            weeklyChangePercent: 0.45,
            monthlyChangePercent: 1.80,
            threeMonthlyChangePercent: 6.20,
            sixMonthlyChangePercent: 14.80,
            yearlyChangePercent: 34.10,
          ),
          PortfolioAsset(
            id: 'asset-105',
            name: 'Gram Altın',
            symbol: 'ALTIN.GR',
            category: AssetCategory.emtia,
            purchaseDate: now.subtract(const Duration(days: 100)),
            purchasePrice: 2450.0,
            quantity: 8,
            currentPrice: 3120.0,
            dailyChangePercent: -0.35,
            weeklyChangePercent: 1.95,
            monthlyChangePercent: 5.40,
            threeMonthlyChangePercent: 16.80,
            sixMonthlyChangePercent: 32.40,
            yearlyChangePercent: 54.30,
          ),
        ],
      ),
      Portfolio(
        id: 'port-2',
        name: 'Dengeli Temettü & Değer',
        description: 'Güçlü temettü ödeyen şirketler ve altın koruması',
        createdAt: now.subtract(const Duration(days: 240)),
        assets: [
          PortfolioAsset(
            id: 'asset-201',
            name: 'Türk Hava Yolları',
            symbol: 'THYAO',
            category: AssetCategory.hisse,
            purchaseDate: now.subtract(const Duration(days: 200)),
            purchasePrice: 260.0,
            quantity: 150,
            currentPrice: 325.0,
            dailyChangePercent: -0.75,
            weeklyChangePercent: 2.80,
            monthlyChangePercent: 7.10,
            threeMonthlyChangePercent: 14.20,
            sixMonthlyChangePercent: 26.50,
            yearlyChangePercent: 42.00,
          ),
          PortfolioAsset(
            id: 'asset-202',
            name: 'Tüpraş Türkiye Petrol Rafinerileri',
            symbol: 'TUPRS',
            category: AssetCategory.hisse,
            purchaseDate: now.subtract(const Duration(days: 180)),
            purchasePrice: 142.0,
            quantity: 200,
            currentPrice: 178.50,
            dailyChangePercent: 1.10,
            weeklyChangePercent: 3.20,
            monthlyChangePercent: 9.40,
            threeMonthlyChangePercent: 21.60,
            sixMonthlyChangePercent: 39.80,
            yearlyChangePercent: 56.80,
          ),
          PortfolioAsset(
            id: 'asset-203',
            name: 'Marmara Capital Hisse Senedi Fonu',
            symbol: 'MAC',
            category: AssetCategory.fon,
            purchaseDate: now.subtract(const Duration(days: 130)),
            purchasePrice: 0.115,
            quantity: 180000,
            currentPrice: 0.148,
            dailyChangePercent: 0.60,
            weeklyChangePercent: 1.80,
            monthlyChangePercent: 4.90,
            threeMonthlyChangePercent: 17.50,
            sixMonthlyChangePercent: 35.20,
            yearlyChangePercent: 68.20,
          ),
          PortfolioAsset(
            id: 'asset-204',
            name: 'Gram Gümüş',
            symbol: 'GUMUS.GR',
            category: AssetCategory.emtia,
            purchaseDate: now.subtract(const Duration(days: 90)),
            purchasePrice: 31.0,
            quantity: 300,
            currentPrice: 38.60,
            dailyChangePercent: 1.40,
            weeklyChangePercent: 4.10,
            monthlyChangePercent: 11.20,
            threeMonthlyChangePercent: 22.80,
            sixMonthlyChangePercent: 36.40,
            yearlyChangePercent: 48.00,
          ),
        ],
      ),
      Portfolio(
        id: 'port-3',
        name: 'Döviz & Kıymetli Madenler Sepeti',
        description: 'Kur ve enflasyona karşı koruma portföyü',
        createdAt: now.subtract(const Duration(days: 300)),
        assets: [
          PortfolioAsset(
            id: 'asset-301',
            name: 'Euro',
            symbol: 'EUR/TRY',
            category: AssetCategory.doviz,
            purchaseDate: now.subtract(const Duration(days: 250)),
            purchasePrice: 34.50,
            quantity: 1200,
            currentPrice: 39.80,
            dailyChangePercent: 0.25,
            weeklyChangePercent: 0.70,
            monthlyChangePercent: 2.10,
            threeMonthlyChangePercent: 7.40,
            sixMonthlyChangePercent: 15.60,
            yearlyChangePercent: 28.50,
          ),
          PortfolioAsset(
            id: 'asset-302',
            name: 'Kuveyt Türk Altın Katılım Fonu',
            symbol: 'KZL',
            category: AssetCategory.fon,
            purchaseDate: now.subtract(const Duration(days: 200)),
            purchasePrice: 4.80,
            quantity: 6000,
            currentPrice: 6.95,
            dailyChangePercent: -0.15,
            weeklyChangePercent: 1.85,
            monthlyChangePercent: 5.60,
            threeMonthlyChangePercent: 19.30,
            sixMonthlyChangePercent: 37.10,
            yearlyChangePercent: 58.10,
          ),
          PortfolioAsset(
            id: 'asset-303',
            name: 'Gram Altın',
            symbol: 'ALTIN.GR',
            category: AssetCategory.emtia,
            purchaseDate: now.subtract(const Duration(days: 280)),
            purchasePrice: 2200.0,
            quantity: 15,
            currentPrice: 3120.0,
            dailyChangePercent: -0.35,
            weeklyChangePercent: 1.95,
            monthlyChangePercent: 5.40,
            threeMonthlyChangePercent: 16.80,
            sixMonthlyChangePercent: 32.40,
            yearlyChangePercent: 54.30,
          ),
        ],
      ),
    ];
  }
}
