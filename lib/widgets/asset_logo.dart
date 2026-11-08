import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/asset_category.dart';
import '../services/market_data_service.dart';
import '../theme/app_theme.dart';

class AssetLogo extends StatefulWidget {
  final String? iconUrl;
  final String symbol;
  final String? name;
  final AssetCategory category;
  final double size;
  final double iconSize;
  final double borderRadius;

  const AssetLogo({
    super.key,
    required this.iconUrl,
    required this.symbol,
    this.name,
    required this.category,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 12,
  });

  @override
  State<AssetLogo> createState() => _AssetLogoState();
}

class _AssetLogoState extends State<AssetLogo> {
  final List<String> _candidateUrls = [];
  int _candidateIndex = 0;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _resolveLogo();
  }

  @override
  void didUpdateWidget(covariant AssetLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconUrl != widget.iconUrl ||
        oldWidget.symbol != widget.symbol ||
        oldWidget.category != widget.category ||
        oldWidget.name != widget.name) {
      _resolveLogo();
    }
  }

  void _resolveLogo() {
    _candidateUrls.clear();
    _candidateIndex = 0;

    void addCandidate(String? url) {
      if (url != null && url.trim().isNotEmpty) {
        final u = url.trim();
        if (!_candidateUrls.contains(u)) {
          _candidateUrls.add(u);
        }
      }
    }

    // 1. Doğrudan widget üzerinden gelen iconUrl
    addCandidate(widget.iconUrl);

    // 2. Fon kategorisi için kurum adayları (TEB, İş, Akbank vb.)
    if (widget.category == AssetCategory.fon) {
      final candidates = MarketDataService.resolveFundLogoCandidates(
        widget.symbol,
        widget.name ?? '',
      );
      for (final c in candidates) {
        addCandidate(c);
      }
    }

    // 3. Bilinen varlık logosu
    final known = MarketDataService.getKnownAssetLogo(
      widget.symbol,
      widget.category,
      widget.name,
    );
    addCandidate(known);

    if (_candidateUrls.isNotEmpty) {
      if (mounted) setState(() {});
      return;
    }

    // 4. Henüz aday bulunamadıysa arka planda API'den sorgula
    if (widget.symbol.trim().isNotEmpty && !_isFetching) {
      _isFetching = true;
      MarketDataService.fetchAssetLogo(
        widget.symbol,
        widget.category,
        widget.name,
      ).then((fetched) {
        if (mounted) {
          setState(() {
            _isFetching = false;
            addCandidate(fetched);
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _isFetching = false;
          });
        }
      });
    }
  }

  void _tryNextCandidate() {
    if (_candidateIndex + 1 < _candidateUrls.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _candidateIndex++;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final fallback = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: cat.color.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Center(
        child: cat.buildIcon(size: widget.iconSize, color: cat.color),
      ),
    );

    if (widget.symbol.trim().isEmpty) {
      return fallback;
    }

    final effectiveUrl = (_candidateIndex < _candidateUrls.length)
        ? _candidateUrls[_candidateIndex]
        : null;

    // Emtia için tam boyutlu, ortalı altın vektör kartı oluşturucu
    Widget buildGoldCard() {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFFD69A00),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              widget.borderRadius > 1 ? widget.borderRadius - 1 : widget.borderRadius),
          child: SvgPicture.string(
            '''<svg width="${widget.size}" height="${widget.size}" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M0 0h18v18H0V0z" fill="#D69A00"/>
  <g transform="translate(0.217, 0.500)">
    <path d="M7.656 5h2.687c.09 0 .17.04.217.107L12.06 7.68c.096.143-.024.32-.216.32H5.715c-.193 0-.313-.177-.217-.32L7.06 5.107A.26.26 0 017.656 5z" fill="#fff"/>
    <path d="M4.156 9h2.687c.09 0 .17.04.217.107L8.56 11.68c.096.143-.024.32-.217.32H2.215c-.193 0-.313-.177-.217-.32L3.94 9.107A.26.26 0 014.156 9z" fill="#fff"/>
    <path d="M11.156 9h2.687c.09 0 .17.04.217.107L15.56 11.68c.096.143-.024.32-.216.32H9.215c-.193 0-.313-.177-.217-.32L10.94 9.107A.26.26 0 0111.156 9z" fill="#fff"/>
  </g>
</svg>''',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      if (cat == AssetCategory.emtia) {
        return buildGoldCard();
      }
      return fallback;
    }

    // Altın için yerel yüksek çözünürlüklü vektör logosu (network beklemeden anında yüklenir ve tam kart boyutunda ortalanır)
    if (cat == AssetCategory.emtia &&
        (effectiveUrl.contains('metal/gold.svg') ||
            (!effectiveUrl.contains('metal/silver.svg') &&
                !effectiveUrl.contains('metal/platinum.svg')))) {
      return buildGoldCard();
    }

    final isSvg = effectiveUrl.toLowerCase().contains('.svg');

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: cat.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            widget.borderRadius > 1 ? widget.borderRadius - 1 : widget.borderRadius),
        child: isSvg
            ? SvgPicture.network(
                effectiveUrl,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => Center(
                  child: SizedBox(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cat.color,
                    ),
                  ),
                ),
                errorBuilder: (context, error, stackTrace) {
                  _tryNextCandidate();
                  return Center(
                    child: cat.buildIcon(size: widget.iconSize, color: cat.color),
                  );
                },
              )
            : Image.network(
                effectiveUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  _tryNextCandidate();
                  return Center(
                    child: cat.buildIcon(size: widget.iconSize, color: cat.color),
                  );
                },
              ),
      ),
    );
  }
}
