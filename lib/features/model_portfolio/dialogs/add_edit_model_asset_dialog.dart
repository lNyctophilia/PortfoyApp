import 'package:flutter/material.dart';
import '../../../models/asset_category.dart';
import '../../../models/portfolio.dart';
import '../../../models/portfolio_asset.dart';
import '../../../services/asset_catalog_service.dart';
import '../../../services/market_data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/asset_logo.dart';
import '../../../widgets/asset_symbol_autocomplete.dart';

class AddEditModelAssetDialog extends StatefulWidget {
  final Portfolio portfolio;
  final PortfolioAsset? asset;
  final Function(PortfolioAsset asset) onSave;

  const AddEditModelAssetDialog({
    super.key,
    required this.portfolio,
    this.asset,
    required this.onSave,
  });

  @override
  State<AddEditModelAssetDialog> createState() =>
      _AddEditModelAssetDialogState();
}

class _AddEditModelAssetDialogState extends State<AddEditModelAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symbolController;
  late TextEditingController _nameController;
  late TextEditingController _allocationController;

  AssetCategory _selectedCategory = AssetCategory.hisse;
  String? _iconUrl;
  bool _isLoading = false;
  MarketAssetInfo? _marketInfo;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _symbolController = TextEditingController(text: a?.symbol ?? '');
    _nameController = TextEditingController(text: a?.name ?? '');
    _allocationController = TextEditingController(
      text: a != null && a.targetAllocationPercent > 0
          ? a.targetAllocationPercent.toStringAsFixed(1).replaceAll('.0', '')
          : '',
    );
    if (a != null) {
      _selectedCategory = a.category;
      _iconUrl = a.iconUrl;
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _allocationController.dispose();
    super.dispose();
  }

  double get _currentAllocatedExcludingSelf {
    double sum = 0.0;
    for (final a in widget.portfolio.assets) {
      if (widget.asset != null && a.id == widget.asset!.id) continue;
      sum += a.targetAllocationPercent;
    }
    return sum;
  }

  double get _remainingAllocation =>
      (100.0 - _currentAllocatedExcludingSelf).clamp(0.0, 100.0);

  void _onSuggestionSelected(AssetSuggestion suggestion) {
    setState(() {
      _symbolController.text = suggestion.symbol;
      _nameController.text = suggestion.name;
      _selectedCategory = suggestion.category;
      _iconUrl = suggestion.iconUrl;
    });
    _fetchMarketData(suggestion.symbol, suggestion.category);
  }

  Future<void> _fetchMarketData(String symbol, AssetCategory category) async {
    setState(() => _isLoading = true);
    final info = await MarketDataService.fetchAssetData(
      category: category,
      symbol: symbol,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _marketInfo = info;
        if (info != null) {
          if (info.name.isNotEmpty) _nameController.text = info.name;
          if (info.iconUrl != null) _iconUrl = info.iconUrl;
        }
      });
    }
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : symbol;
    final alloc = Formatters.parseDouble(_allocationController.text) ?? 0.0;

    setState(() => _isLoading = true);

    MarketAssetInfo? info = _marketInfo;
    info ??= await MarketDataService.fetchAssetData(
      category: _selectedCategory,
      symbol: symbol,
    );

    final now = DateTime.now();
    final asset = (widget.asset ??
            PortfolioAsset(
              id: 'asset_${now.millisecondsSinceEpoch}',
              name: name,
              symbol: symbol,
              category: _selectedCategory,
              purchaseDate: now,
              purchasePrice: info?.currentPrice ?? 1.0,
              quantity: 1.0,
              currentPrice: info?.currentPrice ?? 1.0,
            ))
        .copyWith(
      name: name,
      symbol: symbol,
      category: _selectedCategory,
      targetAllocationPercent: alloc,
      currentPrice: info?.currentPrice ?? widget.asset?.currentPrice ?? 1.0,
      iconUrl: _iconUrl ?? info?.iconUrl ?? widget.asset?.iconUrl,
      dailyChangePercent: info?.dailyChangePercent ?? widget.asset?.dailyChangePercent ?? 0.0,
      weeklyChangePercent: info?.weeklyChangePercent ?? widget.asset?.weeklyChangePercent ?? 0.0,
      monthlyChangePercent: info?.monthlyChangePercent ?? widget.asset?.monthlyChangePercent ?? 0.0,
      threeMonthlyChangePercent: info?.threeMonthlyChangePercent ?? widget.asset?.threeMonthlyChangePercent ?? 0.0,
      sixMonthlyChangePercent: info?.sixMonthlyChangePercent ?? widget.asset?.sixMonthlyChangePercent ?? 0.0,
      yearlyChangePercent: info?.yearlyChangePercent ?? widget.asset?.yearlyChangePercent ?? 0.0,
      twoYearlyChangePercent: info?.twoYearlyChangePercent ?? widget.asset?.twoYearlyChangePercent ?? 0.0,
      threeYearlyChangePercent: info?.threeYearlyChangePercent ?? widget.asset?.threeYearlyChangePercent ?? 0.0,
      fiveYearlyChangePercent: info?.fiveYearlyChangePercent ?? widget.asset?.fiveYearlyChangePercent ?? 0.0,
      earliestDate: info?.earliestDate ?? widget.asset?.earliestDate,
      monthlyReturns: info?.monthlyReturns.isNotEmpty == true
          ? info!.monthlyReturns
          : (widget.asset?.monthlyReturns ?? const {}),
    );

    if (mounted) {
      widget.onSave(asset);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.asset != null;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve Kapat Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Model Varlığı Düzenle' : 'Model Portföye Varlık Ekle',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Varlık Seçim / Arama
                  if (!isEditing) ...[
                    AssetSymbolAutocomplete(
                      controller: _symbolController,
                      category: _selectedCategory,
                      labelText: 'Varlık Ara veya Kod Gir',
                      onSelected: _onSuggestionSelected,
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          AssetLogo(
                            iconUrl: _iconUrl,
                            symbol: _symbolController.text,
                            category: _selectedCategory,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _symbolController.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
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
                  ],

                  // Kategori Seçici
                  if (!isEditing) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AssetCategory.hisse,
                        AssetCategory.fon,
                        AssetCategory.kripto,
                        AssetCategory.emtia,
                        AssetCategory.doviz,
                      ].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? AppColors.cityInner : AppTheme.textSecondary,
                            ),
                          ),
                          selected: isSel,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                            if (_symbolController.text.isNotEmpty) {
                              _fetchMarketData(_symbolController.text, cat);
                            }
                          },
                          backgroundColor: AppTheme.surfaceElevated,
                          selectedColor: AppColors.cityInner.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: isSel ? AppColors.cityInner : AppTheme.borderSubtle,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Portföy Dağılım Payı (%) Input
                  TextFormField(
                    controller: _allocationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Portföy Payı / Ağırlık (%)',
                      prefixIcon: const Icon(Icons.percent_rounded),
                      suffixText: '%',
                      suffixIcon: _remainingAllocation > 0
                          ? TextButton(
                              onPressed: () {
                                _allocationController.text = _remainingAllocation
                                    .toStringAsFixed(1)
                                    .replaceAll('.0', '');
                              },
                              child: Text(
                                'Kalan (%${_remainingAllocation.toStringAsFixed(0)})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cityInner,
                                ),
                              ),
                            )
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Lütfen bir yüzde girin';
                      }
                      final val = Formatters.parseDouble(v);
                      if (val == null || val <= 0 || val > 100) {
                        return 'Geçerli bir yüzde girin (1-100)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Hızlı Yüzde Butonları
                  Wrap(
                    spacing: 8,
                    children: [10, 20, 25, 33, 50].map((pct) {
                      return InkWell(
                        onTap: () {
                          _allocationController.text = pct.toString();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text(
                            '%$pct',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Aksiyon Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(isEditing ? Icons.check_rounded : Icons.add_rounded),
                        label: Text(isEditing ? 'Güncelle' : 'Varlık Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cityInner,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
