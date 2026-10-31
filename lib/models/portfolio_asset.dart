import 'asset_category.dart';
import '../services/market_data_service.dart';
import '../services/inflation_service.dart';
import 'return_mode.dart';

class PortfolioAsset {
  final String id;
  final String name;
  final String symbol;
  final AssetCategory category;
  final DateTime purchaseDate;
  final double purchasePrice;
  final double quantity;
  final double currentPrice;

  // Tarihsel değişim oranları (%)
  final double dailyChangePercent;
  final double weeklyChangePercent;
  final double monthlyChangePercent;
  final double threeMonthlyChangePercent;
  final double sixMonthlyChangePercent;
  final double yearlyChangePercent;
  final String? iconUrl;
  final double? withholdingTaxRate;

  PortfolioAsset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.quantity,
    required this.currentPrice,
    this.dailyChangePercent = 0.0,
    this.weeklyChangePercent = 0.0,
    this.monthlyChangePercent = 0.0,
    this.threeMonthlyChangePercent = 0.0,
    this.sixMonthlyChangePercent = 0.0,
    this.yearlyChangePercent = 0.0,
    this.iconUrl,
    this.withholdingTaxRate,
  });

  double get effectiveWithholdingTaxRate =>
      category == AssetCategory.fon
          ? (withholdingTaxRate ??
              MarketDataService.defaultWithholdingTaxRate(
                  category, name, symbol))
          : 0.0;

  double get withholdingTaxAmount {
    if (category != AssetCategory.fon || totalProfit <= 0) return 0.0;
    return totalProfit * (effectiveWithholdingTaxRate / 100);
  }

  double get netProfit => totalProfit - withholdingTaxAmount;

  double get netProfitPercent =>
      totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;

  double get netCurrentValue => currentValue - withholdingTaxAmount;

  double get netCurrentPrice =>
      quantity > 0 ? (netCurrentValue / quantity) : currentPrice;

  double get totalCost => purchasePrice * quantity;
  double get currentValue => currentPrice * quantity;
  double get totalProfit => currentValue - totalCost;
  double get totalProfitPercent => totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;

  /// Enflasyona göre düzeltilmiş maliyet
  double realCost([double inflationPercent = 0.0]) =>
      totalCost * (1.0 + (inflationPercent / 100.0));

  /// Reel Kâr / Zarar Tutarı (TL)
  /// Net değerden enflasyona göre endekslenmiş maliyetin çıkarılmasıyla bulunur
  double realProfit([double inflationPercent = 0.0]) =>
      netCurrentValue - realCost(inflationPercent);

  /// Reel Getiri Oranı (%)
  /// Fisher Denklemi: [(1 + r_net) / (1 + i) - 1] * 100
  double realProfitPercent([double inflationPercent = 0.0]) {
    if (totalCost <= 0) return 0.0;
    return InflationService.calculateRealReturnPercent(
      nominalReturnPercent: netProfitPercent,
      inflationPercent: inflationPercent,
    );
  }

  /// Seçili getiri hesaplama moduna göre kâr / zarar tutarı (TL)
  double profitForMode(
    ReturnCalculationMode mode, [
    double inflationPercent = 0.0,
  ]) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return totalProfit;
      case ReturnCalculationMode.net:
        return netProfit;
      case ReturnCalculationMode.reel:
        return realProfit(inflationPercent);
    }
  }

  /// Seçili getiri hesaplama moduna göre yüzde getiri (%)
  double profitPercentForMode(
    ReturnCalculationMode mode, [
    double inflationPercent = 0.0,
  ]) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return totalProfitPercent;
      case ReturnCalculationMode.net:
        return netProfitPercent;
      case ReturnCalculationMode.reel:
        return realProfitPercent(inflationPercent);
    }
  }

  /// Seçili moda göre gösterilecek varlık değeri (TL)
  double valueForMode(ReturnCalculationMode mode) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return currentValue;
      case ReturnCalculationMode.net:
      case ReturnCalculationMode.reel:
        return netCurrentValue;
    }
  }

  int get holdingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final purchase = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    final diff = today.difference(purchase).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get hasWeeklyData => holdingDays >= 7;
  bool get hasMonthlyData => holdingDays >= 30;
  bool get hasThreeMonthlyData => holdingDays >= 90;
  bool get hasSixMonthlyData => holdingDays >= 180;
  bool get hasYearlyData => holdingDays >= 365;

  double _calcPeriodProfit(double changePercent) {
    if (changePercent <= -100) return -currentValue;
    return currentValue * (changePercent / (100 + changePercent));
  }

  // Dönemsel kâr / zarar tutarları (Portföyde bulunulan süreye duyarlı)
  double get dailyProfit =>
      holdingDays < 1 ? totalProfit : _calcPeriodProfit(dailyChangePercent);

  double get weeklyProfit =>
      holdingDays < 7 ? totalProfit : _calcPeriodProfit(weeklyChangePercent);

  double get monthlyProfit =>
      holdingDays < 30 ? totalProfit : _calcPeriodProfit(monthlyChangePercent);

  double get threeMonthlyProfit =>
      holdingDays < 90 ? totalProfit : _calcPeriodProfit(threeMonthlyChangePercent);

  double get sixMonthlyProfit =>
      holdingDays < 180 ? totalProfit : _calcPeriodProfit(sixMonthlyChangePercent);

  double get yearlyProfit =>
      holdingDays < 365 ? totalProfit : _calcPeriodProfit(yearlyChangePercent);

  PortfolioAsset copyWith({
    String? id,
    String? name,
    String? symbol,
    AssetCategory? category,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? quantity,
    double? currentPrice,
    double? dailyChangePercent,
    double? weeklyChangePercent,
    double? monthlyChangePercent,
    double? threeMonthlyChangePercent,
    double? sixMonthlyChangePercent,
    double? yearlyChangePercent,
    String? iconUrl,
    double? withholdingTaxRate,
  }) {
    return PortfolioAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantity: quantity ?? this.quantity,
      currentPrice: currentPrice ?? this.currentPrice,
      dailyChangePercent: dailyChangePercent ?? this.dailyChangePercent,
      weeklyChangePercent: weeklyChangePercent ?? this.weeklyChangePercent,
      monthlyChangePercent: monthlyChangePercent ?? this.monthlyChangePercent,
      threeMonthlyChangePercent: threeMonthlyChangePercent ?? this.threeMonthlyChangePercent,
      sixMonthlyChangePercent: sixMonthlyChangePercent ?? this.sixMonthlyChangePercent,
      yearlyChangePercent: yearlyChangePercent ?? this.yearlyChangePercent,
      iconUrl: iconUrl ?? this.iconUrl,
      withholdingTaxRate: withholdingTaxRate ?? this.withholdingTaxRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'category': category.name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'currentPrice': currentPrice,
      'dailyChangePercent': dailyChangePercent,
      'weeklyChangePercent': weeklyChangePercent,
      'monthlyChangePercent': monthlyChangePercent,
      'threeMonthlyChangePercent': threeMonthlyChangePercent,
      'sixMonthlyChangePercent': sixMonthlyChangePercent,
      'yearlyChangePercent': yearlyChangePercent,
      'iconUrl': iconUrl,
      'withholdingTaxRate': withholdingTaxRate,
    };
  }

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String? ?? json['name'] as String,
      category: AssetCategory.fromString(json['category'] as String),
      purchaseDate: DateTime.tryParse(json['purchaseDate'] as String? ?? '') ?? DateTime.now(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      dailyChangePercent: (json['dailyChangePercent'] as num?)?.toDouble() ?? 0.0,
      weeklyChangePercent: (json['weeklyChangePercent'] as num?)?.toDouble() ?? 0.0,
      monthlyChangePercent: (json['monthlyChangePercent'] as num?)?.toDouble() ?? 0.0,
      threeMonthlyChangePercent: (json['threeMonthlyChangePercent'] as num?)?.toDouble() ?? 0.0,
      sixMonthlyChangePercent: (json['sixMonthlyChangePercent'] as num?)?.toDouble() ?? 0.0,
      yearlyChangePercent: (json['yearlyChangePercent'] as num?)?.toDouble() ?? 0.0,
      iconUrl: json['iconUrl'] as String?,
      withholdingTaxRate: (json['withholdingTaxRate'] as num?)?.toDouble(),
    );
  }
}
