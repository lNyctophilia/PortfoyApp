import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../services/market_data_service.dart';
import '../services/storage_service.dart';
import '../utils/fifo_calculator.dart';

class PortfolioProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Portfolio> _portfolios = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  AssetCategory? _selectedCategoryFilter;
  bool _showNetValues = true;

  bool get isRefreshing => _isRefreshing;
  bool get showNetValues => _showNetValues;

  List<Portfolio> get portfolios {
    if (_selectedCategoryFilter == null) {
      return _portfolios;
    }
    return _portfolios.where((portfolio) {
      return portfolio.assets.any((a) => a.category == _selectedCategoryFilter);
    }).toList();
  }

  List<Portfolio> get rawPortfolios => _portfolios;
  bool get isLoading => _isLoading;
  AssetCategory? get selectedCategoryFilter => _selectedCategoryFilter;

  List<Portfolio> get visiblePortfolios =>
      _portfolios.where((p) => p.isVisible).toList();

  // Yalnızca görünür portföylerin toplam değerleri
  double get grandTotalValue =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.totalValue);

  double get grandTotalCost =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.totalCost);

  double get grandTotalProfit => grandTotalValue - grandTotalCost;

  double get grandTotalWithholdingTax =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.totalWithholdingTax);

  double get grandTotalNetProfit =>
      grandTotalProfit - grandTotalWithholdingTax;

  double get grandTotalRealizedProfit =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.realizedProfit);

  double get grandTotalRealizedWithholdingTax =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.realizedWithholdingTax);

  double get grandTotalNetRealizedProfit =>
      visiblePortfolios.fold(0.0, (sum, p) => sum + p.netRealizedProfit);

  double get grandTotalProfitPercent =>
      grandTotalCost > 0 ? (grandTotalProfit / grandTotalCost) * 100 : 0.0;

  double get grandTotalNetProfitPercent =>
      grandTotalCost > 0 ? (grandTotalNetProfit / grandTotalCost) * 100 : 0.0;

  double get grandTotalNetValue =>
      grandTotalValue - grandTotalWithholdingTax;

  int get grandTotalAssetCount =>
      visiblePortfolios.fold(0, (sum, p) => sum + p.assetCount);

  int get grandTotalFundCount =>
      visiblePortfolios.fold(0, (sum, p) => sum + p.fundCount);

  PortfolioProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _storageService.loadSettings();
    _showNetValues = settings['showNetValuesWithholdingTax'] ?? true;

    await MarketDataService.ensureLogoCacheLoaded();
    _portfolios = await _storageService.loadPortfolios();
    _backfillMissingAssetIcons();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setShowNetValues(bool value) async {
    if (_showNetValues == value) return;
    _showNetValues = value;
    notifyListeners();
    await _storageService.saveSettings({
      'showNetValuesWithholdingTax': _showNetValues,
    });
  }

  void _backfillMissingAssetIcons() {
    bool hasChanges = false;
    final updatedPortfolios = <Portfolio>[];

    for (final portfolio in _portfolios) {
      final updatedAssets = <PortfolioAsset>[];
      for (final asset in portfolio.assets) {
        if (asset.iconUrl == null || asset.iconUrl!.trim().isEmpty) {
          final matchingTx = portfolio.transactions.firstWhere(
            (t) =>
                t.symbol.toUpperCase() == asset.symbol.toUpperCase() &&
                t.iconUrl != null &&
                t.iconUrl!.trim().isNotEmpty,
            orElse: () => PortfolioTransaction(
              id: '',
              portfolioId: '',
              type: TransactionType.alis,
              symbol: '',
              name: '',
              category: asset.category,
              date: DateTime.now(),
              quantity: 0,
              price: 0,
            ),
          );

          final resolvedIcon = (matchingTx.iconUrl != null && matchingTx.iconUrl!.isNotEmpty)
              ? matchingTx.iconUrl
              : MarketDataService.getKnownAssetLogo(asset.symbol, asset.category, asset.name);

          if (resolvedIcon != null && resolvedIcon.isNotEmpty) {
            updatedAssets.add(asset.copyWith(iconUrl: resolvedIcon));
            MarketDataService.cacheLogo(asset.symbol, resolvedIcon);
            hasChanges = true;
            continue;
          }
        }
        updatedAssets.add(asset);
      }
      updatedPortfolios.add(portfolio.copyWith(assets: updatedAssets));
    }

    if (hasChanges) {
      _portfolios = updatedPortfolios;
      _storageService.savePortfolios(_portfolios);
    }
  }


  void setCategoryFilter(AssetCategory? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addPortfolio({
    required String name,
    String description = '',
  }) async {
    final newPortfolio = Portfolio(
      id: 'port_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
      assets: [],
    );

    _portfolios.insert(0, newPortfolio);
    await _storageService.savePortfolios(_portfolios);
    notifyListeners();
  }

  Future<void> updatePortfolio({
    required String id,
    required String name,
    String description = '',
  }) async {
    final index = _portfolios.indexWhere((p) => p.id == id);
    if (index != -1) {
      _portfolios[index] = _portfolios[index].copyWith(
        name: name,
        description: description,
      );
      await _storageService.savePortfolios(_portfolios);
      notifyListeners();
    }
  }

  Future<void> togglePortfolioVisibility(String id) async {
    final index = _portfolios.indexWhere((p) => p.id == id);
    if (index != -1) {
      _portfolios[index] = _portfolios[index].copyWith(
        isVisible: !_portfolios[index].isVisible,
      );
      await _storageService.savePortfolios(_portfolios);
      notifyListeners();
    }
  }

  Future<void> deletePortfolio(String id) async {
    _portfolios.removeWhere((p) => p.id == id);
    await _storageService.savePortfolios(_portfolios);
    notifyListeners();
  }

  Future<void> addAsset(String portfolioId, PortfolioAsset asset) async {
    final index = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (index != -1) {
      final updatedAssets = List<PortfolioAsset>.from(_portfolios[index].assets)
        ..add(asset);
      _portfolios[index] = _portfolios[index].copyWith(assets: updatedAssets);
      await _storageService.savePortfolios(_portfolios);
      notifyListeners();
      refreshPortfolioPrices(portfolioId);
    }
  }

  Future<void> updateAsset(String portfolioId, PortfolioAsset updatedAsset) async {
    final pIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (pIndex != -1) {
      final assets = List<PortfolioAsset>.from(_portfolios[pIndex].assets);
      final aIndex = assets.indexWhere((a) => a.id == updatedAsset.id);
      if (aIndex != -1) {
        assets[aIndex] = updatedAsset;
        _portfolios[pIndex] = _portfolios[pIndex].copyWith(assets: assets);
        await _storageService.savePortfolios(_portfolios);
        notifyListeners();
        refreshPortfolioPrices(portfolioId);
      }
    }
  }

  Future<void> deleteAsset(String portfolioId, String assetId) async {
    final pIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (pIndex != -1) {
      final assets = List<PortfolioAsset>.from(_portfolios[pIndex].assets)
        ..removeWhere((a) => a.id == assetId);
      _portfolios[pIndex] = _portfolios[pIndex].copyWith(assets: assets);
      await _storageService.savePortfolios(_portfolios);
      notifyListeners();
      refreshPortfolioPrices(portfolioId);
    }
  }

  Future<void> addTransaction(
    String portfolioId,
    PortfolioTransaction transaction, {
    bool updateHoldings = true,
  }) async {
    final pIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (pIndex == -1) return;

    final portfolio = _portfolios[pIndex];
    final updatedTransactions = [transaction, ...portfolio.transactions];
    List<PortfolioAsset> updatedAssets = List.from(portfolio.assets);

    if (updateHoldings) {
      if (transaction.type == TransactionType.satis) {
        // Satış işleminde FIFO ile varlığı ve kalan maliyeti güncelle
        final aIndex = updatedAssets.indexWhere(
          (a) =>
              (transaction.assetId != null && a.id == transaction.assetId) ||
              a.symbol.toUpperCase() == transaction.symbol.toUpperCase(),
        );

        if (aIndex != -1) {
          final target = updatedAssets[aIndex];
          final tempPortfolio = portfolio.copyWith(
            transactions: updatedTransactions,
            assets: updatedAssets,
          );
          final fifoResult = FifoCalculator.calculate(
            tempPortfolio,
            transaction.symbol,
            assetFallback: target,
          );

          if (fifoResult.remainingQuantity <= 0.00001) {
            updatedAssets.removeAt(aIndex);
          } else {
            updatedAssets[aIndex] = target.copyWith(
              quantity: fifoResult.remainingQuantity,
              purchasePrice: fifoResult.averageRemainingCost > 0
                  ? fifoResult.averageRemainingCost
                  : target.purchasePrice,
            );
          }
        }
      } else if (transaction.type == TransactionType.alis) {
        // Alış işleminde varlık ekle veya miktar/maliyet güncelle
        final aIndex = updatedAssets.indexWhere(
          (a) => a.symbol.toUpperCase() == transaction.symbol.toUpperCase(),
        );

        if (aIndex != -1) {
          final existing = updatedAssets[aIndex];
          final newQty = existing.quantity + transaction.quantity;
          final newAvgCost = newQty > 0
              ? ((existing.purchasePrice * existing.quantity) +
                      (transaction.price * transaction.quantity)) /
                  newQty
              : transaction.price;

          updatedAssets[aIndex] = existing.copyWith(
            quantity: newQty,
            purchasePrice: newAvgCost,
            currentPrice: transaction.currentPrice ?? existing.currentPrice,
            iconUrl: transaction.iconUrl ?? existing.iconUrl,
            dailyChangePercent: transaction.dailyChangePercent ?? existing.dailyChangePercent,
            weeklyChangePercent: transaction.weeklyChangePercent ?? existing.weeklyChangePercent,
            monthlyChangePercent: transaction.monthlyChangePercent ?? existing.monthlyChangePercent,
            threeMonthlyChangePercent: transaction.threeMonthlyChangePercent ?? existing.threeMonthlyChangePercent,
            sixMonthlyChangePercent: transaction.sixMonthlyChangePercent ?? existing.sixMonthlyChangePercent,
            yearlyChangePercent: transaction.yearlyChangePercent ?? existing.yearlyChangePercent,
          );
        } else {
          updatedAssets.add(
            PortfolioAsset(
              id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
              name: transaction.name,
              symbol: transaction.symbol.toUpperCase(),
              category: transaction.category,
              purchaseDate: transaction.date,
              purchasePrice: transaction.price,
              quantity: transaction.quantity,
              currentPrice: transaction.currentPrice ?? transaction.price,
              iconUrl: transaction.iconUrl,
              dailyChangePercent: transaction.dailyChangePercent ?? 0.0,
              weeklyChangePercent: transaction.weeklyChangePercent ?? 0.0,
              monthlyChangePercent: transaction.monthlyChangePercent ?? 0.0,
              threeMonthlyChangePercent: transaction.threeMonthlyChangePercent ?? 0.0,
              sixMonthlyChangePercent: transaction.sixMonthlyChangePercent ?? 0.0,
              yearlyChangePercent: transaction.yearlyChangePercent ?? 0.0,
            ),
          );
        }
      }
    }

    _portfolios[pIndex] = portfolio.copyWith(
      transactions: updatedTransactions,
      assets: updatedAssets,
    );
    await _storageService.savePortfolios(_portfolios);
    notifyListeners();
    refreshPortfolioPrices(portfolioId);
  }

  Future<void> deleteTransaction(
    String portfolioId,
    String transactionId, {
    bool reverseHoldings = true,
  }) async {
    final pIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (pIndex == -1) return;

    final portfolio = _portfolios[pIndex];
    final tIndex =
        portfolio.transactions.indexWhere((t) => t.id == transactionId);
    if (tIndex == -1) return;

    final transaction = portfolio.transactions[tIndex];
    final updatedTransactions =
        List<PortfolioTransaction>.from(portfolio.transactions)
          ..removeAt(tIndex);
    List<PortfolioAsset> updatedAssets = List.from(portfolio.assets);

    if (reverseHoldings) {
      final cleanSymbol = transaction.symbol.toUpperCase();
      final aIndex = updatedAssets.indexWhere(
        (a) =>
            (transaction.assetId != null && a.id == transaction.assetId) ||
            a.symbol.toUpperCase() == cleanSymbol,
      );

      final tempPortfolio = portfolio.copyWith(
        transactions: updatedTransactions,
        assets: updatedAssets,
      );
      final fifoResult = FifoCalculator.calculate(
        tempPortfolio,
        cleanSymbol,
        assetFallback: aIndex != -1 ? updatedAssets[aIndex] : null,
      );

      if (fifoResult.remainingQuantity > 0.00001) {
        if (aIndex != -1) {
          updatedAssets[aIndex] = updatedAssets[aIndex].copyWith(
            quantity: fifoResult.remainingQuantity,
            purchasePrice: fifoResult.averageRemainingCost > 0
                ? fifoResult.averageRemainingCost
                : updatedAssets[aIndex].purchasePrice,
          );
        } else {
          updatedAssets.add(
            PortfolioAsset(
              id: transaction.assetId ??
                  'asset_${DateTime.now().millisecondsSinceEpoch}',
              name: transaction.name,
              symbol: cleanSymbol,
              category: transaction.category,
              purchaseDate: transaction.date,
              purchasePrice: fifoResult.averageRemainingCost > 0
                  ? fifoResult.averageRemainingCost
                  : (transaction.costPrice > 0
                      ? transaction.costPrice
                      : transaction.price),
              quantity: fifoResult.remainingQuantity,
              currentPrice: transaction.price,
              iconUrl: transaction.iconUrl,
            ),
          );
        }
      } else {
        if (aIndex != -1) {
          updatedAssets.removeAt(aIndex);
        }
      }
    }

    _portfolios[pIndex] = portfolio.copyWith(
      transactions: updatedTransactions,
      assets: updatedAssets,
    );
    await _storageService.savePortfolios(_portfolios);
    notifyListeners();
    refreshPortfolioPrices(portfolioId);
  }

  Future<void> refreshAllPortfolios() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      final cache = <String, MarketAssetInfo?>{};
      final updatedPortfolios = <Portfolio>[];

      for (final portfolio in _portfolios) {
        final updatedAssets = <PortfolioAsset>[];
        for (final asset in portfolio.assets) {
          final cacheKey = '${asset.category.name}_${asset.symbol.toUpperCase()}';
          MarketAssetInfo? info;
          if (cache.containsKey(cacheKey)) {
            info = cache[cacheKey];
          } else {
            info = await MarketDataService.fetchAssetData(
              category: asset.category,
              symbol: asset.symbol,
              purchaseDate: asset.purchaseDate,
            );
            cache[cacheKey] = info;
          }

          if (info != null && info.currentPrice > 0) {
            if (info.iconUrl != null && info.iconUrl!.isNotEmpty) {
              MarketDataService.cacheLogo(asset.symbol, info.iconUrl!);
            }
            updatedAssets.add(
              asset.copyWith(
                name: info.name.isNotEmpty ? info.name : asset.name,
                currentPrice: info.currentPrice,
                iconUrl: info.iconUrl ?? asset.iconUrl,
                dailyChangePercent: info.dailyChangePercent,
                weeklyChangePercent: info.weeklyChangePercent,
                monthlyChangePercent: info.monthlyChangePercent,
                threeMonthlyChangePercent: info.threeMonthlyChangePercent,
                sixMonthlyChangePercent: info.sixMonthlyChangePercent,
                yearlyChangePercent: info.yearlyChangePercent,
              ),
            );
          } else {
            updatedAssets.add(asset);
          }
        }
        updatedPortfolios.add(portfolio.copyWith(assets: updatedAssets));
      }

      _portfolios = updatedPortfolios;
      await _storageService.savePortfolios(_portfolios);
    } catch (_) {
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshPortfolioPrices(String portfolioId) async {
    final pIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (pIndex == -1) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final portfolio = _portfolios[pIndex];
      final updatedAssets = <PortfolioAsset>[];

      for (final asset in portfolio.assets) {
        final info = await MarketDataService.fetchAssetData(
          category: asset.category,
          symbol: asset.symbol,
          purchaseDate: asset.purchaseDate,
        );

        if (info != null && info.currentPrice > 0) {
          if (info.iconUrl != null && info.iconUrl!.isNotEmpty) {
            MarketDataService.cacheLogo(asset.symbol, info.iconUrl!);
          }
          updatedAssets.add(
            asset.copyWith(
              name: info.name.isNotEmpty ? info.name : asset.name,
              currentPrice: info.currentPrice,
              purchasePrice: (asset.purchasePrice == 0 && info.purchaseDatePrice != null)
                  ? info.purchaseDatePrice!
                  : asset.purchasePrice,
              iconUrl: info.iconUrl ?? asset.iconUrl,
              dailyChangePercent: info.dailyChangePercent,
              weeklyChangePercent: info.weeklyChangePercent,
              monthlyChangePercent: info.monthlyChangePercent,
              threeMonthlyChangePercent: info.threeMonthlyChangePercent,
              sixMonthlyChangePercent: info.sixMonthlyChangePercent,
              yearlyChangePercent: info.yearlyChangePercent,
            ),
          );
        } else {
          updatedAssets.add(asset);
        }
      }

      _portfolios[pIndex] = portfolio.copyWith(assets: updatedAssets);
      await _storageService.savePortfolios(_portfolios);
    } catch (_) {
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Portfolio? getPortfolioById(String id) {
    try {
      return _portfolios.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
