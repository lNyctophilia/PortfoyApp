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
      if (widget.controller.text.trim().isNotEmpty) {
        _performSearch(widget.controller.text);
      } else {
        _hideOverlay();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideOverlay();
        }
      });
    }
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
        final screenWidth = MediaQuery.sizeOf(context).width;
        final targetWidth = math.min(size.width.clamp(200.0, 520.0), screenWidth - 32);
        final accentColor = widget.category?.color ?? AppTheme.primaryLight;

        // Kategorilere göre grupla (Yalnızca aramayla eşleşen en az 1 sonucu olan kategoriler)
        const preferredOrder = [
          AssetCategory.fon,
          AssetCategory.hisse,
          AssetCategory.kripto,
          AssetCategory.emtia,
          AssetCategory.doviz,
        ];

        final grouped = <AssetCategory, List<AssetSuggestion>>{};
        for (final cat in preferredOrder) {
          final items = _suggestions.where((s) => s.category == cat).toList();
          if (items.isNotEmpty) {
            grouped[cat] = items;
          }
        }
        for (final s in _suggestions) {
          if (!grouped.containsKey(s.category)) {
            final items = _suggestions.where((item) => item.category == s.category).toList();
            if (items.isNotEmpty) {
              grouped[s.category] = items;
            }
          }
        }

        return Positioned(
          width: targetWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
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
                      // Üst Bilgi Barı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: accentColor.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            widget.category?.buildIcon(size: 14, color: accentColor) ??
                                const Icon(Icons.travel_explore_rounded,
                                    size: 14, color: AppTheme.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              widget.category != null
                                  ? '${widget.category!.displayName} Önerileri'
                                  : 'Varlık Önerileri',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            if (_isSearching)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: accentColor,
                                ),
                              )
                            else
                              Text(
                                '${_suggestions.length} sonuç',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: AppTheme.border),

                      // Gruplanmış Öneri Listesi
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final entry in grouped.entries) ...[
                              // Kategori Başlığı (Section Header)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: entry.key.color.withValues(alpha: 0.08),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: entry.key.color.withValues(alpha: 0.15),
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
                                    entry.key.buildIcon(size: 13, color: entry.key.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      entry.key.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: entry.key.color,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: entry.key.color.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${entry.value.length}',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: entry.key.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bu kategoriye ait varlıklar (Sade, rozetsiz, minimal)
                              for (final item in entry.value)
                                InkWell(
                                  onTap: () {
                                    _hideOverlay();
                                    _focusNode.unfocus();
                                    widget.onSelected(item);
                                  },
                                  hoverColor: entry.key.color.withValues(alpha: 0.08),
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
                                                  color: Colors.white,
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
                                          color: entry.key.color.withValues(alpha: 0.65),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
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

    return CompositedTransformTarget(
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
                          Icons.question_mark_rounded,
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
    );
  }
}
