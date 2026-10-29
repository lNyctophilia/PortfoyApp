import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';

/// Belirli bir tarihteki alış lotunu temsil eder.
class AssetLot {
  final String id;
  final DateTime date;
  final double originalQuantity;
  final double purchasePrice;
  double remainingQuantity;

  AssetLot({
    required this.id,
    required this.date,
    required this.originalQuantity,
    required this.purchasePrice,
    required this.remainingQuantity,
  });

  double get totalOriginalCost => originalQuantity * purchasePrice;
  double get totalRemainingCost => remainingQuantity * purchasePrice;
  double get soldQuantity => (originalQuantity - remainingQuantity).clamp(0.0, originalQuantity);

  bool get isFullySold => remainingQuantity <= 0.000001;
  bool get isPartiallySold => remainingQuantity > 0.000001 && remainingQuantity < (originalQuantity - 0.000001);
  bool get isActive => remainingQuantity >= (originalQuantity - 0.000001);

  double unrealizedProfit(double currentPrice) => (currentPrice - purchasePrice) * remainingQuantity;

  double unrealizedProfitPercent(double currentPrice) =>
      purchasePrice > 0 ? ((currentPrice - purchasePrice) / purchasePrice) * 100 : 0.0;
}

/// Bir satış işleminde hangi lottan ne kadar düşüldüğünü gösterir.
class FifoConsumption {
  final AssetLot lot;
  final double quantityConsumed;
  final double unitCost;

  FifoConsumption({
    required this.lot,
    required this.quantityConsumed,
    required this.unitCost,
  });

  double get totalCost => quantityConsumed * unitCost;
}

/// Bir satışın FIFO bazlı maliyet ve kâr/zarar kaydı.
class FifoSaleRecord {
  final PortfolioTransaction transaction;
  final double totalSaleCost;
  final double unitCost;
  final double realizedProfit;
  final double realizedProfitPercent;
  final List<FifoConsumption> consumptions;

  FifoSaleRecord({
    required this.transaction,
    required this.totalSaleCost,
    required this.unitCost,
    required this.realizedProfit,
    required this.realizedProfitPercent,
    required this.consumptions,
  });
}

/// Bir varlığın tüm FIFO lot ve maliyet hesaplama çıktısı.
class FifoResult {
  final String symbol;
  final List<AssetLot> allLots;
  final List<FifoSaleRecord> saleRecords;

  FifoResult({
    required this.symbol,
    required this.allLots,
    required this.saleRecords,
  });

  List<AssetLot> get activeLots => allLots.where((l) => !l.isFullySold).toList();

  double get remainingQuantity =>
      allLots.fold(0.0, (sum, l) => sum + l.remainingQuantity);

  double get remainingCost =>
      allLots.fold(0.0, (sum, l) => sum + l.totalRemainingCost);

  double get averageRemainingCost =>
      remainingQuantity > 0 ? (remainingCost / remainingQuantity) : 0.0;

  double get totalOriginalQuantity =>
      allLots.fold(0.0, (sum, l) => sum + l.originalQuantity);

  double get totalSoldQuantity =>
      allLots.fold(0.0, (sum, l) => sum + l.soldQuantity);

  double get totalRealizedProfit =>
      saleRecords.fold(0.0, (sum, s) => sum + s.realizedProfit);
}

/// Satış anında hesaplanan tahmini maliyet sonucu.
class FifoCostEstimation {
  final double totalCost;
  final double unitCost;
  final double quantity;
  final bool hasEnoughHoldings;
  final List<FifoConsumption> plannedConsumptions;

  FifoCostEstimation({
    required this.totalCost,
    required this.unitCost,
    required this.quantity,
    required this.hasEnoughHoldings,
    required this.plannedConsumptions,
  });
}

class FifoCalculator {
  /// Portföydeki belirli bir sembolün tüm alış ve satışlarını FIFO mantığıyla hesaplar.
  static FifoResult calculate(
    Portfolio portfolio,
    String symbol, {
    PortfolioAsset? assetFallback,
  }) {
    final cleanSymbol = symbol.trim().toUpperCase();

    // 1. Alış işlemlerini kronolojik (en eski -> en yeni) sırala
    final alisTransactions = portfolio.transactions
        .where((t) =>
            t.type == TransactionType.alis &&
            t.symbol.trim().toUpperCase() == cleanSymbol)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<AssetLot> lots = [];

    // Eğer işlem kaydı yoksa ancak mevcut varlık varsa (başlangıç portföyü verisi)
    if (alisTransactions.isEmpty && assetFallback != null) {
      lots.add(
        AssetLot(
          id: 'initial_${assetFallback.id}',
          date: assetFallback.purchaseDate,
          originalQuantity: assetFallback.quantity,
          purchasePrice: assetFallback.purchasePrice,
          remainingQuantity: assetFallback.quantity,
        ),
      );
    } else {
      // Eğer hem varlık var hem de işlem kayıtları var ise,
      // İşlem kayıtlarının toplam miktarı mevcut varlık miktarından küçükse başlangıç lotu ekle
      final totalAlisTxQty =
          alisTransactions.fold(0.0, (sum, t) => sum + t.quantity);
      if (assetFallback != null &&
          assetFallback.quantity > (totalAlisTxQty + 0.0001)) {
        final initialBaseQty = assetFallback.quantity - totalAlisTxQty;
        lots.add(
          AssetLot(
            id: 'initial_${assetFallback.id}',
            date: assetFallback.purchaseDate,
            originalQuantity: initialBaseQty,
            purchasePrice: assetFallback.purchasePrice,
            remainingQuantity: initialBaseQty,
          ),
        );
      }

      for (final tx in alisTransactions) {
        lots.add(
          AssetLot(
            id: tx.id,
            date: tx.date,
            originalQuantity: tx.quantity,
            purchasePrice: tx.price,
            remainingQuantity: tx.quantity,
          ),
        );
      }
    }

    // 2. Satış işlemlerini kronolojik (en eski -> en yeni) sırala
    final satisTransactions = portfolio.transactions
        .where((t) =>
            t.type == TransactionType.satis &&
            t.symbol.trim().toUpperCase() == cleanSymbol)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<FifoSaleRecord> saleRecords = [];

    // 3. FIFO ile satışları ilk lotlardan başlayarak düş
    for (final sale in satisTransactions) {
      double neededQty = sale.quantity;
      double saleCost = 0.0;
      final List<FifoConsumption> consumptions = [];

      for (final lot in lots) {
        if (neededQty <= 0.000001) break;
        if (lot.remainingQuantity <= 0.000001) continue;

        final takeQty = lot.remainingQuantity >= neededQty
            ? neededQty
            : lot.remainingQuantity;

        lot.remainingQuantity -= takeQty;
        neededQty -= takeQty;
        final costFromLot = takeQty * lot.purchasePrice;
        saleCost += costFromLot;

        consumptions.add(
          FifoConsumption(
            lot: lot,
            quantityConsumed: takeQty,
            unitCost: lot.purchasePrice,
          ),
        );
      }

      // Satış maliyeti ve gerçekleşen kâr hesabı
      final unitCost = sale.quantity > 0 ? (saleCost / sale.quantity) : 0.0;
      final totalRevenue = sale.quantity * sale.price;
      final realizedProfit = totalRevenue - saleCost;
      final realizedProfitPercent =
          saleCost > 0 ? ((totalRevenue - saleCost) / saleCost) * 100 : 0.0;

      saleRecords.add(
        FifoSaleRecord(
          transaction: sale,
          totalSaleCost: saleCost,
          unitCost: unitCost,
          realizedProfit: realizedProfit,
          realizedProfitPercent: realizedProfitPercent,
          consumptions: consumptions,
        ),
      );
    }

    return FifoResult(
      symbol: cleanSymbol,
      allLots: lots,
      saleRecords: saleRecords,
    );
  }

  /// Belirli bir satış miktarı için anlık FIFO maliyetini hesaplar (satış ekranında kullanıcıya maliyet önermek için).
  static FifoCostEstimation estimateSaleCost(
    Portfolio portfolio,
    String symbol,
    double saleQuantity, {
    PortfolioAsset? assetFallback,
  }) {
    if (saleQuantity <= 0) {
      return FifoCostEstimation(
        totalCost: 0.0,
        unitCost: 0.0,
        quantity: 0.0,
        hasEnoughHoldings: true,
        plannedConsumptions: [],
      );
    }

    final currentResult = calculate(
      portfolio,
      symbol,
      assetFallback: assetFallback,
    );

    double neededQty = saleQuantity;
    double totalCost = 0.0;
    final List<FifoConsumption> consumptions = [];

    for (final lot in currentResult.allLots) {
      if (neededQty <= 0.000001) break;
      if (lot.remainingQuantity <= 0.000001) continue;

      final takeQty = lot.remainingQuantity >= neededQty
          ? neededQty
          : lot.remainingQuantity;

      neededQty -= takeQty;
      totalCost += takeQty * lot.purchasePrice;

      consumptions.add(
        FifoConsumption(
          lot: lot,
          quantityConsumed: takeQty,
          unitCost: lot.purchasePrice,
        ),
      );
    }

    final hasEnoughHoldings = neededQty <= 0.000001;
    final unitCost = saleQuantity > 0 ? (totalCost / saleQuantity) : 0.0;

    return FifoCostEstimation(
      totalCost: totalCost,
      unitCost: unitCost,
      quantity: saleQuantity,
      hasEnoughHoldings: hasEnoughHoldings,
      plannedConsumptions: consumptions,
    );
  }
}
