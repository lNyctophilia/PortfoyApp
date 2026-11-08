import 'asset_category.dart';
import '../services/market_data_service.dart';

enum TransactionType {
  alis('Alış'),
  satis('Satış');

  final String label;
  const TransactionType(this.label);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value || t.label == value,
      orElse: () => TransactionType.alis,
    );
  }
}

class PortfolioTransaction {
  final String id;
  final String portfolioId;
  final TransactionType type;
  final String symbol;
  final String name;
  final AssetCategory category;
  final DateTime date;
  final double quantity;
  final double price; // Alışta alış fiyatı, satışta satış fiyatı
  final double costPrice; // Satışta maliyet (alış fiyatı)
  final double realizedProfit; // Satışta: (price - costPrice) * quantity
  final String? assetId; // İlişkili portföy varlığı (varsa)
  final double? currentPrice;
  final String? iconUrl;
  final double? dailyChangePercent;
  final double? weeklyChangePercent;
  final double? monthlyChangePercent;
  final double? threeMonthlyChangePercent;
  final double? sixMonthlyChangePercent;
  final double? yearlyChangePercent;
  final double? withholdingTaxRate;

  PortfolioTransaction({
    required this.id,
    required this.portfolioId,
    required this.type,
    required this.symbol,
    required this.name,
    required this.category,
    required this.date,
    required this.quantity,
    required this.price,
    this.costPrice = 0.0,
    double? realizedProfit,
    this.assetId,
    this.currentPrice,
    this.iconUrl,
    this.dailyChangePercent,
    this.weeklyChangePercent,
    this.monthlyChangePercent,
    this.threeMonthlyChangePercent,
    this.sixMonthlyChangePercent,
    this.yearlyChangePercent,
    this.withholdingTaxRate,
  }) : realizedProfit = realizedProfit ??
            (type == TransactionType.satis
                ? (price - costPrice) * quantity
                : 0.0);

  double get effectiveWithholdingTaxRate =>
      withholdingTaxRate ??
      (category == AssetCategory.fon
          ? MarketDataService.defaultWithholdingTaxRate(category, name, symbol)
          : 0.0);

  double get withholdingTax =>
      (type == TransactionType.satis &&
              effectiveWithholdingTaxRate > 0 &&
              realizedProfit > 0)
          ? realizedProfit * (effectiveWithholdingTaxRate / 100)
          : 0.0;

  double get netRealizedProfit => realizedProfit - withholdingTax;

  double get netProfitPercent {
    if (type != TransactionType.satis || costPrice <= 0 || quantity <= 0) return 0.0;
    return (netRealizedProfit / (costPrice * quantity)) * 100;
  }

  double get totalAmount => price * quantity;

  double get profitPercent {
    if (type != TransactionType.satis || costPrice <= 0) return 0.0;
    return ((price - costPrice) / costPrice) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolioId': portfolioId,
      'type': type.name,
      'symbol': symbol,
      'name': name,
      'category': category.name,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'realizedProfit': realizedProfit,
      'assetId': assetId,
      'currentPrice': currentPrice,
      'iconUrl': iconUrl,
      'dailyChangePercent': dailyChangePercent,
      'weeklyChangePercent': weeklyChangePercent,
      'monthlyChangePercent': monthlyChangePercent,
      'threeMonthlyChangePercent': threeMonthlyChangePercent,
      'sixMonthlyChangePercent': sixMonthlyChangePercent,
      'yearlyChangePercent': yearlyChangePercent,
      'withholdingTaxRate': withholdingTaxRate,
    };
  }

  factory PortfolioTransaction.fromJson(Map<String, dynamic> json) {
    final type = TransactionType.fromString(json['type'] as String? ?? 'alis');
    final quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final costPrice = (json['costPrice'] as num?)?.toDouble() ?? 0.0;
    final parsedRealized = (json['realizedProfit'] as num?)?.toDouble();

    return PortfolioTransaction(
      id: json['id'] as String,
      portfolioId: json['portfolioId'] as String? ?? '',
      type: type,
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: AssetCategory.fromString(json['category'] as String? ?? 'diger'),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      quantity: quantity,
      price: price,
      costPrice: costPrice,
      realizedProfit: parsedRealized ??
          (type == TransactionType.satis ? (price - costPrice) * quantity : 0.0),
      assetId: json['assetId'] as String?,
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      iconUrl: json['iconUrl'] as String?,
      dailyChangePercent: (json['dailyChangePercent'] as num?)?.toDouble(),
      weeklyChangePercent: (json['weeklyChangePercent'] as num?)?.toDouble(),
      monthlyChangePercent: (json['monthlyChangePercent'] as num?)?.toDouble(),
      threeMonthlyChangePercent: (json['threeMonthlyChangePercent'] as num?)?.toDouble(),
      sixMonthlyChangePercent: (json['sixMonthlyChangePercent'] as num?)?.toDouble(),
      yearlyChangePercent: (json['yearlyChangePercent'] as num?)?.toDouble(),
      withholdingTaxRate: (json['withholdingTaxRate'] as num?)?.toDouble(),
    );
  }
}
