import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../services/asset_catalog_service.dart';
import '../services/market_data_service.dart';
import '../theme/app_colors.dart';
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
  bool _alisHasSelectedAsset = false;
  bool _isAlisPurchasePriceManual = false;
  bool _isLoadingAlisMarketData = false;
  Timer? _alisDebounceTimer;

  // SATIŞ DURUMU DEĞİŞKENLERİ
  PortfolioAsset? _selectedExistingAsset;
  late TextEditingController _satisSymbolController;
  late TextEditingController _satisNameController;
  late TextEditingController _satisQuantityController;
  late TextEditingController _satisPriceController;
  final FocusNode _satisQuantityFocusNode = FocusNode();
  late DateTime _satisDate;
  DateTime? _satisEarliestDate;
  String? _satisIconUrl;
  bool _isSatisPriceManual = false;

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
    _satisQuantityFocusNode.addListener(() {
      if (!_satisQuantityFocusNode.hasFocus) {
        _clampSatisQuantity();
      }
    });

    _selectedType = widget.initialType;
    if (widget.initialAsset != null) {
      _alisCategory = widget.initialAsset!.category;
      _alisSymbolController.text = widget.initialAsset!.symbol;
      _alisNameController.text = widget.initialAsset!.name;
      _alisIconUrl = widget.initialAsset!.iconUrl;
      _alisLastSymbol = widget.initialAsset!.symbol;
      _alisHasSelectedAsset = true;
      _fetchAlisMarketData(widget.initialAsset!.symbol, forceHistoricalPrice: true);
    }
    // Satış sekmesinde varsayılan olarak hiçbir varlık seçili gelmez,
    // adet ve fiyat boş kalır, tarih bugünün tarihi olur.
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
    _satisQuantityFocusNode.dispose();
    super.dispose();
  }

  void _clampSatisQuantity() {
    if (_selectedExistingAsset == null) return;
    final val = _parseVal(_satisQuantityController.text);
    if (val > _selectedExistingAsset!.quantity) {
      final formatted = _formatNumber(_selectedExistingAsset!.quantity);
      _satisQuantityController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String _formatPrice(double val) {
    return Formatters.formatPriceGrouped(val);
  }

  String _formatNumber(double val) {
    return Formatters.formatNumber(val);
  }

  double _parseVal(String text) {
    return Formatters.parseDouble(text);
  }

  // --- ALIŞ FONKSİYONLARI ---
  void _clearAlisFetchedData() {
    _alisHasSelectedAsset = false;
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
    _alisEarliestDate = null;
  }

  void _onAlisSuggestionSelected(AssetSuggestion suggestion) {
    _alisDebounceTimer?.cancel();
    setState(() {
      _alisSymbolController.text = suggestion.symbol;
      _alisNameController.text = suggestion.name;
      _alisIconUrl = suggestion.iconUrl;
      _alisLastSymbol = suggestion.symbol;
      _alisCategory = suggestion.category;
      _alisHasSelectedAsset = true;
    });
    _fetchAlisMarketData(suggestion.symbol, forceHistoricalPrice: true);
  }

  void _onAlisSymbolChanged(String text) {
    _alisDebounceTimer?.cancel();
    final clean = text.trim();
    if (clean.length < _alisLastSymbol.length ||
        clean.isEmpty ||
        clean.toUpperCase() != _alisLastSymbol.toUpperCase()) {
      _clearAlisFetchedData();
    }
    _alisLastSymbol = clean;
    setState(() {});
  }

  Future<void> _fetchAlisMarketData(String symbol,
      {bool forceHistoricalPrice = false}) async {
    if (symbol.trim().isEmpty) return;
    setState(() {
      _isLoadingAlisMarketData = true;
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
        _alisHasSelectedAsset = true;
        _alisIconUrl = info.iconUrl;
        _alisNameController.text = info.name;
        _alisCurrentPriceController.text = _formatPrice(info.currentPrice);
        _alisDailyChangeController.text = info.dailyChangePercent.toString();
        _alisWeeklyChangeController.text = info.weeklyChangePercent.toString();
        _alisMonthlyChangeController.text = info.monthlyChangePercent.toString();
        _alisThreeMonthlyChangeController.text =
            info.threeMonthlyChangePercent.toString();
        _alisSixMonthlyChangeController.text =
            info.sixMonthlyChangePercent.toString();
        _alisYearlyChangeController.text = info.yearlyChangePercent.toString();

        if (!_isAlisPurchasePriceManual &&
            info.purchaseDatePrice != null &&
            (_alisPurchasePriceController.text.isEmpty ||
                _alisPurchasePriceController.text == '0' ||
                forceHistoricalPrice)) {
          _alisPurchasePriceController.text =
              _formatPrice(info.purchaseDatePrice!);
        }
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
              onPrimary: AppTheme.textPrimary,
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
                            foregroundColor: AppTheme.textPrimary,
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
      if (_alisSymbolController.text.trim().isNotEmpty &&
          _alisNameController.text.trim().isNotEmpty) {
        _fetchAlisMarketData(_alisSymbolController.text.trim(),
            forceHistoricalPrice: true);
      }
    }
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

    final info = await MarketDataService.fetchAssetData(
      category: category,
      symbol: clean,
      purchaseDate: date,
    );

    if (!mounted) return;

    setState(() {
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

      _clampSatisQuantity();

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
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isAlis ? AppTheme.profit : AppTheme.loss)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAlis
                      ? Icons.add_shopping_cart_rounded
                      : Icons.sell_rounded,
                  color: isAlis ? AppTheme.profit : AppTheme.loss,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'İşlem Ekle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isAlis ? AppTheme.profit : AppTheme.loss)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAlis
                ? Icons.add_shopping_cart_rounded
                : Icons.sell_rounded,
            color: isAlis ? AppTheme.profit : AppTheme.loss,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'İşlem Ekle',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
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
                                    ? AppTheme.profit.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isAlis
                                    ? Border.all(color: AppTheme.profit, width: 1.2)
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: isAlis
                                        ? AppTheme.profit
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Alış',
                                      style: TextStyle(
                                        fontWeight: isAlis
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isAlis
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
                                    ? AppTheme.loss.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: !isAlis
                                    ? Border.all(color: AppTheme.loss, width: 1.2)
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: !isAlis
                                        ? AppTheme.loss
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Satış',
                                      style: TextStyle(
                                        fontWeight: !isAlis
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: !isAlis
                                            ? AppTheme.loss
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

                  // AKSİYON BUTONLARI (Mobilde tam genişlik, masaüstünde sağa hizalı)
                  if (isMobile)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isAlis ? AppTheme.profit : AppTheme.loss,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: (!isAlis && widget.portfolio.assets.isEmpty)
                                ? null
                                : _saveTransaction,
                            child: Text(
                              isAlis ? 'Alışı Kaydet' : 'Satışı Kaydet',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isAlis ? AppTheme.profit : AppTheme.loss,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          onPressed: (!isAlis && widget.portfolio.assets.isEmpty)
                              ? null
                              : _saveTransaction,
                          child: Text(
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
    final totalCost = pPrice * qty;
    final hasData = totalCost > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sembol ve Akıllı İsim Gösterimi
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AssetLogo(
                iconUrl: _alisIconUrl,
                symbol: _alisHasSelectedAsset ? _alisSymbolController.text.trim() : '',
                name: _alisHasSelectedAsset ? _alisNameController.text.trim() : null,
                category: _alisCategory,
                size: 48,
                iconSize: 24,
                borderRadius: 12,
              ),
            ),
            Expanded(
              child: AssetSymbolAutocomplete(
                controller: _alisSymbolController,
                assetName: _alisNameController.text,
                isLoading: _isLoadingAlisMarketData,
                hintText: 'Varlık ara...',
                onChanged: _onAlisSymbolChanged,
                onSelected: _onAlisSuggestionSelected,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Varlık seçin veya sembol girin' : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Alış Tarihi & Adet
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickAlisDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        color: AppTheme.profit,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Formatters.date(_alisDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _alisQuantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  TurkishNumberInputFormatter(maxDecimals: 6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Adet',
                  hintText: '0',
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

        // Alış Fiyatı
        TextFormField(
          controller: _alisPurchasePriceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TurkishNumberInputFormatter(maxDecimals: 7),
          ],
          onChanged: (val) {
            setState(() {
              _isAlisPurchasePriceManual = val.trim().isNotEmpty;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Alış Fiyatı',
            hintText: '0,00',
            prefixIcon: Icon(Icons.currency_lira_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Fiyat girin';
            if (_parseVal(v) <= 0) return 'Geçerli fiyat girin';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Toplam Maliyet Paneli (Ortalanmış & Hafif Yeşil Vurgu)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.profit.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.profit.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Toplam',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.profit.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                hasData ? Formatters.currency(totalCost) : '0,00 ₺',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.profit,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SATIŞ VARLIK SEÇİCİ BOTTOM SHEET
  // ==========================================
  void _showSatisAssetPicker(BuildContext context) {
    final assets = widget.portfolio.assets;
    if (assets.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Satılacak Varlığı Seçin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppTheme.textMuted,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderSubtle, height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: assets.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: AppTheme.borderSubtle,
                      height: 1,
                      indent: 68,
                    ),
                    itemBuilder: (context, index) {
                      final a = assets[index];
                      final isSelected = _selectedExistingAsset?.id == a.id;
                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _selectExistingAsset(a);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              AssetLogo(
                                iconUrl: a.iconUrl,
                                symbol: a.symbol,
                                name: a.name,
                                category: a.category,
                                size: 40,
                                iconSize: 20,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          a.symbol,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: a.category.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            a.category.displayName,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: a.category.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      a.name,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.profit),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    final double totalSatisRevenue = satisQty * satisPrice;
    final bool hasData = satisQty > 0 && satisPrice > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PORTFÖYDEKİ MEVCUT VARLIKLARDAN SEÇİM (Tıklanabilir Modern Kart)
        const Text(
          'Portföydeki Varlık',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showSatisAssetPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                if (_selectedExistingAsset != null) ...[
                  AssetLogo(
                    iconUrl: _satisIconUrl,
                    symbol: _satisSymbolController.text.trim(),
                    name: _satisNameController.text.trim(),
                    category: _selectedExistingAsset?.category ?? AssetCategory.fon,
                    size: 34,
                    iconSize: 18,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _satisSymbolController.text.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_satisNameController.text.trim().isNotEmpty)
                            TextSpan(
                              text: '   ${_satisNameController.text.trim()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textSecondary.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppTheme.textMuted),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Portföyden satılacak varlığı seçin...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // TOPLAM ADET & TOPLAM FİYAT BİLGİ KUTUCUĞU
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toplam Adet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedExistingAsset != null
                          ? '${_formatNumber(_selectedExistingAsset!.quantity)} Adet'
                          : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppTheme.borderSubtle,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toplam Fiyat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedExistingAsset != null
                          ? Formatters.currency(_selectedExistingAsset!.quantity * _selectedExistingAsset!.currentPrice)
                          : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
        const SizedBox(height: 14),

        // Satış Tarihi & Adet
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickSatisDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        color: AppTheme.loss,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Formatters.date(_satisDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                focusNode: _satisQuantityFocusNode,
                controller: _satisQuantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  TurkishNumberInputFormatter(maxDecimals: 6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Adet',
                  hintText: '0',
                ),
                onFieldSubmitted: (_) => _clampSatisQuantity(),
                onEditingComplete: _clampSatisQuantity,
                validator: (v) {
                  if (_selectedExistingAsset == null) return 'Önce varlık seçin';
                  final val = _parseVal(v ?? '');
                  if (val <= 0) return 'Miktar girin';
                  if (val > _selectedExistingAsset!.quantity) {
                    return 'Mevcut adetten fazla satılamaz';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Satış Fiyatı
        TextFormField(
          controller: _satisPriceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TurkishNumberInputFormatter(maxDecimals: 7),
          ],
          onChanged: (val) {
            setState(() {
              _isSatisPriceManual = val.trim().isNotEmpty;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Satış Fiyatı',
            hintText: '0,00',
            prefixIcon: Icon(Icons.currency_lira_rounded),
          ),
          validator: (v) =>
              _parseVal(v ?? '') <= 0 ? 'Geçerli fiyat girin' : null,
        ),
        const SizedBox(height: 14),

        // Toplam Satış Tutarı Paneli (Ortalanmış & Hafif Kırmızı Vurgu)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.loss.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.loss.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Toplam',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.loss.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                hasData ? Formatters.currency(totalSatisRevenue) : '0,00 ₺',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.loss,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
