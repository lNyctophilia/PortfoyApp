import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../models/return_mode.dart';
import '../services/inflation_service.dart';
import '../services/market_data_service.dart';
import '../services/storage_service.dart';
import '../utils/fifo_calculator.dart';
import '../features/auth_gate/services/auth_gate_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<Portfolio>>? _portfoliosSubscription;
  StreamSubscription<Map<String, dynamic>?>? _settingsSubscription;
  bool _isLiveConnected = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;

  List<Portfolio> _portfolios = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  AssetCategory? _selectedCategoryFilter;
  bool _showNetValues = false;
  ReturnCalculationMode _returnMode = ReturnCalculationMode.brut;
  Map<String, double> _assetInflationRates = {};
  double _latestAnnualInflation = 0.0;
  PeriodInflationData? _periodInflation;
  bool _isLoadingInflation = false;

  bool get isRefreshing => _isRefreshing;
  bool get showNetValues => _showNetValues;
  ReturnCalculationMode get returnMode => _returnMode;
  Map<String, double> get assetInflationRates => _assetInflationRates;
  double get latestAnnualInflation => _latestAnnualInflation;
  PeriodInflationData? get periodInflation => _periodInflation;
  bool get isLoadingInflation => _isLoadingInflation;
  User? get currentUser => _authService.currentUser;
  bool get isSignedIn => _authService.isSignedIn;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  bool get isLiveConnected => _isLiveConnected && isSignedIn;

  double getAssetInflation(String assetId) =>
      _assetInflationRates[assetId] ?? 0.0;

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

  // Enflasyona göre düzeltilmiş genel toplamlar (Reel Getiri)
  double get grandTotalRealCost => visiblePortfolios.fold(
        0.0,
        (sum, p) => sum + p.realCost(_assetInflationRates),
      );

  double get grandTotalRealProfit => visiblePortfolios.fold(
        0.0,
        (sum, p) => sum + p.realTotalProfit(_assetInflationRates),
      );

  double get grandTotalRealProfitPercent {
    final cost = grandTotalRealCost;
    if (cost <= 0) return 0.0;
    return (grandTotalRealProfit / cost) * 100.0;
  }

  // Seçili getiri moduna duyarlı genel gösterim değerleri
  double get displayGrandTotalValue {
    switch (_returnMode) {
      case ReturnCalculationMode.brut:
        return grandTotalValue;
      case ReturnCalculationMode.net:
      case ReturnCalculationMode.reel:
        return grandTotalNetValue;
    }
  }

  double get displayGrandTotalProfit {
    switch (_returnMode) {
      case ReturnCalculationMode.brut:
        return grandTotalProfit;
      case ReturnCalculationMode.net:
      case ReturnCalculationMode.reel:
        return grandTotalNetProfit;
    }
  }

  double get displayGrandTotalProfitPercent {
    switch (_returnMode) {
      case ReturnCalculationMode.brut:
        return grandTotalProfitPercent;
      case ReturnCalculationMode.net:
        return grandTotalNetProfitPercent;
      case ReturnCalculationMode.reel:
        return grandTotalRealProfitPercent;
    }
  }

  int get grandTotalAssetCount =>
      visiblePortfolios.fold(0, (sum, p) => sum + p.assetCount);

  int get grandTotalFundCount =>
      visiblePortfolios.fold(0, (sum, p) => sum + p.fundCount);

  PortfolioProvider() {
    _initAuthListener();
    loadData();
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await syncWithCloud();
        _startRealtimeSubscriptions(user.uid);
      } else {
        _cancelRealtimeSubscriptions();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelRealtimeSubscriptions();
    super.dispose();
  }

  Future<void> _persistPortfolios() async {
    await _storageService.savePortfolios(_portfolios);
    final user = _authService.currentUser;
    if (user != null && _firestoreService.isFirebaseAvailable) {
      try {
        await _firestoreService.savePortfolios(user.uid, _portfolios);
        _lastSyncTime = DateTime.now();
        _syncError = null;
        notifyListeners();
      } catch (e) {
        debugPrint('Bulut senkronizasyon hatası: $e');
        _syncError = 'Bulut senkronizasyon hatası: $e';
        notifyListeners();
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _syncError = null;
      notifyListeners();
      final userCred = await _authService.signInWithGoogle();
      if (userCred?.user != null) {
        final user = userCred!.user!;
        await _firestoreService.markUserApproved(user);
        await AuthGateService.instance.unlockByGoogleUser(user.uid);
        await syncWithCloud();
        _startRealtimeSubscriptions(user.uid);
      }
    } catch (e) {
      _syncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _cancelRealtimeSubscriptions();
      _syncError = null;
      await _authService.signOut();
      await AuthGateService.instance.clearGoogleApproval();
      notifyListeners();
    } catch (e) {
      _syncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncWithCloud() async {
    final user = _authService.currentUser;
    if (user == null || !_firestoreService.isFirebaseAvailable) return;

    // Veritabanında kullanıcıyı onaylı olarak kaydet ve kapıyı aç
    await _firestoreService.markUserApproved(user);
    await AuthGateService.instance.unlockByGoogleUser(user.uid);

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final cloudPortfolios = await _firestoreService.loadPortfolios(user.uid);

      if (cloudPortfolios.isNotEmpty) {
        final cloudIds = cloudPortfolios.map((p) => p.id).toSet();
        final localOnly = _portfolios.where((p) => !cloudIds.contains(p.id)).toList();
        if (localOnly.isNotEmpty) {
          _portfolios = [...cloudPortfolios, ...localOnly];
          await _firestoreService.savePortfolios(user.uid, _portfolios);
        } else {
          _portfolios = cloudPortfolios;
        }
        await _storageService.savePortfolios(_portfolios);
        _backfillMissingAssetIcons();
      } else if (_portfolios.isNotEmpty) {
        await _firestoreService.savePortfolios(user.uid, _portfolios);
      }

      final cloudSettings = await _firestoreService.loadSettings(user.uid);
      if (cloudSettings != null) {
        final modeStr = cloudSettings['returnCalculationMode'] as String?;
        if (modeStr != null) {
          _returnMode = ReturnCalculationMode.values.firstWhere(
            (e) => e.name == modeStr,
            orElse: () => _returnMode,
          );
        }
        if (cloudSettings.containsKey('showNetValuesWithholdingTax')) {
          _showNetValues = cloudSettings['showNetValuesWithholdingTax'] as bool;
        }
      } else {
        await _firestoreService.saveSettings(user.uid, {
          'returnCalculationMode': _returnMode.name,
          'showNetValuesWithholdingTax': _showNetValues,
        });
      }

      _lastSyncTime = DateTime.now();
      _isLiveConnected = true;
    } catch (e) {
      debugPrint('Bulut senkronizasyon hatası: $e');
      _syncError = 'Senkronizasyon hatası: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Canlı Firestore portföy ve ayar dinleyicilerini başlatır
  void _startRealtimeSubscriptions(String uid) {
    _cancelRealtimeSubscriptions();

    _portfoliosSubscription = _firestoreService.portfoliosStream(uid).listen(
      (cloudPortfolios) {
        _onPortfoliosSnapshot(cloudPortfolios);
      },
      onError: (e) {
        debugPrint('Canlı portföy akışında hata: $e');
        _isLiveConnected = false;
        _syncError = 'Canlı bağlantı hatası: $e';
        notifyListeners();
      },
    );

    _settingsSubscription = _firestoreService.settingsStream(uid).listen(
      (cloudSettings) {
        _onSettingsSnapshot(cloudSettings);
      },
      onError: (e) {
        debugPrint('Canlı ayar akışında hata: $e');
      },
    );

    _isLiveConnected = true;
    notifyListeners();
  }

  /// Canlı Firestore dinleyicilerini durdurur
  void _cancelRealtimeSubscriptions() {
    _portfoliosSubscription?.cancel();
    _portfoliosSubscription = null;
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _isLiveConnected = false;
  }

  /// Buluttan anlık portföy verisi geldiğinde tetiklenir
  void _onPortfoliosSnapshot(List<Portfolio> cloudPortfolios) {
    if (_isSyncing) return;

    final mergedPortfolios = <Portfolio>[];
    for (final cp in cloudPortfolios) {
      final existingPortfolio = _portfolios.firstWhere(
        (p) => p.id == cp.id,
        orElse: () => cp,
      );

      final updatedAssets = cp.assets.map((asset) {
        final localAsset = existingPortfolio.assets.firstWhere(
          (a) => a.id == asset.id,
          orElse: () => asset,
        );

        // Fiyat koruması: Buluttan gelen 0 ise ama yerelde piyasa fiyatı çekilmişse koru
        if (asset.currentPrice <= 0 && localAsset.currentPrice > 0) {
          return asset.copyWith(
            currentPrice: localAsset.currentPrice,
            iconUrl: asset.iconUrl ?? localAsset.iconUrl,
            dailyChangePercent: localAsset.dailyChangePercent,
            weeklyChangePercent: localAsset.weeklyChangePercent,
            monthlyChangePercent: localAsset.monthlyChangePercent,
            threeMonthlyChangePercent: localAsset.threeMonthlyChangePercent,
            sixMonthlyChangePercent: localAsset.sixMonthlyChangePercent,
            yearlyChangePercent: localAsset.yearlyChangePercent,
          );
        }
        return asset;
      }).toList();

      mergedPortfolios.add(cp.copyWith(assets: updatedAssets));
    }

    // Portföyleri oluşturulma tarihine göre en yeni en üstte sırala
    mergedPortfolios.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _portfolios = mergedPortfolios;
    _lastSyncTime = DateTime.now();
    _syncError = null;
    _isLiveConnected = true;

    _storageService.savePortfolios(_portfolios);
    _backfillMissingAssetIcons();

    if (_returnMode == ReturnCalculationMode.reel) {
      refreshInflationData();
    }

    notifyListeners();
  }

  /// Buluttan anlık ayar verisi geldiğinde tetiklenir
  void _onSettingsSnapshot(Map<String, dynamic>? cloudSettings) {
    if (cloudSettings == null) return;
    bool changed = false;

    final modeStr = cloudSettings['returnCalculationMode'] as String?;
    if (modeStr != null) {
      final newMode = ReturnCalculationMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => _returnMode,
      );
      if (newMode != _returnMode) {
        _returnMode = newMode;
        changed = true;
      }
    }

    if (cloudSettings.containsKey('showNetValuesWithholdingTax')) {
      final newNet = cloudSettings['showNetValuesWithholdingTax'] as bool;
      if (newNet != _showNetValues) {
        _showNetValues = newNet;
        changed = true;
      }
    }

    if (changed) {
      _storageService.saveSettings({
        'returnCalculationMode': _returnMode.name,
        'showNetValuesWithholdingTax': _showNetValues,
      });
      if (_returnMode == ReturnCalculationMode.reel) {
        refreshInflationData();
      }
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _storageService.loadSettings();
    final modeStr = settings['returnCalculationMode'] as String?;
    if (modeStr != null) {
      _returnMode = ReturnCalculationMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => ReturnCalculationMode.brut,
      );
    } else {
      final netVal = settings['showNetValuesWithholdingTax'] ?? false;
      _returnMode =
          netVal ? ReturnCalculationMode.net : ReturnCalculationMode.brut;
    }
    _showNetValues = _returnMode == ReturnCalculationMode.net;

    await MarketDataService.ensureLogoCacheLoaded();
    _portfolios = await _storageService.loadPortfolios();
    _backfillMissingAssetIcons();
    if (_returnMode == ReturnCalculationMode.reel) {
      refreshInflationData();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setReturnMode(ReturnCalculationMode mode) async {
    if (_returnMode == mode) return;
    _returnMode = mode;
    _showNetValues = mode == ReturnCalculationMode.net;
    notifyListeners();


    await _storageService.saveSettings({
      'returnCalculationMode': _returnMode.name,
      'showNetValuesWithholdingTax': _showNetValues,
    });

    final user = _authService.currentUser;
    if (user != null && _firestoreService.isFirebaseAvailable) {
      _firestoreService.saveSettings(user.uid, {
        'returnCalculationMode': _returnMode.name,
        'showNetValuesWithholdingTax': _showNetValues,
      });
    }

    if (_returnMode == ReturnCalculationMode.reel) {
      await refreshInflationData();
    }
  }

  Future<void> refreshInflationData() async {
    _isLoadingInflation = true;
    notifyListeners();

    try {
      await InflationService.ensureCacheLoaded();
      _periodInflation =
          await InflationService.getPeriodInflationRates(forceRefresh: true);
      _latestAnnualInflation = _periodInflation?.yearly ??
          await InflationService.getLatestAnnualInflation();

      final rates = <String, double>{};
      for (final portfolio in _portfolios) {
        for (final asset in portfolio.assets) {
          final txs = portfolio.transactions
              .where((t) =>
                  t.type == TransactionType.alis &&
                  (t.assetId == asset.id ||
                      t.symbol.toUpperCase() == asset.symbol.toUpperCase()))
              .toList();
          DateTime buyDate = asset.purchaseDate;
          if (txs.isNotEmpty) {
            txs.sort((a, b) => a.date.compareTo(b.date));
            buyDate = txs.first.date;
          }
          final rate = await InflationService.getInflationSince(buyDate);
          rates[asset.id] = rate;
        }
      }
      _assetInflationRates = rates;
    } catch (_) {
    } finally {
      _isLoadingInflation = false;
      notifyListeners();
    }
  }

  Future<void> setShowNetValues(bool value) async {
    await setReturnMode(value ? ReturnCalculationMode.net : ReturnCalculationMode.brut);
  } /*

    notifyListeners();


    });
  }

  */
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
      _persistPortfolios();
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
    await _persistPortfolios();
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
      await _persistPortfolios();
      notifyListeners();
    }
  }

  Future<void> togglePortfolioVisibility(String id) async {
    final index = _portfolios.indexWhere((p) => p.id == id);
    if (index != -1) {
      _portfolios[index] = _portfolios[index].copyWith(
        isVisible: !_portfolios[index].isVisible,
      );
      await _persistPortfolios();
      notifyListeners();
    }
  }

  Future<void> deletePortfolio(String id) async {
    _portfolios.removeWhere((p) => p.id == id);
    await _persistPortfolios();
    notifyListeners();
  }

  Future<void> addAsset(String portfolioId, PortfolioAsset asset) async {
    final index = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (index != -1) {
      final updatedAssets = List<PortfolioAsset>.from(_portfolios[index].assets)
        ..add(asset);
      _portfolios[index] = _portfolios[index].copyWith(assets: updatedAssets);
      await _persistPortfolios();
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
        await _persistPortfolios();
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
      await _persistPortfolios();
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
    await _persistPortfolios();
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
    await _persistPortfolios();
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
      await _persistPortfolios();
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
      await _persistPortfolios();
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
