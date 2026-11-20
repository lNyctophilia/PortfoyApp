class ModelMonthReturn {
  final String monthKey; // e.g. "2026-10"
  final String monthLabel; // e.g. "Ekim 2026"
  final double returnPercent;
  final List<String> warnedAssetNames; // Varlıkların max tarihi aşıldığında sadece bu ay için tetiklenen liste
  final int year;
  final int month;

  const ModelMonthReturn({
    required this.monthKey,
    required this.monthLabel,
    required this.returnPercent,
    this.warnedAssetNames = const [],
    required this.year,
    required this.month,
  });

  bool get hasWarning => warnedAssetNames.isNotEmpty;

  String get warningMessage {
    if (warnedAssetNames.isEmpty) return '';
    final assets = warnedAssetNames.join(', ');
    return 'Bu varlığın son verisi geçildi: $assets için bu tarihten öncesi veri bulunmuyor.';
  }
}

class ModelPortfolioAnalysis {
  final double averageMonthlyReturn;
  final ModelMonthReturn? bestMonth;
  final ModelMonthReturn? worstMonth;
  final List<ModelMonthReturn> monthlyHistory;
  final Map<String, double> periodReturns; // '1G', '1H', '1A', '3A', '6A', '1Y', '2Y', '3Y', '5Y'
  final Map<String, List<String>> periodMissingAssets; // Dönem bazlı veri sınırı aşılan varlıklar

  const ModelPortfolioAnalysis({
    required this.averageMonthlyReturn,
    this.bestMonth,
    this.worstMonth,
    this.monthlyHistory = const [],
    this.periodReturns = const {},
    this.periodMissingAssets = const {},
  });

  bool isPeriodExceeded(String period) =>
      periodMissingAssets[period]?.isNotEmpty ?? false;

  List<String> getMissingAssetsForPeriod(String period) =>
      periodMissingAssets[period] ?? const [];
}
