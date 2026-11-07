import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../services/asset_catalog_service.dart';
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
        final targetWidth = math.min(size.width.clamp(200.0, 480.0), screenWidth - 32);
        final accentColor = widget.category?.color ?? AppTheme.primaryLight;
        return Positioned(
          width: targetWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
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
                      // Başlık / Kategori Bilgisi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        color: accentColor.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            widget.category?.buildIcon(
                                    size: 14, color: accentColor) ??
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
                      // Öneri Listesi
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, _) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppTheme.border,
                            indent: 48,
                          ),
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            final itemColor = item.category.color;
                            return InkWell(
                              onTap: () {
                                _hideOverlay();
                                _focusNode.unfocus();
                                widget.onSelected(item);
                              },
                              hoverColor: itemColor.withValues(alpha: 0.12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.symbol,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: itemColor.withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.category.shortName,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: itemColor,
                                                  ),
                                                ),
                                              ),
                                              if (item.subtitle != null) ...[
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.border,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      item.subtitle!,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
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
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.north_west_rounded,
                                      size: 14,
                                      color: itemColor.withValues(alpha: 0.7),
                                    ),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.characters,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: 'Kod / Sembol *',
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.tag_rounded),
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
              : IconButton(
                  tooltip: 'Otomatik Fiyat & Bilgi Getir',
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  onPressed: widget.onFetchManual,
                ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
