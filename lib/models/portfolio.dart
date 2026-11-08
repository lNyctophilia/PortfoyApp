import 'asset_category.dart';
import 'portfolio_asset.dart';
import 'portfolio_transaction.dart';
import 'return_mode.dart';

class Portfolio {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<PortfolioAsset> assets;
  final List<PortfolioTransaction> transactions;
  final bool isVisible;

  Portfolio({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.assets,
    this.transactions = const [],
    this.isVisible = true,
  });

  int get assetCount => assets.length;

  int get fundCount =>
      assets.where((a) => a.category == AssetCategory.fon).length;

  double get totalCost =>
      assets.fold(0.0, (sum, asset) => sum + asset.totalCost);

  double get totalValue =>
      assets.fold(0.0, (sum, asset) => sum + asset.currentValue);

  double get totalProfit => totalValue - totalCost;

  double get totalProfitPercent =>
      totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;

  double get totalWithholdingTax =>
      assets.fold(0.0, (sum, asset) => sum + asset.withholdingTaxAmount);

  double get netTotalProfit => totalProfit - totalWithholdingTax;

  double get netTotalProfitPercent =>
      totalCost > 0 ? (netTotalProfit / totalCost) * 100 : 0.0;

  double get netTotalValue => totalValue - totalWithholdingTax;

  /// Enflasyona göre endekslenmiş toplam portföy maliyeti
  double realCost([Map<String, double>? assetInflationRates]) => assets.fold(
        0.0,
        (sum, a) =>
            sum + a.realCost(assetInflationRates?[a.id] ?? 0.0),
      );

  /// Reel Kâr / Zarar Tutarı (TL)
  double realTotalProfit([Map<String, double>? assetInflationRates]) =>
      assets.fold(
        0.0,
        (sum, a) =>
            sum + a.realProfit(assetInflationRates?[a.id] ?? 0.0),
      );

  /// Reel Getiri Oranı (%)
  double realTotalProfitPercent([Map<String, double>? assetInflationRates]) {
    final cost = realCost(assetInflationRates);
    if (cost <= 0) return 0.0;
    return (realTotalProfit(assetInflationRates) / cost) * 100.0;
  }

  /// Seçili moda göre toplam kâr tutarı
  double profitForMode(
    ReturnCalculationMode mode, [
    Map<String, double>? assetInflationRates,
  ]) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return totalProfit;
      case ReturnCalculationMode.net:
      case ReturnCalculationMode.reel:
        return netTotalProfit;
    }
  }

  /// Seçili moda göre getiri yüzdesi (%)
  double profitPercentForMode(
    ReturnCalculationMode mode, [
    Map<String, double>? assetInflationRates,
  ]) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return totalProfitPercent;
      case ReturnCalculationMode.net:
        return netTotalProfitPercent;
      case ReturnCalculationMode.reel:
        return realTotalProfitPercent(assetInflationRates);
    }
  }

  /// Seçili moda göre toplam portföy değeri (TL)
  double valueForMode(ReturnCalculationMode mode) {
    switch (mode) {
      case ReturnCalculationMode.brut:
        return totalValue;
      case ReturnCalculationMode.net:
      case ReturnCalculationMode.reel:
        return netTotalValue;
    }
  }

  double get allTimeProfitPercent => totalProfitPercent;

  double get realizedProfit => transactions
      .where((t) => t.type == TransactionType.satis)
      .fold(0.0, (sum, t) => sum + t.realizedProfit);

  double get realizedWithholdingTax => transactions
      .where((t) => t.type == TransactionType.satis)
      .fold(0.0, (sum, t) => sum + t.withholdingTax);

  double get netRealizedProfit => transactions
      .where((t) => t.type == TransactionType.satis)
      .fold(0.0, (sum, t) => sum + t.netRealizedProfit);

  DateTime get earliestPurchaseDate {
    DateTime? minDate;
    for (final asset in assets) {
      if (minDate == null || asset.purchaseDate.isBefore(minDate)) {
        minDate = asset.purchaseDate;
      }
    }
    for (final tx in transactions) {
      if (minDate == null || tx.date.isBefore(minDate)) {
        minDate = tx.date;
      }
    }
    return minDate ?? createdAt;
  }

  int get holdingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = DateTime(
      earliestPurchaseDate.year,
      earliestPurchaseDate.month,
      earliestPurchaseDate.day,
    );
    final diff = today.difference(earliest).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get hasDailyData => true;
  bool get hasWeeklyData => holdingDays >= 7;
  bool get hasMonthlyData => holdingDays >= 30;
  bool get hasThreeMonthlyData => holdingDays >= 90;
  bool get hasSixMonthlyData => holdingDays >= 180;
  bool get hasYearlyData => holdingDays >= 365;

  // Dönemsel toplam kâr ve yüzdeler
  double get dailyProfit =>
      assets.fold(0.0, (sum, asset) => sum + asset.dailyProfit);

  double get dailyChangePercent {
    if (totalValue <= 0) return 0.0;
    final prevValue = totalValue - dailyProfit;
    return prevValue > 0 ? (dailyProfit / prevValue) * 100 : 0.0;
  }

  double get weeklyProfit =>
      hasWeeklyData ? assets.fold(0.0, (sum, asset) => sum + asset.weeklyProfit) : 0.0;

  double get weeklyChangePercent {
    if (!hasWeeklyData || totalValue <= 0) return 0.0;
    final prevValue = totalValue - weeklyProfit;
    return prevValue > 0 ? (weeklyProfit / prevValue) * 100 : 0.0;
  }

  double get monthlyProfit =>
      hasMonthlyData ? assets.fold(0.0, (sum, asset) => sum + asset.monthlyProfit) : 0.0;

  double get monthlyChangePercent {
    if (!hasMonthlyData || totalValue <= 0) return 0.0;
    final prevValue = totalValue - monthlyProfit;
    return prevValue > 0 ? (monthlyProfit / prevValue) * 100 : 0.0;
  }

  double get threeMonthlyProfit =>
      hasThreeMonthlyData ? assets.fold(0.0, (sum, asset) => sum + asset.threeMonthlyProfit) : 0.0;

  double get threeMonthlyChangePercent {
    if (!hasThreeMonthlyData || totalValue <= 0) return 0.0;
    final prevValue = totalValue - threeMonthlyProfit;
    return prevValue > 0 ? (threeMonthlyProfit / prevValue) * 100 : 0.0;
  }

  double get sixMonthlyProfit =>
      hasSixMonthlyData ? assets.fold(0.0, (sum, asset) => sum + asset.sixMonthlyProfit) : 0.0;

  double get sixMonthlyChangePercent {
    if (!hasSixMonthlyData || totalValue <= 0) return 0.0;
    final prevValue = totalValue - sixMonthlyProfit;
    return prevValue > 0 ? (sixMonthlyProfit / prevValue) * 100 : 0.0;
  }

  double get yearlyProfit =>
      hasYearlyData ? assets.fold(0.0, (sum, asset) => sum + asset.yearlyProfit) : 0.0;

  double get yearlyChangePercent {
    if (!hasYearlyData || totalValue <= 0) return 0.0;
    final prevValue = totalValue - yearlyProfit;
    return prevValue > 0 ? (yearlyProfit / prevValue) * 100 : 0.0;
  }

  // Varlık bazlı dağılım (yüzde cinsinden, büyükten küçüğe sıralı)
  List<AssetAllocationItem> get assetAllocations {
    final effectiveTotal = totalWithholdingTax > 0 ? netTotalValue : totalValue;
    if (effectiveTotal <= 0 || assets.isEmpty) return [];

    final Map<String, AssetAllocationItem> map = {};
    for (final asset in assets) {
      final key = asset.symbol.trim().isNotEmpty
          ? asset.symbol.trim()
          : asset.name.trim();
      final val = (asset.category == AssetCategory.fon && asset.withholdingTaxAmount > 0)
          ? asset.netCurrentValue
          : asset.currentValue;
      if (val <= 0) continue;

      if (map.containsKey(key)) {
        final existing = map[key]!;
        final newVal = existing.value + val;
        map[key] = AssetAllocationItem(
          symbol: existing.symbol,
          name: existing.name,
          category: existing.category,
          value: newVal,
          percentage: (newVal / effectiveTotal) * 100,
        );
      } else {
        map[key] = AssetAllocationItem(
          symbol: key,
          name: asset.name,
          category: asset.category,
          value: val,
          percentage: (val / effectiveTotal) * 100,
        );
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  // Kategori bazlı dağılım (yüzde cinsinden)
  Map<AssetCategory, double> get categoryPercentages {
    final effectiveTotal = totalWithholdingTax > 0 ? netTotalValue : totalValue;
    if (effectiveTotal <= 0) return {};
    final Map<AssetCategory, double> result = {};
    for (final cat in AssetCategory.values) {
      final catValue = assets
          .where((a) => a.category == cat)
          .fold(
            0.0,
            (sum, a) =>
                sum +
                ((a.category == AssetCategory.fon && a.withholdingTaxAmount > 0)
                    ? a.netCurrentValue
                    : a.currentValue),
          );
      if (catValue > 0) {
        result[cat] = (catValue / effectiveTotal) * 100;
      }
    }
    return result;
  }

  Map<AssetCategory, double> get categoryValues {
    final Map<AssetCategory, double> result = {};
    for (final cat in AssetCategory.values) {
      final catValue = assets
          .where((a) => a.category == cat)
          .fold(
            0.0,
            (sum, a) =>
                sum +
                ((a.category == AssetCategory.fon && a.withholdingTaxAmount > 0)
                    ? a.netCurrentValue
                    : a.currentValue),
          );
      if (catValue > 0) {
        result[cat] = catValue;
      }
    }
    return result;
  }

  Portfolio copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<PortfolioAsset>? assets,
    List<PortfolioTransaction>? transactions,
    bool? isVisible,
  }) {
    return Portfolio(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      assets: assets ?? this.assets,
      transactions: transactions ?? this.transactions,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'isVisible': isVisible,
    };
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => PortfolioAsset.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList() ??
          [],
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) => PortfolioTransaction.fromJson(Map<String, dynamic>.from(t as Map)))
              .toList() ??
          [],
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}

class AssetAllocationItem {
  final String symbol;
  final String name;
  final AssetCategory category;
  final double value;
  final double percentage;

  const AssetAllocationItem({
    required this.symbol,
    required this.name,
    required this.category,
    required this.value,
    required this.percentage,
  });
}
