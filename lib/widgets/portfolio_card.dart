import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio.dart';
import '../models/return_mode.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'category_distribution_bar.dart';
import 'net_gross_badge.dart';
import 'period_performance_badge.dart';

class PortfolioCard extends StatefulWidget {
  final Portfolio portfolio;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleVisibility;

  const PortfolioCard({
    super.key,
    required this.portfolio,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onToggleVisibility,
  });

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isHovered != value) {
        setState(() {
          _isHovered = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.portfolio;
    final provider = context.watch<PortfolioProvider>();
    final mode = provider.returnMode;
    final hasStopaj = p.totalWithholdingTax > 0;
    final inflationRates = provider.assetInflationRates;
    final displayValue = p.valueForMode(mode);
    final displayProfit = p.profitForMode(mode, inflationRates);
    final displayProfitPercent = p.profitPercentForMode(mode, inflationRates);
    final isProfit = displayProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: p.isVisible ? 1.0 : 0.72,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? AppTheme.primaryLight : AppTheme.borderSubtle,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ÜST KISIM: Sol tarafta Portföy İsmi, Sağ tarafta Rozetler ve Menü
              Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sol: Portföy İsmi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sağ Üst: Rozetler ve Menü
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!p.isVisible) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_off_rounded,
                                    size: 11,
                                    color: AppTheme.warning,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Gizli',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const SizedBox(width: 2),
                          PopupMenuButton<String>(
                            tooltip: 'Seçenekler',
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                            color: AppTheme.surfaceElevated,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            onSelected: (value) {
                              if (value == 'toggle_visibility') {
                                widget.onToggleVisibility?.call();
                              } else if (value == 'edit') {
                                widget.onEdit();
                              } else if (value == 'delete') {
                                widget.onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle_visibility',
                                child: Row(
                                  children: [
                                    Icon(
                                      p.isVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 16,
                                      color: p.isVisible
                                          ? AppTheme.warning
                                          : AppTheme.profit,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      p.isVisible
                                          ? 'Cüzdandan Gizle'
                                          : 'Cüzdanda Göster',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Portföyü Düzenle'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 16, color: AppTheme.loss),
                                    SizedBox(width: 8),
                                    Text('Portföyü Sil',
                                        style: TextStyle(color: AppTheme.loss)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
              const SizedBox(height: 12),

              // TOPLAM DEĞER & KAZANÇ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Portföy Değeri',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasStopaj || mode == ReturnCalculationMode.reel) ...[
                              const SizedBox(width: 6),
                              NetGrossBadge(mode: mode),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.currency(displayValue),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Toplam Kazanç
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? AppTheme.profitBg
                            : AppTheme.lossBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: profitColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isProfit
                                  ? Icons.arrow_outward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: profitColor,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${Formatters.currency(displayProfit)} (${Formatters.percent(displayProfitPercent)})',
                              style: TextStyle(
                                color: profitColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppTheme.borderSubtle, height: 1),
              ),

              // ORTA KISIM: TARİHSEL VERİLER (GÜNLÜK, HAFTALIK, AYLIK, YILLIK)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarihsel Değişimler',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PeriodPerformanceRow.fromPortfolio(
                    p,
                    compact: true,
                    mode: mode,
                    periodInflation: provider.periodInflation,
                    assetInflationRates: inflationRates,
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppTheme.borderSubtle, height: 1),
              ),

              // EN ALT KISIM: VARLIK DAĞILIMI
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Varlık Dağılımı',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Yönetmek için tıkla →',
                        style: TextStyle(
                          color: _isHovered
                              ? AppTheme.primaryLight
                              : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CategoryDistributionBar(
                    portfolio: p,
                    showAmounts: false,
                    maxItems: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
