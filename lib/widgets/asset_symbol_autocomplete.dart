import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../services/asset_catalog_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'asset_logo.dart';

class AssetSymbolAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final AssetCategory? category;
  final ValueChanged<AssetSuggestion> onSelected;
  final VoidCallback? onFetchManual;
  final bool isLoading;
  final String? Function(String?)? validator;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final bool showRefreshButton;
  final String? assetName;
  final ValueChanged<String>? onChanged;

  const AssetSymbolAutocomplete({
    super.key,
    required this.controller,
    this.category,
    required this.onSelected,
    this.onFetchManual,
    this.isLoading = false,
    this.validator,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.showRefreshButton = false,
    this.assetName,
    this.onChanged,
  });

  @override
  State<AssetSymbolAutocomplete> createState() => _AssetSymbolAutocompleteState();
}

class _AssetSymbolAutocompleteState extends State<AssetSymbolAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();
  OverlayEntry? _overlayEntry;

  List<AssetSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AssetSymbolAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      if (_focusNode.hasFocus && widget.controller.text.trim().isNotEmpty) {
        _performSearch(widget.controller.text);
      } else {
        _hideOverlay();
      }
    }
    if (oldWidget.assetName != widget.assetName) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
    if (_focusNode.hasFocus) {
      if (widget.controller.text.trim().isNotEmpty && _suggestions.isNotEmpty) {
        _showOverlay();
      } else if (widget.controller.text.trim().isNotEmpty) {
        _performSearch(widget.controller.text);
      } else {
        _hideOverlay();
      }
    }
    // Not: Mobilde ekrandaki öneri listesine dokunulup kaydırıldığında input odağı
    // kaybolabilir. Bu sebeple odak kaybında (blur) overlay'i kapatmıyoruz.
    // Liste yalnızca kullanıcı arama kutusu ve öneri listesi dışına dokunduğunda
    // (TapRegion.onTapOutside) veya bir varlık seçtiğinde kapatılır.
  }

  void _onControllerChanged() {
    if (_focusNode.hasFocus) {
      final text = widget.controller.text.trim();
      _debounceTimer?.cancel();

      if (text.isEmpty) {
        _hideOverlay();
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        return;
      }

      // Kullanıcı bir tuşa basıp beklediğinde (~800ms) önerileri getir
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _performSearch(widget.controller.text);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        _hideOverlay();
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final results = await AssetCatalogService.search(
        category: widget.category,
        query: clean,
      );

      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });

      if (_focusNode.hasFocus &&
          _suggestions.isNotEmpty &&
          widget.controller.text.trim().isNotEmpty) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
        _hideOverlay();
      }
    }
  }

  void _showOverlay() {
    _hideOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final viewInsetsBottom = mediaQuery.viewInsets.bottom;
        final targetWidth = math.min(size.width.clamp(200.0, 520.0), screenWidth - 32);
        final accentColor = widget.category?.color ?? AppTheme.primaryLight;

        // RenderBox koordinatları ile klavyenin üzerinde kalan boşluğu hesapla
        final fieldOffset = renderBox.localToGlobal(Offset.zero);
        final spaceBelow = screenHeight - viewInsetsBottom - (fieldOffset.dy + size.height) - 16;
        final dynamicMaxHeight = (spaceBelow > 140) ? math.min(320.0, spaceBelow) : 220.0;

        // Kategorilere göre bölümler (BYF'ler ayrı bir bölüm olarak listelenir)
        final sections = <Map<String, dynamic>>[];

        final tefasFunds = _suggestions.where((s) => s.category == AssetCategory.fon && !s.isByf).toList();
        if (tefasFunds.isNotEmpty) {
          sections.add({
            'title': 'Yatırım Fonu',
            'icon': AssetCategory.fon.buildIcon(size: 13, color: AssetCategory.fon.color),
            'color': AssetCategory.fon.color,
            'items': tefasFunds,
          });
        }

        final byfItems = _suggestions.where((s) => s.isByf).toList();
        if (byfItems.isNotEmpty) {
          sections.add({
            'title': 'Borsa Yatırım Fonu',
            'icon': const Icon(Icons.layers_rounded, size: 13, color: Color(0xFF64DFDF)),
            'color': const Color(0xFF64DFDF),
            'items': byfItems,
          });
        }

        final stockItems = _suggestions.where((s) => s.category == AssetCategory.hisse && !s.isByf).toList();
        if (stockItems.isNotEmpty) {
          sections.add({
            'title': AssetCategory.hisse.displayName,
            'icon': AssetCategory.hisse.buildIcon(size: 13, color: AssetCategory.hisse.color),
            'color': AssetCategory.hisse.color,
            'items': stockItems,
          });
        }

        final cryptoItems = _suggestions.where((s) => s.category == AssetCategory.kripto).toList();
        if (cryptoItems.isNotEmpty) {
          sections.add({
            'title': AssetCategory.kripto.displayName,
            'icon': AssetCategory.kripto.buildIcon(size: 13, color: AssetCategory.kripto.color),
            'color': AssetCategory.kripto.color,
            'items': cryptoItems,
          });
        }

        final emtiaItems = _suggestions.where((s) => s.category == AssetCategory.emtia).toList();
        if (emtiaItems.isNotEmpty) {
          sections.add({
            'title': AssetCategory.emtia.displayName,
            'icon': AssetCategory.emtia.buildIcon(size: 13, color: AssetCategory.emtia.color),
            'color': AssetCategory.emtia.color,
            'items': emtiaItems,
          });
        }

        final dovizItems = _suggestions.where((s) => s.category == AssetCategory.doviz).toList();
        if (dovizItems.isNotEmpty) {
          sections.add({
            'title': AssetCategory.doviz.displayName,
            'icon': AssetCategory.doviz.buildIcon(size: 13, color: AssetCategory.doviz.color),
            'color': AssetCategory.doviz.color,
            'items': dovizItems,
          });
        }

        return Positioned(
          width: targetWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: TapRegion(
              groupId: _tapRegionGroupId,
              onTapOutside: (_) {
                _hideOverlay();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxHeight: dynamicMaxHeight),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearching)
                          LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),

                        // Gruplanmış Öneri Listesi
                        Flexible(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              children: [
                            for (final section in sections) ...[
                              // Bölüm Başlığı (Section Header)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (section['color'] as Color).withValues(alpha: 0.08),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: (section['color'] as Color).withValues(alpha: 0.15),
                                      width: 0.8,
                                    ),
                                    top: BorderSide(
                                      color: AppTheme.border.withValues(alpha: 0.35),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    section['icon'] as Widget,
                                    const SizedBox(width: 6),
                                    Text(
                                      section['title'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: section['color'] as Color,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bu kategoriye ait varlıklar
                              for (final item in (section['items'] as List<AssetSuggestion>))
                                InkWell(
                                  onTap: () {
                                    _hideOverlay();
                                    _focusNode.unfocus();
                                    widget.onSelected(item);
                                  },
                                  hoverColor: (section['color'] as Color).withValues(alpha: 0.08),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppTheme.borderSubtle,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AssetLogo(
                                          iconUrl: item.iconUrl,
                                          symbol: item.symbol,
                                          name: item.name,
                                          category: item.category,
                                          size: 32,
                                          iconSize: 16,
                                          borderRadius: 8,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.symbol,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.north_west_rounded,
                                          size: 14,
                                          color: (section['color'] as Color).withValues(alpha: 0.65),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.controller.text.trim().isEmpty;
    final showInlineName = !_focusNode.hasFocus &&
        widget.assetName != null &&
        widget.assetName!.trim().isNotEmpty &&
        !isEmpty;

    return TapRegion(
      groupId: _tapRegionGroupId,
      child: CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.characters,
            onChanged: widget.onChanged,
            style: TextStyle(
              color: showInlineName ? Colors.transparent : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText ?? 'Varlık ara...',
              prefixIcon: widget.prefixIcon ??
                  (isEmpty
                      ? const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        )
                      : null),
              suffixIcon: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : (widget.showRefreshButton && widget.onFetchManual != null)
                      ? IconButton(
                          tooltip: 'Otomatik Fiyat & Bilgi Getir',
                          icon: const Icon(Icons.sync_rounded, size: 20),
                          onPressed: widget.onFetchManual,
                        )
                      : (!isEmpty
                          ? IconButton(
                              tooltip: 'Temizle',
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
                              onPressed: () {
                                widget.controller.clear();
                                widget.onChanged?.call('');
                                setState(() {});
                              },
                            )
                          : null),
            ),
            validator: widget.validator,
          ),
          if (showInlineName)
            Positioned(
              left: 14,
              right: 42,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _focusNode.requestFocus(),
                child: Row(
                  children: [
                    Text(
                      widget.controller.text.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.assetName!.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}
