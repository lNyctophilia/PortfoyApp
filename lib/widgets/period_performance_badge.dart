import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../models/return_mode.dart';
import '../services/inflation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PeriodPerformanceRow extends StatelessWidget {
  final double? dailyPercent;
  final double? dailyAmount;
  final double? weeklyPercent;
  final double? weeklyAmount;
  final double? monthlyPercent;
  final double? monthlyAmount;
  final double? threeMonthlyPercent;
  final double? threeMonthlyAmount;
  final double? sixMonthlyPercent;
  final double? sixMonthlyAmount;
  final double? yearlyPercent;
  final double? yearlyAmount;
  final double? allTimePercent;
  final double? allTimeAmount;
  final bool compact;
  final ReturnCalculationMode mode;

  const PeriodPerformanceRow({
    super.key,
    this.dailyPercent,
    this.dailyAmount,
    this.weeklyPercent,
    this.weeklyAmount,
    this.monthlyPercent,
    this.monthlyAmount,
    this.threeMonthlyPercent,
    this.threeMonthlyAmount,
    this.sixMonthlyPercent,
    this.sixMonthlyAmount,
    this.yearlyPercent,
    this.yearlyAmount,
    this.allTimePercent,
    this.allTimeAmount,
    this.compact = false,
    this.mode = ReturnCalculationMode.brut,
  });

  factory PeriodPerformanceRow.fromPortfolio(
    Portfolio p, {
    bool compact = false,
    ReturnCalculationMode mode = ReturnCalculationMode.brut,
    PeriodInflationData? periodInflation,
    Map<String, double>? assetInflationRates,
  }) {
    if (mode == ReturnCalculationMode.reel && periodInflation != null) {
      double? calcRealPercent(double? nominal, double inf) {
        if (nominal == null) return null;
        return InflationService.calculateRealReturnPercent(
          nominalReturnPercent: nominal,
          inflationPercent: inf,
        );
      }

      double? calcRealAmount(double? nominalProfit, double inf) {
        if (nominalProfit == null || p.totalValue <= 0) return null;
        final prev = p.totalValue - nominalProfit;
        return p.totalValue - (prev * (1.0 + (inf / 100.0)));
      }

      return PeriodPerformanceRow(
        compact: compact,
        mode: mode,
        dailyPercent:
            calcRealPercent(p.dailyChangePercent, periodInflation.daily),
        dailyAmount: calcRealAmount(p.dailyProfit, periodInflation.daily),
        weeklyPercent: p.hasWeeklyData
            ? calcRealPercent(p.weeklyChangePercent, periodInflation.weekly)
            : null,
        weeklyAmount: p.hasWeeklyData
            ? calcRealAmount(p.weeklyProfit, periodInflation.weekly)
            : null,
        monthlyPercent: p.hasMonthlyData
            ? calcRealPercent(p.monthlyChangePercent, periodInflation.monthly)
            : null,
        monthlyAmount: p.hasMonthlyData
            ? calcRealAmount(p.monthlyProfit, periodInflation.monthly)
            : null,
        threeMonthlyPercent: p.hasThreeMonthlyData
            ? calcRealPercent(
                p.threeMonthlyChangePercent, periodInflation.threeMonthly)
            : null,
        threeMonthlyAmount: p.hasThreeMonthlyData
            ? calcRealAmount(
                p.threeMonthlyProfit, periodInflation.threeMonthly)
            : null,
        sixMonthlyPercent: p.hasSixMonthlyData
            ? calcRealPercent(
                p.sixMonthlyChangePercent, periodInflation.sixMonthly)
            : null,
        sixMonthlyAmount: p.hasSixMonthlyData
            ? calcRealAmount(p.sixMonthlyProfit, periodInflation.sixMonthly)
            : null,
        yearlyPercent: p.hasYearlyData
            ? calcRealPercent(p.yearlyChangePercent, periodInflation.yearly)
            : null,
        yearlyAmount: p.hasYearlyData
            ? calcRealAmount(p.yearlyProfit, periodInflation.yearly)
            : null,
        allTimePercent: p.realTotalProfitPercent(assetInflationRates),
        allTimeAmount: p.realTotalProfit(assetInflationRates),
      );
    }

    if (mode == ReturnCalculationMode.net) {
      return PeriodPerformanceRow(
        compact: compact,
        mode: mode,
        dailyPercent: p.dailyChangePercent,
        dailyAmount: p.dailyProfit,
        weeklyPercent: p.hasWeeklyData ? p.weeklyChangePercent : null,
        weeklyAmount: p.hasWeeklyData ? p.weeklyProfit : null,
        monthlyPercent: p.hasMonthlyData ? p.monthlyChangePercent : null,
        monthlyAmount: p.hasMonthlyData ? p.monthlyProfit : null,
        threeMonthlyPercent:
            p.hasThreeMonthlyData ? p.threeMonthlyChangePercent : null,
        threeMonthlyAmount: p.hasThreeMonthlyData ? p.threeMonthlyProfit : null,
        sixMonthlyPercent:
            p.hasSixMonthlyData ? p.sixMonthlyChangePercent : null,
        sixMonthlyAmount: p.hasSixMonthlyData ? p.sixMonthlyProfit : null,
        yearlyPercent: p.hasYearlyData ? p.yearlyChangePercent : null,
        yearlyAmount: p.hasYearlyData ? p.yearlyProfit : null,
        allTimePercent: p.netTotalProfitPercent,
        allTimeAmount: p.netTotalProfit,
      );
    }

    return PeriodPerformanceRow(
      compact: compact,
      mode: mode,
      dailyPercent: p.dailyChangePercent,
      dailyAmount: p.dailyProfit,
      weeklyPercent: p.hasWeeklyData ? p.weeklyChangePercent : null,
      weeklyAmount: p.hasWeeklyData ? p.weeklyProfit : null,
      monthlyPercent: p.hasMonthlyData ? p.monthlyChangePercent : null,
      monthlyAmount: p.hasMonthlyData ? p.monthlyProfit : null,
      threeMonthlyPercent:
          p.hasThreeMonthlyData ? p.threeMonthlyChangePercent : null,
      threeMonthlyAmount: p.hasThreeMonthlyData ? p.threeMonthlyProfit : null,
      sixMonthlyPercent:
          p.hasSixMonthlyData ? p.sixMonthlyChangePercent : null,
      sixMonthlyAmount: p.hasSixMonthlyData ? p.sixMonthlyProfit : null,
      yearlyPercent: p.hasYearlyData ? p.yearlyChangePercent : null,
      yearlyAmount: p.hasYearlyData ? p.yearlyProfit : null,
      allTimePercent: p.totalProfitPercent,
      allTimeAmount: p.totalProfit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 4.0 : 8.0;
    final metricTiles = <Widget>[];

    void addPeriod(String title, double? percent, double? amount) {
      if (percent == null) return;
      metricTiles.add(
        _buildMetricTile(
          title: title,
          percent: percent,
          amount: amount,
        ),
      );
    }

    addPeriod(compact ? '1G' : 'Günlük', dailyPercent, dailyAmount);
    addPeriod(compact ? '1H' : 'Haftalık', weeklyPercent, weeklyAmount);
    addPeriod(compact ? '1A' : '1 Ay', monthlyPercent, monthlyAmount);
    addPeriod(compact ? '3A' : '3 Ay', threeMonthlyPercent, threeMonthlyAmount);
    addPeriod(compact ? '6A' : '6 Ay', sixMonthlyPercent, sixMonthlyAmount);
    addPeriod(compact ? '1Y' : '1 Yıl', yearlyPercent, yearlyAmount);
    addPeriod(compact ? 'Ömür' : 'Ömür Boyu', allTimePercent, allTimeAmount);

    if (metricTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minRequiredWidth = metricTiles.length * (compact ? 44.0 : 82.0) + (metricTiles.length - 1) * gap;
        // Eğer alan dar ise yatay kaydırılabilir yap (özellikle mobil telefonlar için)
        if (constraints.maxWidth < minRequiredWidth || !compact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < metricTiles.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: compact ? 44 : 76,
                    ),
                    child: metricTiles[i],
                  ),
                ],
              ],
            ),
          );
        }

        // Geniş ekranda tüm alana dengeli dağıt
        return Row(
          children: [
            for (int i = 0; i < metricTiles.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: metricTiles[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required double percent,
    double? amount,
  }) {
    final isPositive = percent >= 0;
    final color = isPositive ? AppTheme.profit : AppTheme.loss;
    final bg = isPositive ? AppTheme.profitBg : AppTheme.lossBg;

    final tile = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 6,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
            ),
          ),
          if (amount != null && !compact) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.currency(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: color,
                  size: compact ? 15 : 18,
                ),
                Text(
                  Formatters.percent(percent, includeSign: false),
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final modeSuffix = mode == ReturnCalculationMode.reel ? ' (Reel)' : '';
    if (amount != null) {
      return Tooltip(
        message:
            '$title$modeSuffix: ${Formatters.currency(amount)} (${Formatters.percent(percent)})',
        child: tile,
      );
    }

    return Tooltip(
      message: '$title$modeSuffix: ${Formatters.percent(percent)}',
      child: tile,
    );
  }
}
