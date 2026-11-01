import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../services/asset_catalog_service.dart';
import '../services/market_data_service.dart';
import '../theme/app_theme.dart';
import '../utils/fifo_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/asset_logo.dart';
import '../widgets/asset_symbol_autocomplete.dart';

class AddTransactionDialog extends StatefulWidget {
  final Portfolio portfolio;
  final PortfolioAsset? initialAsset;
  final TransactionType initialType;
  final Function(PortfolioTransaction transaction, bool updateHoldings) onSave;
  final bool isFullScreen;

  const AddTransactionDialog({
    super.key,
    required this.portfolio,
    this.initialAsset,
    this.initialType = TransactionType.alis,
    required this.onSave,
    this.isFullScreen = false,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Alış solda, Satış sağda; varsayılan olarak Alış seçili
  TransactionType _selectedType = TransactionType.alis;

  // ALIŞ DURUMU DEĞİŞKENLERİ
  AssetCategory _alisCategory = AssetCategory.fon;
  late TextEditingController _alisSymbolController;
  late TextEditingController _alisNameController;
  late TextEditingController _alisQuantityController;
  late TextEditingController _alisPurchasePriceController;
  late TextEditingController _alisCurrentPriceController;
  late TextEditingController _alisDailyChangeController;
  late TextEditingController _alisWeeklyChangeController;
  late TextEditingController _alisMonthlyChangeController;
  late TextEditingController _alisThreeMonthlyChangeController;
  late TextEditingController _alisSixMonthlyChangeController;
  late TextEditingController _alisYearlyChangeController;
  late DateTime _alisDate;
  DateTime? _alisEarliestDate;
  String? _alisIconUrl;
  String _alisLastSymbol = '';
  bool _isAlisPurchasePriceManual = false;
  bool _isAlisCurrentPriceManual = false;
  bool _isLoadingAlisMarketData = false;
  String? _alisMarketDataStatus;
  Timer? _alisDebounceTimer;

  // SATIŞ DURUMU DEĞİŞKENLERİ
  PortfolioAsset? _selectedExistingAsset;
  late TextEditingController _satisSymbolController;
  late TextEditingController _satisNameController;
  late TextEditingController _satisQuantityController;
  late TextEditingController _satisPriceController;
  late DateTime _satisDate;
  DateTime? _satisEarliestDate;
  String? _satisIconUrl;
  bool _isSatisPriceManual = false;
  bool _isLoadingSatisMarketData = false;
  String? _satisMarketDataStatus;

  @override
  void initState() {
    super.initState();

    // Alış Controller'ları
    _alisSymbolController = TextEditingController();
    _alisNameController = TextEditingController();
    _alisQuantityController = TextEditingController();
    _alisPurchasePriceController = TextEditingController();
    _alisCurrentPriceController = TextEditingController();
    _alisDailyChangeController = TextEditingController(text: '0.0');
    _alisWeeklyChangeController = TextEditingController(text: '0.0');
    _alisMonthlyChangeController = TextEditingController(text: '0.0');
    _alisThreeMonthlyChangeController = TextEditingController(text: '0.0');
    _alisSixMonthlyChangeController = TextEditingController(text: '0.0');
    _alisYearlyChangeController = TextEditingController(text: '0.0');
    _alisDate = DateTime.now();

    _alisQuantityController.addListener(() => setState(() {}));
    _alisPurchasePriceController.addListener(() => setState(() {}));
    _alisCurrentPriceController.addListener(() => setState(() {}));

    // Satış Controller'ları
    _satisSymbolController = TextEditingController();
    _satisNameController = TextEditingController();
    _satisQuantityController = TextEditingController();
    _satisPriceController = TextEditingController();
    _satisDate = DateTime.now();

    _satisQuantityController.addListener(() => setState(() {}));
    _satisPriceController.addListener(() => setState(() {}));

    _selectedType = widget.initialType;
    if (widget.initialAsset != null) {
      _selectExistingAsset(widget.initialAsset!);
    } else if (widget.portfolio.assets.isNotEmpty) {
      _selectExistingAsset(widget.portfolio.assets.first);
    }
  }

  @override
  void dispose() {
    _alisDebounceTimer?.cancel();
    _alisSymbolController.dispose();
    _alisNameController.dispose();
    _alisQuantityController.dispose();
    _alisPurchasePriceController.dispose();
    _alisCurrentPriceController.dispose();
    _alisDailyChangeController.dispose();
    _alisWeeklyChangeController.dispose();
    _alisMonthlyChangeController.dispose();
    _alisThreeMonthlyChangeController.dispose();
    _alisSixMonthlyChangeController.dispose();
    _alisYearlyChangeController.dispose();

    _satisSymbolController.dispose();
    _satisNameController.dispose();
    _satisQuantityController.dispose();
    _satisPriceController.dispose();
    super.dispose();
  }

  String _formatPrice(double val) {
    if (val == 0) return '0';
    if (val >= 100) return val.toStringAsFixed(2);
    if (val >= 1) return val.toStringAsFixed(4);
    return val.toStringAsFixed(6);
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString();
  }

  double _parseVal(String text) {
    var clean = text.trim();
    if (clean.isEmpty) return 0.0;
    if (clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(clean) ?? 0.0;
  }

  // --- ALIŞ FONKSİYONLARI ---
  void _clearAlisFetchedData() {
    _alisIconUrl = null;
    _alisNameController.clear();
    _alisCurrentPriceController.clear();
    _alisPurchasePriceController.clear();
    _alisDailyChangeController.text = '0.0';
    _alisWeeklyChangeController.text = '0.0';
    _alisMonthlyChangeController.text = '0.0';
    _alisThreeMonthlyChangeController.text = '0.0';
    _alisSixMonthlyChangeController.text = '0.0';
    _alisYearlyChangeController.text = '0.0';
    _alisMarketDataStatus = null;
    _alisEarliestDate = null;
  }

  void _onAlisSuggestionSelected(AssetSuggestion suggestion) {
    _alisDebounceTimer?.cancel();
    setState(() {
      _alisSymbolController.text = suggestion.symbol;
      _alisNameController.text = suggestion.name;
      _alisIconUrl = suggestion.iconUrl;
      _alisLastSymbol = suggestion.symbol;
      _alisMarketDataStatus = null;
    });
    _fetchAlisMarketData(suggestion.symbol, forceHistoricalPrice: true);
  }

  void _onAlisSymbolChanged(String text) {
    _alisDebounceTimer?.cancel();
    final clean = text.trim();
    if (clean.length < _alisLastSymbol.length || clean.isEmpty) {
      _clearAlisFetchedData();
    }
    _alisLastSymbol = clean;
    setState(() {});
    if (clean.length >= 3) {
      _alisDebounceTimer = Timer(const Duration(milliseconds: 900), () {
        _fetchAlisMarketData(clean, forceHistoricalPrice: true);
      });
    }
  }

  Future<void> _fetchAlisMarketData(String symbol,
      {bool forceHistoricalPrice = false}) async {
    if (symbol.trim().isEmpty) return;
    setState(() {
      _isLoadingAlisMarketData = true;
      _alisMarketDataStatus = null;
    });

    final info = await MarketDataService.fetchAssetData(
      category: _alisCategory,
      symbol: symbol,
      purchaseDate: _alisDate,
    );

    if (!mounted) return;
    if (_alisSymbolController.text.trim().toUpperCase() !=
        symbol.trim().toUpperCase()) {
      return;
    }

    setState(() {
      _isLoadingAlisMarketData = false;
      if (info != null) {
        _alisEarliestDate = info.earliestDate;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_alisDate.isAfter(today)) {
          _alisDate = today;
        } else if (_alisEarliestDate != null && _alisDate.isBefore(_alisEarliestDate!)) {
          _alisDate = _alisEarliestDate!;
        }
        _alisLastSymbol = symbol.trim();
        _alisIconUrl = info.iconUrl;
        _alisNameController.text = info.name;
        if (!_isAlisCurrentPriceManual) {
          _alisCurrentPriceController.text = _formatPrice(info.currentPrice);
        }
        _alisDailyChangeController.text = info.dailyChangePercent.toString();
        _alisWeeklyChangeController.text = info.weeklyChangePercent.toString();
        _alisMonthlyChangeController.text = info.monthlyChangePercent.toString();
        _alisThreeMonthlyChangeController.text =
            info.threeMonthlyChangePercent.toString();
        _alisSixMonthlyChangeController.text =
            info.sixMonthlyChangePercent.toString();
        _alisYearlyChangeController.text = info.yearlyChangePercent.toString();

        final hasManualPrice =
            _isAlisPurchasePriceManual || _isAlisCurrentPriceManual;

        if (!_isAlisPurchasePriceManual &&
            info.purchaseDatePrice != null &&
            (_alisPurchasePriceController.text.isEmpty ||
                _alisPurchasePriceController.text == '0' ||
                forceHistoricalPrice)) {
          _alisPurchasePriceController.text =
              _formatPrice(info.purchaseDatePrice!);
          _alisMarketDataStatus =
              '${Formatters.date(_alisDate)} tarihindeki fiyat (${_formatPrice(info.purchaseDatePrice!)} ₺) ve güncel veriler otomatik uygulandı.';
        } else if (hasManualPrice) {
          _alisMarketDataStatus =
              'Manuel girilen fiyatlar korundu. Anlık piyasa ve varlık verileri güncellendi.';
        } else {
          _alisMarketDataStatus =
              'Anlık fiyat (${_formatPrice(info.currentPrice)} ₺) ve varlık detayları güncellendi.';
        }
      } else {
        _alisMarketDataStatus =
            'Fiyat bilgisi bulunamadı. Lütfen manuel giriniz.';
      }
    });
  }

  Future<DateTime?> _showCalendarPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Color primaryColor,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime normLastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    if (normLastDate.isAfter(today)) {
      normLastDate = today;
    }

    DateTime normFirstDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
    if (normFirstDate.isAfter(normLastDate)) {
      normFirstDate = normLastDate;
    }

    DateTime selectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
    if (selectedDate.isBefore(normFirstDate)) {
      selectedDate = normFirstDate;
    } else if (selectedDate.isAfter(normLastDate)) {
      selectedDate = normLastDate;
    }

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: Dialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            child: SizedBox(
              width: 330,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: normFirstDate,
                      lastDate: normLastDate,
                      onDateChanged: (val) {
                        selectedDate = val;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            'İptal',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(selectedDate),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAlisDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_alisEarliestDate == null && _alisSymbolController.text.trim().isNotEmpty) {
      final info = await MarketDataService.fetchAssetData(
        category: _alisCategory,
        symbol: _alisSymbolController.text.trim(),
        purchaseDate: _alisDate,
      );
      if (info?.earliestDate != null) {
        _alisEarliestDate = info!.earliestDate;
      }
    }

    DateTime first = _alisEarliestDate ?? DateTime(2000, 1, 1);
    if (first.isAfter(today)) first = today;

    DateTime initial = _alisDate;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    if (!mounted) return;
    final picked = await _showCalendarPicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
      primaryColor: AppTheme.primary,
    );
    if (picked != null) {
      setState(() => _alisDate = picked);
      if (_alisSymbolController.text.trim().isNotEmpty) {
        _fetchAlisMarketData(_alisSymbolController.text.trim(),
            forceHistoricalPrice: true);
      }
    }
  }

  Widget _buildReadonlyPeriodBadge(String label, double val) {
    final isPos = val >= 0;
    final color = isPos ? AppTheme.profit : AppTheme.loss;
    final bg = isPos ? AppTheme.profitBg : AppTheme.lossBg;
    final sign = isPos ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPos
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '$sign${val.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SATIŞ FONKSİYONLARI ---
  void _selectExistingAsset(PortfolioAsset asset) {
    setState(() {
      _selectedExistingAsset = asset;
      _satisEarliestDate = null;
      _satisIconUrl = asset.iconUrl;
      _satisSymbolController.text = asset.symbol;
      _satisNameController.text = asset.name;
      _satisPriceController.text = _formatPrice(asset.currentPrice);
      _satisQuantityController.text = _formatNumber(asset.quantity);
      _isSatisPriceManual = false;
    });
    _fetchSatisMarketPriceForDate(
      symbol: asset.symbol,
      category: asset.category,
      date: _satisDate,
    );
  }

  Future<void> _fetchSatisMarketPriceForDate({
    required String symbol,
    required AssetCategory category,
    required DateTime date,
  }) async {
    final clean = symbol.trim().toUpperCase();
    if (clean.length < 2) return;

    setState(() {
      _isLoadingSatisMarketData = true;
      _satisMarketDataStatus = null;
    });

    final info = await MarketDataService.fetchAssetData(
      category: category,
      symbol: clean,
      purchaseDate: date,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingSatisMarketData = false;
      if (info != null) {
        _satisEarliestDate = info.earliestDate;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_satisDate.isAfter(today)) {
          _satisDate = today;
        } else if (_satisEarliestDate != null && _satisDate.isBefore(_satisEarliestDate!)) {
          _satisDate = _satisEarliestDate!;
        }

        if (info.iconUrl != null && info.iconUrl!.isNotEmpty) {
          _satisIconUrl = info.iconUrl;
        }
        final targetPrice = info.purchaseDatePrice ?? info.currentPrice;
        if (!_isSatisPriceManual && targetPrice > 0) {
          _satisPriceController.text = _formatPrice(targetPrice);
        }

        if (_isSatisPriceManual) {
          _satisMarketDataStatus =
              'Manuel girilen fiyat korundu. (${Formatters.date(date)} piyasa: ${_formatPrice(targetPrice)} ₺)';
        } else if (info.purchaseDatePrice != null) {
          _satisMarketDataStatus =
              '${Formatters.date(date)} tarihindeki fiyat (${_formatPrice(info.purchaseDatePrice!)} ₺) uygulandı.';
        } else {
          _satisMarketDataStatus =
              'Güncel piyasa fiyatı (${_formatPrice(info.currentPrice)} ₺) uygulandı.';
        }
      } else {
        _satisMarketDataStatus = 'Fiyat bilgisi bulunamadı.';
      }
    });
  }

  Future<void> _pickSatisDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_satisEarliestDate == null && _selectedExistingAsset != null) {
      final info = await MarketDataService.fetchAssetData(
        category: _selectedExistingAsset!.category,
        symbol: _selectedExistingAsset!.symbol,
        purchaseDate: _satisDate,
      );
      if (info?.earliestDate != null) {
        _satisEarliestDate = info!.earliestDate;
      }
    }

    DateTime first = _satisEarliestDate ?? DateTime(2000, 1, 1);
    if (first.isAfter(today)) first = today;

    DateTime initial = _satisDate;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    if (!mounted) return;
    final picked = await _showCalendarPicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
      primaryColor: AppTheme.profit,
    );
    if (picked != null) {
      setState(() => _satisDate = picked);
      if (_selectedExistingAsset != null) {
        _fetchSatisMarketPriceForDate(
          symbol: _selectedExistingAsset!.symbol,
          category: _selectedExistingAsset!.category,
          date: picked,
        );
      }
    }
  }

  void _saveTransaction() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedType == TransactionType.alis) {
      final pPrice = _parseVal(_alisPurchasePriceController.text);
      final qty = _parseVal(_alisQuantityController.text);
      final cPrice = _parseVal(_alisCurrentPriceController.text);

      final daily = _parseVal(_alisDailyChangeController.text);
      final weekly = _parseVal(_alisWeeklyChangeController.text);
      final monthly = _parseVal(_alisMonthlyChangeController.text);
      final threeMonthly = _parseVal(_alisThreeMonthlyChangeController.text);
      final sixMonthly = _parseVal(_alisSixMonthlyChangeController.text);
      final yearly = _parseVal(_alisYearlyChangeController.text);

      final tx = PortfolioTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        portfolioId: widget.portfolio.id,
        type: TransactionType.alis,
        symbol: _alisSymbolController.text.trim().toUpperCase(),
        name: _alisNameController.text.trim(),
        category: _alisCategory,
        date: _alisDate,
        quantity: qty,
        price: pPrice,
        costPrice: pPrice,
        currentPrice: cPrice > 0 ? cPrice : pPrice,
        iconUrl: _alisIconUrl,
        dailyChangePercent: daily,
        weeklyChangePercent: weekly,
        monthlyChangePercent: monthly,
        threeMonthlyChangePercent: threeMonthly,
        sixMonthlyChangePercent: sixMonthly,
        yearlyChangePercent: yearly,
      );

      // Satış veya alış fark etmeksizin otomatik portföye yansıtılır
      widget.onSave(tx, true);
      Navigator.of(context).pop();
    } else {
      if (_selectedExistingAsset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen satılacak bir varlık seçin.'),
            backgroundColor: AppTheme.loss,
          ),
        );
        return;
      }

      final qty = _parseVal(_satisQuantityController.text);
      final price = _parseVal(_satisPriceController.text);

      // FIFO mantığıyla en eski alımlardan başlayarak satış maliyeti ve gerçekleşen kâr hesaplanır
      final fifoEst = FifoCalculator.estimateSaleCost(
        widget.portfolio,
        _selectedExistingAsset!.symbol,
        qty,
        assetFallback: _selectedExistingAsset,
      );
      final cost = fifoEst.unitCost > 0
          ? fifoEst.unitCost
          : _selectedExistingAsset!.purchasePrice;

      final tx = PortfolioTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        portfolioId: widget.portfolio.id,
        type: TransactionType.satis,
        symbol: _satisSymbolController.text.trim().toUpperCase(),
        name: _satisNameController.text.trim(),
        category: _selectedExistingAsset!.category,
        date: _satisDate,
        quantity: qty,
        price: price,
        costPrice: cost,
        realizedProfit: (price - cost) * qty,
        assetId: _selectedExistingAsset!.id,
        iconUrl: _satisIconUrl ?? _selectedExistingAsset!.iconUrl,
        withholdingTaxRate: _selectedExistingAsset!.category == AssetCategory.fon
            ? _selectedExistingAsset!.effectiveWithholdingTaxRate
            : null,
      );

      // Satışta otomatik portföyden düşülür
      widget.onSave(tx, true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
        final isAlis = _selectedType == TransactionType.alis;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAlis ? 'Alış İşlemi Ekle' : 'Satış İşlemi Ekle',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text(
                widget.portfolio.name,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildFormContent(context, isAlis, isMobile: true),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 10 : 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopHeader(context, isAlis),
                  const SizedBox(height: 18),
                  _buildFormContent(context, isAlis, isMobile: isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isAlis) {
    return // BAŞLIK
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isAlis ? AppTheme.primary : AppTheme.profit)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAlis
                              ? Icons.shopping_cart_outlined
                              : Icons.monetization_on_outlined,
                          color:
                              isAlis ? AppTheme.primaryLight : AppTheme.profit,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alış / Satış İşlemi',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${widget.portfolio.name} • Alış veya Satış Kaydı',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
  }

  Widget _buildFormContent(BuildContext context, bool isAlis, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ÜST SEKME: ALIŞ (SOLDA) / SATIŞ (SAĞDA)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        // ALIŞ BUTONU (SOLDA)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(
                                  () => _selectedType = TransactionType.alis);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isAlis
                                    ? AppTheme.primary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isAlis
                                    ? Border.all(color: AppTheme.primary)
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: isAlis
                                        ? AppTheme.primaryLight
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      MediaQuery.sizeOf(context).width < 500
                                          ? 'Alış Yap'
                                          : 'Alış (Yeni / Ek Alım)',
                                      style: TextStyle(
                                        fontWeight: isAlis
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isAlis
                                            ? AppTheme.primaryLight
                                            : AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // SATIŞ BUTONU (SAĞDA)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(
                                  () => _selectedType = TransactionType.satis);
                              if (_selectedExistingAsset != null) {
                                _fetchSatisMarketPriceForDate(
                                  symbol: _selectedExistingAsset!.symbol,
                                  category: _selectedExistingAsset!.category,
                                  date: _satisDate,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isAlis
                                    ? AppTheme.profit.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: !isAlis
                                    ? Border.all(color: AppTheme.profit)
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: !isAlis
                                        ? AppTheme.profit
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      MediaQuery.sizeOf(context).width < 500
                                          ? 'Satış Yap'
                                          : 'Satış (Kâr / Zarar Gerçekleştir)',
                                      style: TextStyle(
                                        fontWeight: !isAlis
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: !isAlis
                                            ? AppTheme.profit
                                            : AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // İÇERİK: ALIŞ EKRANI (Şu anki Varlık Ekle Ekranı Gibi)
                  if (isAlis) ...[
                    _buildAlisForm(),
                  ] else ...[
                    // İÇERİK: SATIŞ EKRANI (Portföyde Olan Varlıklar)
                    _buildSatisForm(),
                  ],

                  const SizedBox(height: 24),

                  // AKSİYON BUTONLARI (Alt kısımdaki otomatik düşüş checkbox'ı tamamen kaldırıldı)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAlis ? AppTheme.primary : AppTheme.profit,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                        ),
                        onPressed: (!isAlis && widget.portfolio.assets.isEmpty)
                            ? null
                            : _saveTransaction,
                        icon: Icon(
                          isAlis
                              ? Icons.add_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isAlis ? 'Alışı Kaydet' : 'Satışı Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
      ],
    );
  }

  // ==========================================
  // ALIŞ FORMU (VARLIK EKLEME ARAYÜZÜ)
  // ==========================================
  Widget _buildAlisForm() {
    final pPrice = _parseVal(_alisPurchasePriceController.text);
    final qty = _parseVal(_alisQuantityController.text);
    final cPrice = _parseVal(_alisCurrentPriceController.text) > 0
        ? _parseVal(_alisCurrentPriceController.text)
        : pPrice;

    final totalCost = pPrice * qty;
    final currentValue = cPrice * qty;
    final totalProfit = currentValue - totalCost;
    final profitPercent = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;
    final isProfit = totalProfit >= 0;
    final hasData = totalCost > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori Seçici
        const Text(
          'Varlık Kategorisi',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: AssetCategory.values.map((cat) {
              final isSelected = _alisCategory == cat;
              return SizedBox(
                width: 76,
                child: GestureDetector(
                onTap: () {
                  setState(() {
                    _alisDebounceTimer?.cancel();
                    _alisCategory = cat;
                    _alisSymbolController.clear();
                    _alisLastSymbol = '';
                    _isAlisPurchasePriceManual = false;
                    _isAlisCurrentPriceManual = false;
                    _isLoadingAlisMarketData = false;
                    _clearAlisFetchedData();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.2)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? cat.color : AppTheme.borderSubtle,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      cat.buildIcon(
                        size: 20,
                        color: isSelected ? cat.color : AppTheme.textMuted,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cat.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? cat.color
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Sembol ve İsim
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            final symbolField = AssetSymbolAutocomplete(
              controller: _alisSymbolController,
              category: _alisCategory,
              isLoading: _isLoadingAlisMarketData,
              hintText: _alisCategory == AssetCategory.fon
                  ? 'Örn: TI2 / Fon adı'
                  : _alisCategory == AssetCategory.hisse
                      ? 'Örn: THYAO / Hisse adı'
                      : _alisCategory == AssetCategory.doviz
                          ? 'Örn: USD / Dolar'
                          : _alisCategory == AssetCategory.emtia
                              ? 'Örn: Altın / Gümüş'
                              : 'Örn: BTC / Bitcoin',
              onChanged: _onAlisSymbolChanged,
              onSelected: _onAlisSuggestionSelected,
              onFetchManual: () => _fetchAlisMarketData(
                _alisSymbolController.text.trim(),
                forceHistoricalPrice: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Sembol girin' : null,
            );
            final nameField = TextFormField(
              controller: _alisNameController,
              decoration: const InputDecoration(
                labelText: 'Varlık Adı *',
                hintText: 'Örn: Türk Hava Yolları',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İsim girin' : null,
            );
            final logo = Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: AssetLogo(
                iconUrl: _alisIconUrl,
                symbol: _alisSymbolController.text.trim(),
                name: _alisNameController.text.trim(),
                category: _alisCategory,
                size: 48,
                iconSize: 24,
                borderRadius: 12,
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      logo,
                      Expanded(child: symbolField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  nameField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                Expanded(flex: 2, child: symbolField),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: nameField),
              ],
            );
          },
        ),

        // Otomatik Fiyat Bildirimi
        if (_alisMarketDataStatus != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _alisMarketDataStatus!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Alış Tarihi & Adet
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickAlisDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alış Tarihi (Tıkla & Değiştir)',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formatters.date(_alisDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _alisQuantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Alınan Adet / Miktar *',
                  hintText: 'Örn: 100',
                  prefixIcon: Icon(Icons.format_list_numbered_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Adet girin';
                  if (_parseVal(v) <= 0) return 'Geçerli miktar girin';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Alış Fiyatı & Güncel Fiyat
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _alisPurchasePriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  setState(() {
                    _isAlisPurchasePriceManual = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Alış Birim Fiyatı (₺) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  helperText: _isAlisPurchasePriceManual
                      ? 'Manuel girildi (otomatik yenilemede korunur)'
                      : 'Tarihe göre otomatik bulunur',
                  helperStyle: TextStyle(
                    fontSize: 10,
                    color: _isAlisPurchasePriceManual
                        ? AppTheme.profit
                        : AppTheme.textMuted,
                    fontWeight: _isAlisPurchasePriceManual
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Fiyat girin';
                  if (_parseVal(v) <= 0) return 'Geçerli fiyat girin';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _alisCurrentPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  setState(() {
                    _isAlisCurrentPriceManual = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Güncel Birim Fiyat (₺) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.price_check_rounded),
                  helperText: _isAlisCurrentPriceManual
                      ? 'Manuel girildi (otomatik yenilemede korunur)'
                      : 'Canlı piyasadan çekilir',
                  helperStyle: TextStyle(
                    fontSize: 10,
                    color: _isAlisCurrentPriceManual
                        ? AppTheme.profit
                        : AppTheme.textMuted,
                    fontWeight: _isAlisCurrentPriceManual
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Fiyat girin';
                  if (_parseVal(v) <= 0) return 'Geçerli fiyat girin';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Canlı Değer ve Kâr Önizleme Paneli (Alış Tarihinden İtibaren Kâr Hesabı)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasData
                  ? (isProfit
                      ? AppTheme.profit.withValues(alpha: 0.3)
                      : AppTheme.loss.withValues(alpha: 0.3))
                  : AppTheme.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasData
                        ? (isProfit
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded)
                        : Icons.analytics_outlined,
                    size: 16,
                    color: hasData
                        ? (isProfit ? AppTheme.profit : AppTheme.loss)
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${Formatters.date(_alisDate)} Alışından Bugüne (${Formatters.formatDuration(_alisDate)}) Getiri Hesabı:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasData
                            ? (isProfit ? AppTheme.profit : AppTheme.loss)
                            : AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Toplam Maliyet',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasData ? Formatters.currency(totalCost) : '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Güncel Değer',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasData ? Formatters.currency(currentValue) : '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Net Kâr / Zarar',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasData
                                ? '${isProfit ? '+' : ''}${Formatters.currency(totalProfit)} (${Formatters.percent(profitPercent)})'
                                : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: hasData
                                  ? (isProfit
                                      ? AppTheme.profit
                                      : AppTheme.loss)
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tarihsel Değişim Oranları (Günlük, Haftalık, Aylık, Yıllık %)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tarihsel Değişim Yüzdeleri (%)',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 12, color: AppTheme.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'Otomatik / Dokunulmaz',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 460;
            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Günlük', _parseVal(_alisDailyChangeController.text))),
                    const SizedBox(width: 6),
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Haftalık', _parseVal(_alisWeeklyChangeController.text))),
                    const SizedBox(width: 6),
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('1 Aylık', _parseVal(_alisMonthlyChangeController.text))),
                    const SizedBox(width: 6),
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('3 Aylık', _parseVal(_alisThreeMonthlyChangeController.text))),
                    const SizedBox(width: 6),
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('6 Aylık', _parseVal(_alisSixMonthlyChangeController.text))),
                    const SizedBox(width: 6),
                    SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Yıllık', _parseVal(_alisYearlyChangeController.text))),
                  ],
                ),
              );
            }
            return Row(
              children: [
                Expanded(child: _buildReadonlyPeriodBadge('Günlük', _parseVal(_alisDailyChangeController.text))),
                const SizedBox(width: 6),
                Expanded(child: _buildReadonlyPeriodBadge('Haftalık', _parseVal(_alisWeeklyChangeController.text))),
                const SizedBox(width: 6),
                Expanded(child: _buildReadonlyPeriodBadge('1 Aylık', _parseVal(_alisMonthlyChangeController.text))),
                const SizedBox(width: 6),
                Expanded(child: _buildReadonlyPeriodBadge('3 Aylık', _parseVal(_alisThreeMonthlyChangeController.text))),
                const SizedBox(width: 6),
                Expanded(child: _buildReadonlyPeriodBadge('6 Aylık', _parseVal(_alisSixMonthlyChangeController.text))),
                const SizedBox(width: 6),
                Expanded(child: _buildReadonlyPeriodBadge('Yıllık', _parseVal(_alisYearlyChangeController.text))),
              ],
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // SATIŞ FORMU (PORTFÖYDE OLANLARDAN SATIŞ)
  // ==========================================
  Widget _buildSatisForm() {
    if (widget.portfolio.assets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.loss.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.loss.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Portföyünüzde henüz satış yapılabilecek bir varlık bulunmamaktadır. Lütfen sol taraftaki "Alış" sekmesini kullanarak yeni bir varlık ekleyiniz.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final satisQty = _parseVal(_satisQuantityController.text);
    final satisPrice = _parseVal(_satisPriceController.text);

    final fifoEst = _selectedExistingAsset != null && satisQty > 0
        ? FifoCalculator.estimateSaleCost(
            widget.portfolio,
            _selectedExistingAsset!.symbol,
            satisQty,
            assetFallback: _selectedExistingAsset,
          )
        : null;

    final double totalSatisCost = fifoEst != null && fifoEst.totalCost > 0
        ? fifoEst.totalCost
        : (satisQty * (_selectedExistingAsset?.purchasePrice ?? 0.0));
    final double satisUnitCost =
        satisQty > 0 ? (totalSatisCost / satisQty) : 0.0;
    final double totalSatisRevenue = satisQty * satisPrice;
    final double totalSatisProfit = totalSatisRevenue - totalSatisCost;
    final double satisProfitPercent =
        totalSatisCost > 0 ? (totalSatisProfit / totalSatisCost) * 100 : 0.0;
    final bool isProfit = totalSatisProfit >= 0;
    final bool hasData = satisQty > 0 && satisPrice > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PORTFÖYDEKİ MEVCUT VARLIKLARDAN SEÇİM
        const Text(
          'Portföydeki Varlık *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<PortfolioAsset?>(
          key: ValueKey(_selectedExistingAsset?.id ?? 'none'),
          initialValue: _selectedExistingAsset,
          decoration: const InputDecoration(
            hintText: 'Portföyden satılacak varlığı seçin...',
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          dropdownColor: AppTheme.surfaceElevated,
          items: widget.portfolio.assets.map((a) {
            return DropdownMenuItem<PortfolioAsset?>(
              value: a,
              child: Text(
                '${a.symbol} - ${a.name} (Portföydeki Adet: ${_formatNumber(a.quantity)})',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (asset) {
            if (asset != null) {
              _selectExistingAsset(asset);
            }
          },
          validator: (val) => val == null ? 'Varlık seçmelisiniz' : null,
        ),
        const SizedBox(height: 14),

        // SEMBOL VE İSİM (Seçilen Varlık Bilgisi)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            final logo = Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: AssetLogo(
                iconUrl: _satisIconUrl,
                symbol: _satisSymbolController.text.trim(),
                name: _satisNameController.text.trim(),
                category: _selectedExistingAsset?.category ?? AssetCategory.fon,
                size: 48,
                iconSize: 24,
                borderRadius: 12,
              ),
            );
            final symbolField = TextFormField(
              controller: _satisSymbolController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Sembol',
                filled: true,
              ),
            );
            final nameField = TextFormField(
              controller: _satisNameController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Varlık Adı',
                filled: true,
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      logo,
                      Expanded(child: symbolField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  nameField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                Expanded(flex: 2, child: symbolField),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: nameField),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // MİKTAR VE SATIŞ FİYATI
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _satisQuantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Satılan Adet *',
                  hintText: '0',
                  helperText: _selectedExistingAsset != null
                      ? 'Portföydeki Mevcut: ${_formatNumber(_selectedExistingAsset!.quantity)}'
                      : null,
                ),
                validator: (v) {
                  final val = _parseVal(v ?? '');
                  if (val <= 0) return 'Miktar girin';
                  if (_selectedExistingAsset != null &&
                      val > _selectedExistingAsset!.quantity) {
                    return 'Mevcut adetten fazla satılamaz';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _satisPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  setState(() {
                    _isSatisPriceManual = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Satış Fiyatı (₺) *',
                  hintText: '0.00',
                  helperText: _isSatisPriceManual
                      ? 'Manuel girildi'
                      : 'Piyasa fiyatı',
                  helperStyle: TextStyle(
                    fontSize: 10,
                    color: _isSatisPriceManual
                        ? AppTheme.profit
                        : AppTheme.textMuted,
                    fontWeight: _isSatisPriceManual
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  suffixIcon: _isLoadingSatisMarketData
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.profit,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          tooltip: 'Seçili tarihteki fiyatı tekrar getir',
                          onPressed: () {
                            if (_selectedExistingAsset != null) {
                              _fetchSatisMarketPriceForDate(
                                symbol: _selectedExistingAsset!.symbol,
                                category: _selectedExistingAsset!.category,
                                date: _satisDate,
                              );
                            }
                          },
                        ),
                ),
                validator: (v) =>
                    _parseVal(v ?? '') <= 0 ? 'Geçerli fiyat girin' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // İŞLEM TARİHİ
        InkWell(
          onTap: _pickSatisDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'İşlem Tarihi',
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: Text(
              Formatters.date(_satisDate),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),

        if (_isLoadingSatisMarketData) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.profit,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Seçili tarihe göre satış fiyatı güncelleniyor...',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ] else if (_satisMarketDataStatus != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppTheme.profit),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _satisMarketDataStatus!,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Canlı Değer ve Kâr Önizleme Paneli (Satış İşlemi Özeti)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasData
                  ? (isProfit
                      ? AppTheme.profit.withValues(alpha: 0.3)
                      : AppTheme.loss.withValues(alpha: 0.3))
                  : AppTheme.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasData
                        ? (isProfit
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded)
                        : Icons.analytics_outlined,
                    size: 16,
                    color: hasData
                        ? (isProfit ? AppTheme.profit : AppTheme.loss)
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${Formatters.date(_satisDate)} Satış İşlemi Özeti & Kâr Hesabı:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasData
                            ? (isProfit ? AppTheme.profit : AppTheme.loss)
                            : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Toplam Maliyet (FIFO)',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasData ? Formatters.currency(totalSatisCost) : '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        if (hasData && satisUnitCost > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Birim: ${Formatters.currency(satisUnitCost)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Toplam Satış Tutarı',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasData ? Formatters.currency(totalSatisRevenue) : '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Net Kâr / Zarar',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Builder(
                            builder: (context) {
                              final hasStopaj = hasData &&
                                  _selectedExistingAsset?.category ==
                                      AssetCategory.fon &&
                                  totalSatisProfit > 0 &&
                                  _selectedExistingAsset!
                                          .effectiveWithholdingTaxRate >
                                      0;
                              final stopajRate = _selectedExistingAsset
                                      ?.effectiveWithholdingTaxRate ??
                                  0.0;
                              final netProfit = hasStopaj
                                  ? totalSatisProfit -
                                      totalSatisProfit * (stopajRate / 100)
                                  : totalSatisProfit;
                              final netPct = (hasStopaj && totalSatisCost > 0)
                                  ? (netProfit / totalSatisCost) * 100
                                  : satisProfitPercent;
                              final isNetProfit = netProfit >= 0;

                              return Text(
                                hasData
                                    ? '${isNetProfit ? '+' : ''}${Formatters.currency(netProfit)} (${Formatters.percent(netPct)})'
                                    : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: hasData
                                      ? (isNetProfit
                                          ? AppTheme.profit
                                          : AppTheme.loss)
                                      : AppTheme.textMuted,
                                ),
                              );
                            },
                          ),
                        ),
                        if (hasData &&
                            _selectedExistingAsset?.category ==
                                AssetCategory.fon &&
                            totalSatisProfit > 0 &&
                            _selectedExistingAsset!
                                    .effectiveWithholdingTaxRate >
                                0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Brüt: ${Formatters.currency(totalSatisProfit)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
