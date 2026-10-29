import 'package:flutter/material.dart';
import '../models/portfolio.dart';
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
  });

  factory PeriodPerformanceRow.fromPortfolio(
    Portfolio p, {
    bool compact = false,
  }) {
    return PeriodPerformanceRow(
      compact: compact,
      dailyPercent: p.dailyChangePercent,
      dailyAmount: p.dailyProfit,
      weeklyPercent: p.hasWeeklyData ? p.weeklyChangePercent : null,
      weeklyAmount: p.hasWeeklyData ? p.weeklyProfit : null,
      monthlyPercent: p.hasMonthlyData ? p.monthlyChangePercent : null,
      monthlyAmount: p.hasMonthlyData ? p.monthlyProfit : null,
      threeMonthlyPercent: p.hasThreeMonthlyData ? p.threeMonthlyChangePercent : null,
      threeMonthlyAmount: p.hasThreeMonthlyData ? p.threeMonthlyProfit : null,
      sixMonthlyPercent: p.hasSixMonthlyData ? p.sixMonthlyChangePercent : null,
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
    final items = <Widget>[];

    void addPeriod(String title, double? percent, double? amount) {
      if (percent == null) return;
      if (items.isNotEmpty) {
        items.add(SizedBox(width: gap));
      }
      items.add(
        Expanded(
          child: _buildMetricTile(
            title: title,
            percent: percent,
            amount: amount,
          ),
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

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: items,
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
                  isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
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

    if (amount != null) {
      return Tooltip(
        message: '$title: ${Formatters.currency(amount)} (${Formatters.percent(percent)})',
        child: tile,
      );
    }

    return tile;
  }
}
