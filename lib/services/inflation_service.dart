import 'dart:convert';
import 'dart:math' as math;
import '../core/network/app_http_client.dart';
import 'storage_service.dart';

class InflationInfo {
  final double inflationRate; // % Değişim (örnek: 32.5 -> %32.5)
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;
  final double? startTufe;
  final double? endTufe;
  final bool isFromApi;

  InflationInfo({
    required this.inflationRate,
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
    this.startTufe,
    this.endTufe,
    this.isFromApi = true,
  });

  Map<String, dynamic> toJson() => {
        'inflationRate': inflationRate,
        'startYear': startYear,
        'startMonth': startMonth,
        'endYear': endYear,
        'endMonth': endMonth,
        'startTufe': startTufe,
        'endTufe': endTufe,
        'isFromApi': isFromApi,
      };

  factory InflationInfo.fromJson(Map<String, dynamic> json) => InflationInfo(
        inflationRate: (json['inflationRate'] as num).toDouble(),
        startYear: json['startYear'] as int,
        startMonth: json['startMonth'] as int,
        endYear: json['endYear'] as int,
        endMonth: json['endMonth'] as int,
        startTufe: (json['startTufe'] as num?)?.toDouble(),
        endTufe: (json['endTufe'] as num?)?.toDouble(),
        isFromApi: json['isFromApi'] as bool? ?? false,
      );
}

/// Dönemsel resmi TÜFE enflasyon verileri (Günlük, Haftalık, 1A, 3A, 6A, 1Y)
class PeriodInflationData {
  final double daily; // 1G (pro-rata bileşik günlük)
  final double weekly; // 1H (pro-rata bileşik haftalık)
  final double monthly; // 1A (son 1 aylık resmi TÜFE)
  final double threeMonthly; // 3A (son 3 aylık kümülatif TÜFE)
  final double sixMonthly; // 6A (son 6 aylık kümülatif TÜFE)
  final double yearly; // 1Y (son 12 aylık kümülatif TÜFE)
  final int latestYear;
  final int latestMonth;

  const PeriodInflationData({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.threeMonthly,
    required this.sixMonthly,
    required this.yearly,
    required this.latestYear,
    required this.latestMonth,
  });

  Map<String, dynamic> toJson() => {
        'daily': daily,
        'weekly': weekly,
        'monthly': monthly,
        'threeMonthly': threeMonthly,
        'sixMonthly': sixMonthly,
        'yearly': yearly,
        'latestYear': latestYear,
        'latestMonth': latestMonth,
      };

  factory PeriodInflationData.fromJson(Map<String, dynamic> json) =>
      PeriodInflationData(
        daily: (json['daily'] as num).toDouble(),
        weekly: (json['weekly'] as num).toDouble(),
        monthly: (json['monthly'] as num).toDouble(),
        threeMonthly: (json['threeMonthly'] as num).toDouble(),
        sixMonthly: (json['sixMonthly'] as num).toDouble(),
        yearly: (json['yearly'] as num).toDouble(),
        latestYear: json['latestYear'] as int,
        latestMonth: json['latestMonth'] as int,
      );
}

class InflationService {
  static const String _tcmbApiUrl =
      'https://appg.tcmb.gov.tr/KIMENFH/enflasyon/hesapla';

  static final Map<String, InflationInfo> _memoryCache = {};
  static final StorageService _storageService = StorageService();
  static bool _cacheInitialized = false;

  static int? _latestAvailableYear;
  static int? _latestAvailableMonth;
  static PeriodInflationData? _cachedPeriodInflation;

  /// Resmi TÜİK TÜFE Endeksleri (2003=100 Temel Yıllı)
  /// İnternet bağlantısı kesildiğinde veya sorgu zaman aşımına uğradığında anında kesintisiz hesaplama sağlar.
  static final Map<String, double> _fallbackTufeIndices = {
    // 2021
    '2021-1': 505.55,
    '2021-2': 510.15,
    '2021-3': 515.67,
    '2021-4': 524.33,
    '2021-5': 529.00,
    '2021-6': 539.26,
    '2021-7': 548.97,
    '2021-8': 555.18,
    '2021-9': 562.13,
    '2021-10': 575.60,
    '2021-11': 595.82,
    '2021-12': 686.95,
    // 2022
    '2022-1': 763.23,
    '2022-2': 799.93,
    '2022-3': 843.64,
    '2022-4': 904.79,
    '2022-5': 931.76,
    '2022-6': 977.89,
    '2022-7': 1001.03,
    '2022-8': 1015.65,
    '2022-9': 1046.89,
    '2022-10': 1084.00,
    '2022-11': 1115.26,
    '2022-12': 1128.45,
    // 2023
    '2023-1': 1203.48,
    '2023-2': 1241.33,
    '2023-3': 1269.75,
    '2023-4': 1300.04,
    '2023-5': 1300.60,
    '2023-6': 1351.59,
    '2023-7': 1479.84,
    '2023-8': 1614.31,
    '2023-9': 1691.04,
    '2023-10': 1749.11,
    '2023-11': 1806.50,
    '2023-12': 1859.38,
    // 2024
    '2024-1': 1984.02,
    '2024-2': 2073.88,
    '2024-3': 2139.47,
    '2024-4': 2207.50,
    '2024-5': 2281.85,
    '2024-6': 2319.29,
    '2024-7': 2394.10,
    '2024-8': 2453.34,
    '2024-9': 2526.16,
    '2024-10': 2598.91,
    '2024-11': 2657.23,
    '2024-12': 2684.55,
    // 2025
    '2025-1': 2819.65,
    '2025-2': 2883.75,
    '2025-3': 2954.69,
    '2025-4': 3043.23,
    '2025-5': 3089.74,
    '2025-6': 3132.17,
    '2025-7': 3196.66,
    '2025-8': 3261.72,
    '2025-9': 3367.22,
    '2025-10': 3453.09,
    '2025-11': 3482.96,
    '2025-12': 3513.87,
    // 2026
    '2026-1': 3683.83,
    '2026-2': 3793.05,
    '2026-3': 3866.74,
    '2026-4': 4028.47,
    '2026-5': 4097.55,
    '2026-6': 4137.93,
    '2026-7': 4211.58,
    '2026-8': 4289.23,
    '2026-9': 4368.35,
  };

  static Future<void> ensureCacheLoaded() async {
    if (_cacheInitialized) return;
    _cacheInitialized = true;
    try {
      final cached = await _storageService.loadInflationCache();
      for (final entry in cached.entries) {
        if (!_memoryCache.containsKey(entry.key)) {
          _memoryCache[entry.key] = entry.value;
        }
      }
    } catch (_) {}
  }

  /// Belirtilen iki dönem arasında resmi TCMB / TÜİK enflasyon verisini çeker
  static Future<InflationInfo> fetchInflationRate({
    required int startYear,
    required int startMonth,
    required int endYear,
    required int endMonth,
  }) async {
    await ensureCacheLoaded();

    // Aynı ay ve yıl ise değişim 0'dır
    if (startYear == endYear && startMonth == endMonth) {
      return InflationInfo(
        inflationRate: 0.0,
        startYear: startYear,
        startMonth: startMonth,
        endYear: endYear,
        endMonth: endMonth,
        isFromApi: true,
      );
    }

    // Başlangıç tarihi bitiş tarihinden sonra ise 0 kabul edilir
    if (startYear > endYear ||
        (startYear == endYear && startMonth > endMonth)) {
      return InflationInfo(
        inflationRate: 0.0,
        startYear: startYear,
        startMonth: startMonth,
        endYear: endYear,
        endMonth: endMonth,
        isFromApi: true,
      );
    }

    final cacheKey = '${startYear}_${startMonth}_${endYear}_$endMonth';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // TCMB Enflasyon API'sine istek gönder
    try {
      final payload = jsonEncode({
        'baslangicYil': startYear.toString(),
        'baslangicAy': startMonth.toString(),
        'bitisYil': endYear.toString(),
        'bitisAy': endMonth.toString(),
        'malSepeti': '100',
      });

      final response = await AppHttpClient.post(
        _tcmbApiUrl,
        headers: {'Content-Type': 'application/json'},
        body: payload,
        timeout: const Duration(seconds: 4),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final rawDegisim = data['toplamDegisim'];
        double degisim = 0.0;
        if (rawDegisim is num) {
          degisim = rawDegisim.toDouble();
        } else if (rawDegisim is String && rawDegisim.trim().isNotEmpty) {
          degisim = double.tryParse(rawDegisim.replaceAll(',', '.')) ?? 0.0;
        }

        final ilkTufeStr = (data['ilkYilTufe'] as String?)?.replaceAll(',', '');
        final sonTufeStr = (data['sonYilTufe'] as String?)?.replaceAll(',', '');
        final startTufe = ilkTufeStr != null ? double.tryParse(ilkTufeStr) : null;
        final endTufe = sonTufeStr != null ? double.tryParse(sonTufeStr) : null;

        final info = InflationInfo(
          inflationRate: degisim,
          startYear: startYear,
          startMonth: startMonth,
          endYear: endYear,
          endMonth: endMonth,
          startTufe: startTufe,
          endTufe: endTufe,
          isFromApi: true,
        );

        _memoryCache[cacheKey] = info;
        _saveToCache(cacheKey, info);
        return info;
      }
    } catch (_) {
      // API erişimi başarısız olursa yerel TÜFE tablosundan hesapla
    }

    // Yerel Fallback TÜFE Tablosundan Hesaplama
    final fallbackInfo = _calculateFromFallback(
      startYear: startYear,
      startMonth: startMonth,
      endYear: endYear,
      endMonth: endMonth,
    );

    _memoryCache[cacheKey] = fallbackInfo;
    return fallbackInfo;
  }

  /// Yerel TÜFE endeks tablosundan oran hesaplar
  static InflationInfo _calculateFromFallback({
    required int startYear,
    required int startMonth,
    required int endYear,
    required int endMonth,
  }) {
    final startIndex = _findClosestIndex(startYear, startMonth);
    final endIndex = _findClosestIndex(endYear, endMonth);

    double rate = 0.0;
    if (startIndex != null && endIndex != null && startIndex > 0) {
      rate = ((endIndex - startIndex) / startIndex) * 100;
      rate = double.parse(rate.toStringAsFixed(2));
    }

    return InflationInfo(
      inflationRate: rate,
      startYear: startYear,
      startMonth: startMonth,
      endYear: endYear,
      endMonth: endMonth,
      startTufe: startIndex,
      endTufe: endIndex,
      isFromApi: false,
    );
  }

  static double? _findClosestIndex(int year, int month) {
    final direct = _fallbackTufeIndices['$year-$month'];
    if (direct != null) return direct;

    // Bulunamazsa en yakın mevcut aya bak
    for (int m = month; m >= 1; m--) {
      final val = _fallbackTufeIndices['$year-$m'];
      if (val != null) return val;
    }
    for (int y = year - 1; y >= 2021; y--) {
      for (int m = 12; m >= 1; m--) {
        final val = _fallbackTufeIndices['$y-$m'];
        if (val != null) return val;
      }
    }
    return _fallbackTufeIndices['2026-9'];
  }

  static void _saveToCache(String key, InflationInfo info) {
    try {
      _storageService.saveInflationCache(_memoryCache);
    } catch (_) {}
  }

  /// En son açıklanmış resmi TÜFE ayını ve yılını tespit eder
  static Future<Map<String, int>> getLatestAvailablePeriod() async {
    if (_latestAvailableYear != null && _latestAvailableMonth != null) {
      return {
        'year': _latestAvailableYear!,
        'month': _latestAvailableMonth!,
      };
    }

    final now = DateTime.now();
    int testYear = now.year;
    int testMonth = now.month;

    // TÜFE verisi genellikle ayın 3'ünde bir önceki ay için açıklanır
    if (now.day < 4) {
      testMonth -= 1;
      if (testMonth < 1) {
        testMonth = 12;
        testYear -= 1;
      }
    }

    // TCMB'den geriye doğru sorgulayarak en son ayı bul
    for (int i = 0; i < 4; i++) {
      try {
        final res = await fetchInflationRate(
          startYear: testYear - 1,
          startMonth: testMonth,
          endYear: testYear,
          endMonth: testMonth,
        );
        if (res.isFromApi && res.endTufe != null && res.endTufe! > 0) {
          _latestAvailableYear = testYear;
          _latestAvailableMonth = testMonth;
          return {'year': testYear, 'month': testMonth};
        }
      } catch (_) {}

      testMonth -= 1;
      if (testMonth < 1) {
        testMonth = 12;
        testYear -= 1;
      }
    }

    // Fallback: 2026-9
    _latestAvailableYear = 2026;
    _latestAvailableMonth = 9;
    return {'year': 2026, 'month': 9};
  }

  /// Resmi dönemsel TÜFE enflasyon oranlarını (Günlük, Haftalık, 1A, 3A, 6A, 1Y) hesaplar ve döndürür
  static Future<PeriodInflationData> getPeriodInflationRates({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedPeriodInflation != null) {
      return _cachedPeriodInflation!;
    }

    final period = await getLatestAvailablePeriod();
    final endYear = period['year']!;
    final endMonth = period['month']!;

    // 1 Aylık TÜFE: Bir önceki aydan son aya
    int startYear1M = endYear;
    int startMonth1M = endMonth - 1;
    if (startMonth1M < 1) {
      startMonth1M = 12;
      startYear1M -= 1;
    }
    final info1M = await fetchInflationRate(
      startYear: startYear1M,
      startMonth: startMonth1M,
      endYear: endYear,
      endMonth: endMonth,
    );
    final monthlyRate = info1M.inflationRate > 0 ? info1M.inflationRate : 1.84;

    // 3 Aylık TÜFE: 3 ay öncesinden son aya
    int startYear3M = endYear;
    int startMonth3M = endMonth - 3;
    if (startMonth3M < 1) {
      startMonth3M += 12;
      startYear3M -= 1;
    }
    final info3M = await fetchInflationRate(
      startYear: startYear3M,
      startMonth: startMonth3M,
      endYear: endYear,
      endMonth: endMonth,
    );
    final threeMonthlyRate =
        info3M.inflationRate > 0 ? info3M.inflationRate : 5.57;

    // 6 Aylık TÜFE: 6 ay öncesinden son aya
    int startYear6M = endYear;
    int startMonth6M = endMonth - 6;
    if (startMonth6M < 1) {
      startMonth6M += 12;
      startYear6M -= 1;
    }
    final info6M = await fetchInflationRate(
      startYear: startYear6M,
      startMonth: startMonth6M,
      endYear: endYear,
      endMonth: endMonth,
    );
    final sixMonthlyRate =
        info6M.inflationRate > 0 ? info6M.inflationRate : 12.97;

    // 1 Yıllık TÜFE: 12 ay öncesinden son aya
    final info1Y = await fetchInflationRate(
      startYear: endYear - 1,
      startMonth: endMonth,
      endYear: endYear,
      endMonth: endMonth,
    );
    final yearlyRate = info1Y.inflationRate > 0 ? info1Y.inflationRate : 29.73;

    // Günlük ve Haftalık TÜFE: Aylık oranın bileşik gün/hafta payı
    // r_günlük = (1 + r_aylık / 100)^(1 / 30.4375) - 1
    final monthlyDecimal = monthlyRate / 100.0;
    final dailyRateDecimal = monthlyDecimal > -1.0
        ? math.pow(1.0 + monthlyDecimal, 1.0 / 30.4375).toDouble() - 1.0
        : 0.0;
    final dailyRate =
        double.parse((dailyRateDecimal * 100.0).toStringAsFixed(2));

    // r_haftalık = (1 + r_günlük)^7 - 1
    final weeklyRateDecimal =
        math.pow(1.0 + dailyRateDecimal, 7.0).toDouble() - 1.0;
    final weeklyRate =
        double.parse((weeklyRateDecimal * 100.0).toStringAsFixed(2));

    final result = PeriodInflationData(
      daily: dailyRate,
      weekly: weeklyRate,
      monthly: monthlyRate,
      threeMonthly: threeMonthlyRate,
      sixMonthly: sixMonthlyRate,
      yearly: yearlyRate,
      latestYear: endYear,
      latestMonth: endMonth,
    );

    _cachedPeriodInflation = result;
    return result;
  }

  /// Son 12 aylık yıllık resmi TÜFE oranını döndürür
  static Future<double> getLatestAnnualInflation() async {
    final periodData = await getPeriodInflationRates();
    return periodData.yearly;
  }

  /// Varlığın alış tarihinden günümüze kadar kümülatif TÜFE enflasyon oranını döndürür (%)
  /// 1 yılı doldurmayan varlıklar (15 gün, 1 ay, 3 ay vb.) dahil olmak üzere aylık ve günlük
  /// bileşik resmi TÜFE enflasyonunu kesintisiz hesaplar.
  static Future<double> getInflationSince(
    DateTime purchaseDate, [
    DateTime? targetDate,
  ]) async {
    final target = targetDate ?? DateTime.now();
    final days = target.difference(purchaseDate).inDays;
    if (days <= 0) return 0.0;

    final periodData = await getPeriodInflationRates();
    final latestYear = periodData.latestYear;
    final latestMonth = periodData.latestMonth;
    final latestReportEndDate =
        DateTime(latestYear, latestMonth + 1, 0, 23, 59, 59);

    // Aylık TÜFE'den günlük bileşik oran: (1 + r_aylık)^(1 / 30.4375) - 1
    final dailyRate = periodData.daily / 100.0;

    // 1) Alış tarihi son açıklanan rapor bitişinden sonra ise (örn. devam eden ay içi alımlar)
    if (purchaseDate.isAfter(latestReportEndDate)) {
      final compound = math.pow(1.0 + dailyRate, days).toDouble() - 1.0;
      return double.parse((compound * 100.0).toStringAsFixed(2));
    }

    // 2) Alış tarihi son açıklanan ayın içindeyse
    if (purchaseDate.year == latestYear && purchaseDate.month == latestMonth) {
      final compound = math.pow(1.0 + dailyRate, days).toDouble() - 1.0;
      return double.parse((compound * 100.0).toStringAsFixed(2));
    }

    // 3) Alış tarihi son açıklanan aydan önce:
    // Yayınlanan resmi TÜFE tablosundan alış ayından son rapora kadar olan kümülatif enflasyon
    final info = await fetchInflationRate(
      startYear: purchaseDate.year,
      startMonth: purchaseDate.month,
      endYear: latestYear,
      endMonth: latestMonth,
    );
    final publishedDecimal = info.inflationRate / 100.0;

    // Son rapor tarihinden hedef tarihe kadar olan devam eden günler
    final ongoingDays = target.difference(latestReportEndDate).inDays;
    if (ongoingDays > 0) {
      final ongoingCompound =
          math.pow(1.0 + dailyRate, ongoingDays).toDouble() - 1.0;
      final totalCompound =
          ((1.0 + publishedDecimal) * (1.0 + ongoingCompound)) - 1.0;
      return double.parse((totalCompound * 100.0).toStringAsFixed(2));
    }

    return info.inflationRate;
  }

  /// Finansal Fisher Denklemi ile Nominal Getiriden Reel Getiri Oranı (%) Hesaplama
  /// (1 + r_reel) = (1 + r_nominal) / (1 + i)
  /// r_reel = [(1 + r_nominal) / (1 + i) - 1] * 100
  static double calculateRealReturnPercent({
    required double nominalReturnPercent,
    required double inflationPercent,
  }) {
    final r = nominalReturnPercent / 100.0;
    final i = inflationPercent / 100.0;

    if (1.0 + i <= 0) return 0.0;

    final realRate = ((1.0 + r) / (1.0 + i) - 1.0) * 100.0;
    return double.parse(realRate.toStringAsFixed(2));
  }

  /// Satın alma gücü bazında Reel Kâr / Zarar Tutarı (TL)
  /// Reel Kâr = Güncel Değer - (Maliyet * (1 + Enflasyon))
  static double calculateRealProfitAmount({
    required double currentValue,
    required double totalCost,
    required double inflationPercent,
  }) {
    final adjustedCost = totalCost * (1.0 + (inflationPercent / 100.0));
    return currentValue - adjustedCost;
  }
}
