import '../../../models/portfolio.dart';
import '../../../models/portfolio_asset.dart';
import '../models/model_portfolio_analysis.dart';

class ModelPortfolioService {
  static const List<String> _turkishMonths = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String getMonthLabel(int year, int month) {
    final mName = (month >= 1 && month <= 12) ? _turkishMonths[month] : '$month';
    return '$mName $year';
  }

  /// Model portföyün geriye dönük getirilerini (Backtest) ve aylık analizini hesaplar
  static ModelPortfolioAnalysis analyze(Portfolio portfolio) {
    if (portfolio.assets.isEmpty) {
      return const ModelPortfolioAnalysis(
        averageMonthlyReturn: 0.0,
      );
    }

    final assets = portfolio.assets;
    final totalAllocation = portfolio.totalAllocationPercent > 0
        ? portfolio.totalAllocationPercent
        : 100.0;

    // -------------------------------------------------------------
    // 1. DÖNEMSEL GETİRİLER VE VERİ SINIRI KONTROLÜ
    // -------------------------------------------------------------
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final periodConfigs = <String, int>{
      '1G': 1,
      '1H': 7,
      '1A': 30,
      '3A': 90,
      '6A': 180,
      '1Y': 365,
      '2Y': 730,
      '3Y': 1095,
      '5Y': 1825,
    };

    final Map<String, double> periodReturns = {};
    final Map<String, List<String>> periodMissingAssets = {};

    for (final entry in periodConfigs.entries) {
      final period = entry.key;
      final daysAgo = entry.value;
      final targetDate = today.subtract(Duration(days: daysAgo));

      double weightedSum = 0.0;
      double effectiveWeight = 0.0;
      final List<String> missingInPeriod = [];

      for (final asset in assets) {
        final weight = asset.targetAllocationPercent > 0
            ? asset.targetAllocationPercent
            : (totalAllocation / assets.length);

        // Varlığın en erken verisi hedef tarihten sonra ise sınırı aşılmıştır
        if (asset.earliestDate != null && asset.earliestDate!.isAfter(targetDate)) {
          missingInPeriod.add(asset.symbol.isNotEmpty ? asset.symbol : asset.name);
        }

        double assetReturn = 0.0;
        switch (period) {
          case '1G':
            assetReturn = asset.dailyChangePercent;
            break;
          case '1H':
            assetReturn = asset.weeklyChangePercent;
            break;
          case '1A':
            assetReturn = asset.monthlyChangePercent;
            break;
          case '3A':
            assetReturn = asset.threeMonthlyChangePercent;
            break;
          case '6A':
            assetReturn = asset.sixMonthlyChangePercent;
            break;
          case '1Y':
            assetReturn = asset.yearlyChangePercent;
            break;
          case '2Y':
            assetReturn = asset.twoYearlyChangePercent;
            break;
          case '3Y':
            assetReturn = asset.threeYearlyChangePercent;
            break;
          case '5Y':
            assetReturn = asset.fiveYearlyChangePercent;
            break;
        }

        weightedSum += (assetReturn * weight);
        effectiveWeight += weight;
      }

      final ret = effectiveWeight > 0 ? (weightedSum / effectiveWeight) : 0.0;
      periodReturns[period] = double.parse(ret.toStringAsFixed(2));
      if (missingInPeriod.isNotEmpty) {
        periodMissingAssets[period] = missingInPeriod;
      }
    }

    // -------------------------------------------------------------
    // 2. AYLIK GETİRİ ANALİZİ VE SINIR UYARILARI
    // -------------------------------------------------------------
    // Tüm varlıkların mevcut aylarını topla
    final Set<String> allMonthKeys = {};
    for (final a in assets) {
      allMonthKeys.addAll(a.monthlyReturns.keys);
    }

    // Eğer monthlyReturns boş ise son 12 ayı oluştur
    if (allMonthKeys.isEmpty) {
      DateTime temp = DateTime(now.year, now.month);
      for (int i = 0; i < 12; i++) {
        final k = '${temp.year}-${temp.month.toString().padLeft(2, '0')}';
        allMonthKeys.add(k);
        temp = DateTime(temp.year, temp.month - 1);
      }
    }

    // Ayları yeniden eskiye sırala (örn: 2026-10, 2026-09, 2026-08...)
    final sortedMonthKeys = allMonthKeys.toList()..sort((a, b) => b.compareTo(a));

    final List<ModelMonthReturn> monthlyHistory = [];
    final Set<String> warnedAssetIds = {};

    for (final monthKey in sortedMonthKeys) {
      final parts = monthKey.split('-');
      final year = int.tryParse(parts[0]) ?? now.year;
      final month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
      final monthStart = DateTime(year, month, 1);
      final monthLabel = getMonthLabel(year, month);

      double monthWeightedSum = 0.0;
      double monthWeight = 0.0;
      final List<String> warnedInThisMonth = [];

      for (final asset in assets) {
        final weight = asset.targetAllocationPercent > 0
            ? asset.targetAllocationPercent
            : (totalAllocation / assets.length);

        final hasReturnForMonth = asset.monthlyReturns.containsKey(monthKey);
        final ret = asset.monthlyReturns[monthKey] ?? 0.0;

        if (hasReturnForMonth) {
          monthWeightedSum += (ret * weight);
          monthWeight += weight;
        }

        // Varlığın max tarihi kontrolü (geçmişe doğru giderken ilk aşıldığı ayda uyarı ver)
        final isDataExceeded = (asset.earliestDate != null &&
                asset.earliestDate!.isAfter(monthStart)) ||
            (!hasReturnForMonth && asset.monthlyReturns.isNotEmpty);

        if (isDataExceeded) {
          if (!warnedAssetIds.contains(asset.id)) {
            warnedInThisMonth.add(asset.symbol.isNotEmpty ? asset.symbol : asset.name);
            warnedAssetIds.add(asset.id);
          }
        }
      }

      final monthReturnVal = monthWeight > 0 ? (monthWeightedSum / monthWeight) : 0.0;
      monthlyHistory.add(
        ModelMonthReturn(
          monthKey: monthKey,
          monthLabel: monthLabel,
          returnPercent: double.parse(monthReturnVal.toStringAsFixed(2)),
          warnedAssetNames: warnedInThisMonth,
          year: year,
          month: month,
        ),
      );
    }

    // -------------------------------------------------------------
    // 3. İSTATİSTİKLER (Ortalama Aylık Getiri, En İyi Ay, En Kötü Ay)
    // -------------------------------------------------------------
    double avgMonthly = 0.0;
    ModelMonthReturn? bestMonth;
    ModelMonthReturn? worstMonth;

    if (monthlyHistory.isNotEmpty) {
      double totalSum = 0.0;
      for (final m in monthlyHistory) {
        totalSum += m.returnPercent;
        if (bestMonth == null || m.returnPercent > bestMonth.returnPercent) {
          bestMonth = m;
        }
        if (worstMonth == null || m.returnPercent < worstMonth.returnPercent) {
          worstMonth = m;
        }
      }
      avgMonthly = double.parse((totalSum / monthlyHistory.length).toStringAsFixed(2));
    }

    return ModelPortfolioAnalysis(
      averageMonthlyReturn: avgMonthly,
      bestMonth: bestMonth,
      worstMonth: worstMonth,
      monthlyHistory: monthlyHistory,
      periodReturns: periodReturns,
      periodMissingAssets: periodMissingAssets,
    );
  }
}
