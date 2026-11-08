import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../models/portfolio_asset.dart';
import '../services/asset_catalog_service.dart';
import '../services/market_data_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/asset_logo.dart';
import '../widgets/asset_symbol_autocomplete.dart';

class AddEditAssetDialog extends StatefulWidget {
  final PortfolioAsset? asset;
  final Function(PortfolioAsset asset) onSave;
  final bool isFullScreen;

  const AddEditAssetDialog({
    super.key,
    this.asset,
    required this.onSave,
    this.isFullScreen = false,
  });

  @override
  State<AddEditAssetDialog> createState() => _AddEditAssetDialogState();
}

class _AddEditAssetDialogState extends State<AddEditAssetDialog> {
  final _formKey = GlobalKey<FormState>();

  late AssetCategory _selectedCategory;
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _currentPriceController;
  late TextEditingController _withholdingTaxController;
  late TextEditingController _dailyChangeController;
  late TextEditingController _weeklyChangeController;
  late TextEditingController _monthlyChangeController;
  late TextEditingController _threeMonthlyChangeController;
  late TextEditingController _sixMonthlyChangeController;
  late TextEditingController _yearlyChangeController;

  late DateTime _purchaseDate;
  DateTime? _earliestDate;

  bool _isLoadingMarketData = false;
  String? _marketDataStatus;
  Timer? _debounceTimer;
  String? _iconUrl;
  String _lastSymbol = '';

  bool _isPurchasePriceManual = false;
  bool _isCurrentPriceManual = false;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _selectedCategory = a?.category ?? AssetCategory.fon;
    _iconUrl = a?.iconUrl;
    _lastSymbol = a?.symbol ?? '';
    _nameController = TextEditingController(text: a?.name ?? '');
    _symbolController = TextEditingController(text: a?.symbol ?? '');
    _purchasePriceController =
        TextEditingController(text: a?.purchasePrice != null ? _formatPrice(a!.purchasePrice) : '');
    _quantityController =
        TextEditingController(text: a?.quantity != null ? _formatNumber(a!.quantity) : '');
    _currentPriceController =
        TextEditingController(text: a?.currentPrice != null ? _formatPrice(a!.currentPrice) : '');
    final initialStopaj = a?.withholdingTaxRate != null
        ? a!.withholdingTaxRate!.toStringAsFixed(1)
        : (a?.category == AssetCategory.fon
            ? MarketDataService.defaultWithholdingTaxRate(
                    AssetCategory.fon, a?.name ?? '', a?.symbol)
                .toStringAsFixed(1)
            : '17.5');
    _withholdingTaxController = TextEditingController(text: initialStopaj);
    _dailyChangeController =
        TextEditingController(text: a?.dailyChangePercent.toString() ?? '0.0');
    _weeklyChangeController =
        TextEditingController(text: a?.weeklyChangePercent.toString() ?? '0.0');
    _monthlyChangeController =
        TextEditingController(text: a?.monthlyChangePercent.toString() ?? '0.0');
    _threeMonthlyChangeController =
        TextEditingController(text: a?.threeMonthlyChangePercent.toString() ?? '0.0');
    _sixMonthlyChangeController =
        TextEditingController(text: a?.sixMonthlyChangePercent.toString() ?? '0.0');
    _yearlyChangeController =
        TextEditingController(text: a?.yearlyChangePercent.toString() ?? '0.0');

    _purchaseDate = a?.purchaseDate ?? DateTime.now();

    _purchasePriceController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
    _currentPriceController.addListener(() => setState(() {}));
    _withholdingTaxController.addListener(() => setState(() {}));

    if (widget.asset != null) {
      _isPurchasePriceManual = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMarketData(widget.asset!.symbol);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _symbolController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    _currentPriceController.dispose();
    _withholdingTaxController.dispose();
    _dailyChangeController.dispose();
    _weeklyChangeController.dispose();
    _monthlyChangeController.dispose();
    _threeMonthlyChangeController.dispose();
    _sixMonthlyChangeController.dispose();
    _yearlyChangeController.dispose();
    super.dispose();
  }

  String _formatPrice(double val) => Formatters.formatPrice(val);

  String _formatNumber(double val) => Formatters.formatNumber(val);

  double _parseVal(String text) => Formatters.parseDouble(text);

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
                const SizedBox(width: 3),
                Text(
                  '$sign${Formatters.percent(val)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

  void _clearFetchedData() {
    _iconUrl = null;
    _nameController.clear();
    _currentPriceController.clear();
    _purchasePriceController.clear();
    _dailyChangeController.text = '0.0';
    _weeklyChangeController.text = '0.0';
    _monthlyChangeController.text = '0.0';
    _threeMonthlyChangeController.text = '0.0';
    _sixMonthlyChangeController.text = '0.0';
    _yearlyChangeController.text = '0.0';
    _marketDataStatus = null;
    _earliestDate = null;
  }

  void _onSuggestionSelected(AssetSuggestion suggestion) {
    _debounceTimer?.cancel();
    setState(() {
      _symbolController.text = suggestion.symbol;
      _nameController.text = suggestion.name;
      _iconUrl = suggestion.iconUrl;
      _lastSymbol = suggestion.symbol;
      _marketDataStatus = null;
    });
    _fetchMarketData(suggestion.symbol, forceHistoricalPrice: true);
  }

  void _onSymbolChanged(String text) {
    _debounceTimer?.cancel();
    final clean = text.trim();
    if (clean.length < _lastSymbol.length || clean.isEmpty) {
      _clearFetchedData();
    }
    _lastSymbol = clean;
    setState(() {});
    if (clean.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 900), () {
        _fetchMarketData(clean, forceHistoricalPrice: true);
      });
    }
  }

  Future<void> _fetchMarketData(String symbol, {bool forceHistoricalPrice = false}) async {
    if (symbol.trim().isEmpty) return;
    setState(() {
      _isLoadingMarketData = true;
      _marketDataStatus = null;
    });

    final info = await MarketDataService.fetchAssetData(
      category: _selectedCategory,
      symbol: symbol,
      purchaseDate: _purchaseDate,
    );

    if (!mounted) return;
    if (_symbolController.text.trim().toUpperCase() !=
        symbol.trim().toUpperCase()) {
      return;
    }

    setState(() {
      _isLoadingMarketData = false;
      if (info != null) {
        _earliestDate = info.earliestDate;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_purchaseDate.isAfter(today)) {
          _purchaseDate = today;
        } else if (_earliestDate != null && _purchaseDate.isBefore(_earliestDate!)) {
          _purchaseDate = _earliestDate!;
        }
        _lastSymbol = symbol.trim();
        _iconUrl = info.iconUrl;
        _nameController.text = info.name;
        if (_selectedCategory == AssetCategory.fon) {
          final stopaj = info.withholdingTaxRate ??
              MarketDataService.defaultWithholdingTaxRate(
                  AssetCategory.fon, info.name, symbol);
          _withholdingTaxController.text = stopaj.toStringAsFixed(1);
        }
        if (!_isCurrentPriceManual) {
          _currentPriceController.text = _formatPrice(info.currentPrice);
        }
        _dailyChangeController.text = info.dailyChangePercent.toString();
        _weeklyChangeController.text = info.weeklyChangePercent.toString();
        _monthlyChangeController.text = info.monthlyChangePercent.toString();
        _threeMonthlyChangeController.text = info.threeMonthlyChangePercent.toString();
        _sixMonthlyChangeController.text = info.sixMonthlyChangePercent.toString();
        _yearlyChangeController.text = info.yearlyChangePercent.toString();

        final hasManualPrice = _isPurchasePriceManual || _isCurrentPriceManual;

        if (!_isPurchasePriceManual &&
            info.purchaseDatePrice != null &&
            (_purchasePriceController.text.isEmpty ||
                _purchasePriceController.text == '0' ||
                forceHistoricalPrice)) {
          _purchasePriceController.text = _formatPrice(info.purchaseDatePrice!);
          _marketDataStatus =
              '${Formatters.date(_purchaseDate)} tarihindeki fiyat (${_formatPrice(info.purchaseDatePrice!)} ₺) ve güncel veriler otomatik uygulandı.';
        } else if (hasManualPrice) {
          _marketDataStatus =
              'Manuel girilen fiyatlar korundu. Anlık piyasa ve varlık verileri güncellendi.';
        } else {
          _marketDataStatus =
              'Anlık fiyat (${_formatPrice(info.currentPrice)} ₺) ve varlık detayları güncellendi.';
        }
      } else {
        _marketDataStatus = 'Fiyat bilgisi bulunamadı. Lütfen manuel giriniz.';
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_earliestDate == null && _symbolController.text.trim().isNotEmpty) {
      final info = await MarketDataService.fetchAssetData(
        category: _selectedCategory,
        symbol: _symbolController.text.trim(),
        purchaseDate: _purchaseDate,
      );
      if (info?.earliestDate != null) {
        _earliestDate = info!.earliestDate;
      }
    }

    DateTime first = _earliestDate ?? DateTime(2000, 1, 1);
    if (first.isAfter(today)) first = today;

    DateTime initial = _purchaseDate;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
      if (_symbolController.text.trim().isNotEmpty) {
        _fetchMarketData(_symbolController.text.trim(), forceHistoricalPrice: true);
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final pPrice = _parseVal(_purchasePriceController.text);
      final qty = _parseVal(_quantityController.text);
      final cPrice = _currentPriceController.text.trim().isEmpty
          ? pPrice
          : _parseVal(_currentPriceController.text);

      final daily = _parseVal(_dailyChangeController.text);
      final weekly = _parseVal(_weeklyChangeController.text);
      final monthly = _parseVal(_monthlyChangeController.text);
      final threeMonthly = _parseVal(_threeMonthlyChangeController.text);
      final sixMonthly = _parseVal(_sixMonthlyChangeController.text);
      final yearly = _parseVal(_yearlyChangeController.text);

      final updatedAsset = PortfolioAsset(
        id: widget.asset?.id ?? 'asset_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        symbol: _symbolController.text.trim().toUpperCase(),
        category: _selectedCategory,
        purchaseDate: _purchaseDate,
        purchasePrice: pPrice,
        quantity: qty,
        currentPrice: cPrice,
        iconUrl: _iconUrl ?? widget.asset?.iconUrl,
        dailyChangePercent: daily,
        weeklyChangePercent: weekly,
        monthlyChangePercent: monthly,
        threeMonthlyChangePercent: threeMonthly,
        sixMonthlyChangePercent: sixMonthly,
        yearlyChangePercent: yearly,
        withholdingTaxRate: _selectedCategory == AssetCategory.fon
            ? _parseVal(_withholdingTaxController.text)
            : null,
      );

      widget.onSave(updatedAsset);
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = widget.asset != null;


    final isMobile = MediaQuery.sizeOf(context).width < 600;

        if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isEditing ? 'Varlığı Düzenle' : 'Yeni Varlık Ekle',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildFormContent(context, isEditing, isMobile: true),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20,
        vertical: isMobile ? 10 : 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 14 : 24,
              top: isMobile ? 16 : 24,
              right: isMobile ? 6 : 8,
              bottom: isMobile ? 16 : 24,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(right: isMobile ? 8 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopHeader(context, isEditing),
                  const SizedBox(height: 16),
                  _buildFormContent(context, isEditing, isMobile: isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isEditing) {
    return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Varlığı Düzenle' : 'Yeni Varlık Ekle',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppTheme.textMuted,
                      ),
                    ],
                  );
  }

  Widget _buildFormContent(BuildContext context, bool isEditing, {required bool isMobile}) {
    final pPrice = _parseVal(_purchasePriceController.text);
    final qty = _parseVal(_quantityController.text);
    final cPrice = _currentPriceController.text.trim().isEmpty
        ? pPrice
        : _parseVal(_currentPriceController.text);

    final totalCost = pPrice * qty;
    final currentValue = cPrice * qty;
    final totalProfit = currentValue - totalCost;
    final profitPercent =
        totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;
    final isProfit = totalProfit >= 0;
    final hasData = totalCost > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori Seçici (Segmented tabs)
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
                        final isSelected = _selectedCategory == cat;
                        return SizedBox(
                          width: 76,
                          child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _debounceTimer?.cancel();
                              _selectedCategory = cat;
                              _symbolController.clear();
                              _lastSymbol = '';
                              _isPurchasePriceManual = false;
                              _isCurrentPriceManual = false;
                              _isLoadingMarketData = false;
                              _clearFetchedData();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withValues(alpha: 0.2)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : AppTheme.borderSubtle,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                cat.buildIcon(
                                  size: 20,
                                  color: isSelected
                                      ? cat.color
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    cat.displayName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
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
                        controller: _symbolController,
                        category: _selectedCategory,
                        isLoading: _isLoadingMarketData,
                        labelText: 'Kod / Sembol *',
                        prefixIcon: const Icon(Icons.tag_rounded),
                        showRefreshButton: true,
                        hintText: _selectedCategory == AssetCategory.fon
                            ? 'Örn: TI2 / Fon adı'
                            : _selectedCategory == AssetCategory.hisse
                                ? 'Örn: THYAO / Hisse adı'
                                : _selectedCategory == AssetCategory.doviz
                                    ? 'Örn: USD / Dolar'
                                    : _selectedCategory == AssetCategory.emtia
                                        ? 'Örn: Altın / Gümüş'
                                        : 'Örn: BTC / Bitcoin',
                        onChanged: _onSymbolChanged,
                        onSelected: _onSuggestionSelected,
                        onFetchManual: () => _fetchMarketData(
                          _symbolController.text.trim(),
                          forceHistoricalPrice: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Sembol girin'
                            : null,
                      );
                      final nameField = TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Varlık Adı *',
                          hintText: 'Örn: İş Portföy Hisse Senedi Fonu',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'İsim girin'
                            : null,
                      );
                      final logo = Padding(
                        padding: const EdgeInsets.only(top: 4, right: 10),
                        child: AssetLogo(
                          iconUrl: _iconUrl,
                          symbol: _symbolController.text.trim(),
                          name: _nameController.text.trim(),
                          category: _selectedCategory,
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
                  if (_marketDataStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _marketDataStatus!,
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

                  const SizedBox(height: 16),

                  // Alış Tarihi & Adet
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
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
                                        Formatters.date(_purchaseDate),
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
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            TurkishNumberInputFormatter(maxDecimals: 6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Adet / Miktar *',
                            hintText: 'Örn: 1000',
                            prefixIcon: Icon(Icons.format_list_numbered_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Adet girin';
                            if (_parseVal(v) <= 0) {
                              return 'Geçersiz sayı';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alış Fiyatı & Güncel Fiyat
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            TurkishNumberInputFormatter(maxDecimals: 7),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _isPurchasePriceManual = val.trim().isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Alış Birim Fiyatı (₺) *',
                            hintText: 'Örn: 1,45',
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                            helperText: _isPurchasePriceManual
                                ? 'Manuel girildi (otomatik yenilemede korunur)'
                                : 'Tarihe göre otomatik bulunur',
                            helperStyle: TextStyle(
                              fontSize: 10,
                              color: _isPurchasePriceManual
                                  ? AppTheme.profit
                                  : AppTheme.textMuted,
                              fontWeight: _isPurchasePriceManual
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Fiyat girin';
                            if (_parseVal(v) <= 0) {
                              return 'Geçersiz sayı';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _currentPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            TurkishNumberInputFormatter(maxDecimals: 7),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _isCurrentPriceManual = val.trim().isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Güncel Birim Fiyat (₺) *',
                            hintText: 'Örn: 2,18',
                            prefixIcon: const Icon(Icons.price_check_rounded),
                            helperText: _isCurrentPriceManual
                                ? 'Manuel girildi (otomatik yenilemede korunur)'
                                : 'Canlı piyasadan çekilir',
                            helperStyle: TextStyle(
                              fontSize: 10,
                              color: _isCurrentPriceManual
                                  ? AppTheme.profit
                                  : AppTheme.textMuted,
                              fontWeight: _isCurrentPriceManual
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Fiyat girin';
                            if (_parseVal(v) <= 0) {
                              return 'Geçersiz sayı';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_selectedCategory == AssetCategory.fon) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _withholdingTaxController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Stopaj Oranı (%)',
                              hintText: 'Örn: 17.5 veya 0',
                              prefixIcon: Icon(Icons.percent_rounded),
                              helperText:
                                  'Hisse yoğun fonlarda %0, diğerlerinde %17,5',
                            ),
                          ),
                        ),
                        if (cPrice > pPrice && pPrice > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Stopaj Kesilmiş Net Fiyat',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${Formatters.formatPrice(pPrice + (cPrice - pPrice) * (1 - (_parseVal(_withholdingTaxController.text) / 100)))} ₺',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.profit,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

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
                                '${Formatters.date(_purchaseDate)} Alışından Bugüne (${Formatters.formatDuration(_purchaseDate)}) Getiri Hesabı:',
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
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
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
                                            _selectedCategory ==
                                                AssetCategory.fon &&
                                            totalProfit > 0 &&
                                            _parseVal(_withholdingTaxController
                                                    .text) >
                                                0;
                                        final stopajRate = _parseVal(
                                            _withholdingTaxController.text);
                                        final netProfit = hasStopaj
                                            ? totalProfit -
                                                totalProfit *
                                                    (stopajRate / 100)
                                            : totalProfit;
                                        final netPct = (hasStopaj &&
                                                totalCost > 0)
                                            ? (netProfit / totalCost) * 100
                                            : profitPercent;
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
                                      _selectedCategory == AssetCategory.fon &&
                                      totalProfit > 0 &&
                                      _parseVal(_withholdingTaxController.text) >
                                          0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Brüt: ${Formatters.currency(totalProfit)}',
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
                  const SizedBox(height: 20),

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
                            Icon(Icons.lock_outline_rounded, size: 12, color: AppTheme.textMuted),
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
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Günlük', _parseVal(_dailyChangeController.text))),
                              const SizedBox(width: 6),
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Haftalık', _parseVal(_weeklyChangeController.text))),
                              const SizedBox(width: 6),
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('1 Aylık', _parseVal(_monthlyChangeController.text))),
                              const SizedBox(width: 6),
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('3 Aylık', _parseVal(_threeMonthlyChangeController.text))),
                              const SizedBox(width: 6),
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('6 Aylık', _parseVal(_sixMonthlyChangeController.text))),
                              const SizedBox(width: 6),
                              SizedBox(width: 72, child: _buildReadonlyPeriodBadge('Yıllık', _parseVal(_yearlyChangeController.text))),
                            ],
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _buildReadonlyPeriodBadge('Günlük', _parseVal(_dailyChangeController.text))),
                          const SizedBox(width: 6),
                          Expanded(child: _buildReadonlyPeriodBadge('Haftalık', _parseVal(_weeklyChangeController.text))),
                          const SizedBox(width: 6),
                          Expanded(child: _buildReadonlyPeriodBadge('1 Aylık', _parseVal(_monthlyChangeController.text))),
                          const SizedBox(width: 6),
                          Expanded(child: _buildReadonlyPeriodBadge('3 Aylık', _parseVal(_threeMonthlyChangeController.text))),
                          const SizedBox(width: 6),
                          Expanded(child: _buildReadonlyPeriodBadge('6 Aylık', _parseVal(_sixMonthlyChangeController.text))),
                          const SizedBox(width: 6),
                          Expanded(child: _buildReadonlyPeriodBadge('Yıllık', _parseVal(_yearlyChangeController.text))),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(isEditing ? Icons.check : Icons.add),
                        label: Text(isEditing ? 'Kaydet' : 'Varlığı Ekle'),
                      ),
                    ],
                  ),
      ],
    );
  }
}
