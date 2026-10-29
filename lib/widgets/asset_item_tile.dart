import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import 'asset_logo.dart';
import '../models/portfolio_asset.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AssetItemTile extends StatelessWidget {
  final PortfolioAsset asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onStatus;

  const AssetItemTile({
    super.key,
    required this.asset,
    required this.onEdit,
    required this.onDelete,
    this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final hasStopaj =
        asset.category == AssetCategory.fon && asset.withholdingTaxAmount > 0;
    final displayProfit = hasStopaj ? asset.netProfit : asset.totalProfit;
    final displayPercent =
        hasStopaj ? asset.netProfitPercent : asset.totalProfitPercent;
    final isProfit = displayProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;
    final cat = asset.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Varlık Logosu / İkonu
              AssetLogo(
                iconUrl: asset.iconUrl,
                symbol: asset.symbol,
                name: asset.name,
                category: cat,
                size: 44,
                iconSize: 22,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),

              // İsim, Sembol ve Durumum Butonu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          asset.symbol,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cat.color,
                            ),
                          ),
                        ),
                        if (asset.category == AssetCategory.fon) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              'Stopaj: %${asset.effectiveWithholdingTaxRate.toStringAsFixed(asset.effectiveWithholdingTaxRate % 1 == 0 ? 0 : 1)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (onStatus != null) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onStatus,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primaryLight.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 13,
                                color: AppTheme.primaryLight,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Durumum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryLight,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Değer ve Kâr/Zarar
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        Formatters.currency(asset.currentValue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isProfit ? AppTheme.profitBg : AppTheme.lossBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${Formatters.currency(displayProfit)} (${Formatters.percent(displayPercent)})',
                          style: TextStyle(
                            color: profitColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (hasStopaj) ...[
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Brüt: ${Formatters.currency(asset.totalProfit)}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Net Fiyat: ${Formatters.formatPrice(asset.netCurrentPrice)} ₺',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Düzenle & Sil butonları
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Varlığı Düzenle',
                    color: AppTheme.textSecondary,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Varlığı Sil',
                    color: AppTheme.loss,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),

          // Dönemsel Değişimler
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(color: AppTheme.borderSubtle, height: 1),
          ),
          Row(
            children: [
              _buildSmallStat('1G', asset.dailyChangePercent, asset.dailyProfit),
              if (asset.hasWeeklyData) ...[
                const SizedBox(width: 4),
                _buildSmallStat('1H', asset.weeklyChangePercent, asset.weeklyProfit),
              ],
              if (asset.hasMonthlyData) ...[
                const SizedBox(width: 4),
                _buildSmallStat('1A', asset.monthlyChangePercent, asset.monthlyProfit),
              ],
              if (asset.hasThreeMonthlyData) ...[
                const SizedBox(width: 4),
                _buildSmallStat('3A', asset.threeMonthlyChangePercent, asset.threeMonthlyProfit),
              ],
              if (asset.hasSixMonthlyData) ...[
                const SizedBox(width: 4),
                _buildSmallStat('6A', asset.sixMonthlyChangePercent, asset.sixMonthlyProfit),
              ],
              if (asset.hasYearlyData) ...[
                const SizedBox(width: 4),
                _buildSmallStat('1Y', asset.yearlyChangePercent, asset.yearlyProfit),
              ],
              const SizedBox(width: 4),
              _buildSmallStat('Ömür', asset.totalProfitPercent, asset.totalProfit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, double val, [double? profit]) {
    final isPos = val >= 0;
    final col = isPos ? AppTheme.profit : AppTheme.loss;
    final bg = isPos ? AppTheme.profitBg : AppTheme.lossBg;
    final statWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label ',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              Formatters.percent(val),
              style: TextStyle(
                color: col,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (profit != null) {
      return Expanded(
        child: Tooltip(
          message: '$label Kâr/Zarar: ${Formatters.currency(profit)} (${Formatters.percent(val)})',
          child: statWidget,
        ),
      );
    }

    return Expanded(child: statWidget);
  }
}
