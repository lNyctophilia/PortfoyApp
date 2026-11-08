import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_category.dart';
import '../providers/portfolio_provider.dart';
import 'asset_logo.dart';
import '../models/portfolio_asset.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../models/return_mode.dart';
import 'period_performance_badge.dart';

class AssetItemTile extends StatelessWidget {
  final PortfolioAsset asset;
  final VoidCallback onDelete;
  final VoidCallback? onStatus;

  const AssetItemTile({
    super.key,
    required this.asset,
    required this.onDelete,
    this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final mode = provider.returnMode;
    final inflationRate = provider.getAssetInflation(asset.id);
    final periodInflation = provider.periodInflation;

    final displayValue = asset.valueForMode(mode);
    final displayProfit = asset.profitForMode(mode, inflationRate);
    final displayPercent = asset.profitPercentForMode(mode, inflationRate);


    final isProfit = displayProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;
    final cat = asset.category;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              final logoWidget = AssetLogo(
                iconUrl: asset.iconUrl,
                symbol: asset.symbol,
                name: asset.name,
                category: cat,
                size: 44,
                iconSize: 22,
                borderRadius: 12,
              );

              final symbolAndCategoryWidget = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    asset.symbol,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
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
              );

              final nameWidget = Text(
                asset.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              Widget? statusButtonWidget;
              if (onStatus != null) {
                statusButtonWidget = InkWell(
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
                );
              }

              final valueAndProfitWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            Formatters.currency(displayValue),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isProfit ? AppTheme.profitBg : AppTheme.lossBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mode == ReturnCalculationMode.reel
                            ? '${Formatters.currency(displayProfit)} (${Formatters.percent(displayPercent)}) • TÜFE: %${Formatters.percent(inflationRate)}'
                            : '${Formatters.currency(displayProfit)} (${Formatters.percent(displayPercent)})',
                        style: TextStyle(
                          color: profitColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              final actionButtonsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Varlığı Sil',
                    color: AppTheme.loss,
                    hoverColor: AppTheme.lossBg,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(7),
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        logoWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              symbolAndCategoryWidget,
                              const SizedBox(height: 2),
                              nameWidget,
                            ],
                          ),
                        ),
                        actionButtonsWidget,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (statusButtonWidget != null)
                          statusButtonWidget
                        else
                          const SizedBox.shrink(),
                        Flexible(
                          child: valueAndProfitWidget,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  logoWidget,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        symbolAndCategoryWidget,
                        const SizedBox(height: 2),
                        nameWidget,
                        if (statusButtonWidget != null) ...[
                          const SizedBox(height: 6),
                          statusButtonWidget,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  valueAndProfitWidget,
                  const SizedBox(width: 14),
                  actionButtonsWidget,
                ],
              );
            },
          ),

          // Dönemsel Değişimler
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(color: AppTheme.borderSubtle, height: 1),
          ),
          PeriodPerformanceRow.fromAsset(
            asset,
            mode: mode,
            periodInflation: periodInflation,
            assetInflationRate: inflationRate,
          ),
        ],
      ),
    );
  }
}
