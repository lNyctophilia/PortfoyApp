import 'package:flutter/gestures.dart';
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
            calcRealPercent(p.dailyChangePercent, periodInflation.daily) ?? 0.0,
        dailyAmount: calcRealAmount(p.dailyProfit, periodInflation.daily) ?? 0.0,
        weeklyPercent: p.hasWeeklyData
            ? (calcRealPercent(p.weeklyChangePercent, periodInflation.weekly) ?? 0.0)
            : 0.0,
        weeklyAmount: p.hasWeeklyData
            ? (calcRealAmount(p.weeklyProfit, periodInflation.weekly) ?? 0.0)
            : 0.0,
        monthlyPercent: p.hasMonthlyData
            ? (calcRealPercent(p.monthlyChangePercent, periodInflation.monthly) ?? 0.0)
            : 0.0,
        monthlyAmount: p.hasMonthlyData
            ? (calcRealAmount(p.monthlyProfit, periodInflation.monthly) ?? 0.0)
            : 0.0,
        threeMonthlyPercent: p.hasThreeMonthlyData
            ? (calcRealPercent(
                    p.threeMonthlyChangePercent, periodInflation.threeMonthly) ??
                0.0)
            : 0.0,
        threeMonthlyAmount: p.hasThreeMonthlyData
            ? (calcRealAmount(
                    p.threeMonthlyProfit, periodInflation.threeMonthly) ??
                0.0)
            : 0.0,
        sixMonthlyPercent: p.hasSixMonthlyData
            ? (calcRealPercent(
                    p.sixMonthlyChangePercent, periodInflation.sixMonthly) ??
                0.0)
            : 0.0,
        sixMonthlyAmount: p.hasSixMonthlyData
            ? (calcRealAmount(p.sixMonthlyProfit, periodInflation.sixMonthly) ??
                0.0)
            : 0.0,
        yearlyPercent: p.hasYearlyData
            ? (calcRealPercent(p.yearlyChangePercent, periodInflation.yearly) ??
                0.0)
            : 0.0,
        yearlyAmount: p.hasYearlyData
            ? (calcRealAmount(p.yearlyProfit, periodInflation.yearly) ?? 0.0)
            : 0.0,
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
        weeklyPercent: p.hasWeeklyData ? p.weeklyChangePercent : 0.0,
        weeklyAmount: p.hasWeeklyData ? p.weeklyProfit : 0.0,
        monthlyPercent: p.hasMonthlyData ? p.monthlyChangePercent : 0.0,
        monthlyAmount: p.hasMonthlyData ? p.monthlyProfit : 0.0,
        threeMonthlyPercent:
            p.hasThreeMonthlyData ? p.threeMonthlyChangePercent : 0.0,
        threeMonthlyAmount: p.hasThreeMonthlyData ? p.threeMonthlyProfit : 0.0,
        sixMonthlyPercent:
            p.hasSixMonthlyData ? p.sixMonthlyChangePercent : 0.0,
        sixMonthlyAmount: p.hasSixMonthlyData ? p.sixMonthlyProfit : 0.0,
        yearlyPercent: p.hasYearlyData ? p.yearlyChangePercent : 0.0,
        yearlyAmount: p.hasYearlyData ? p.yearlyProfit : 0.0,
        allTimePercent: p.netTotalProfitPercent,
        allTimeAmount: p.netTotalProfit,
      );
    }

    return PeriodPerformanceRow(
      compact: compact,
      mode: mode,
      dailyPercent: p.dailyChangePercent,
      dailyAmount: p.dailyProfit,
      weeklyPercent: p.hasWeeklyData ? p.weeklyChangePercent : 0.0,
      weeklyAmount: p.hasWeeklyData ? p.weeklyProfit : 0.0,
      monthlyPercent: p.hasMonthlyData ? p.monthlyChangePercent : 0.0,
      monthlyAmount: p.hasMonthlyData ? p.monthlyProfit : 0.0,
      threeMonthlyPercent:
          p.hasThreeMonthlyData ? p.threeMonthlyChangePercent : 0.0,
      threeMonthlyAmount: p.hasThreeMonthlyData ? p.threeMonthlyProfit : 0.0,
      sixMonthlyPercent:
          p.hasSixMonthlyData ? p.sixMonthlyChangePercent : 0.0,
      sixMonthlyAmount: p.hasSixMonthlyData ? p.sixMonthlyProfit : 0.0,
      yearlyPercent: p.hasYearlyData ? p.yearlyChangePercent : 0.0,
      yearlyAmount: p.hasYearlyData ? p.yearlyProfit : 0.0,
      allTimePercent: p.totalProfitPercent,
      allTimeAmount: p.totalProfit,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;
    final metricTiles = <Widget>[];

    void addPeriod(String title, double? percent, double? amount) {
      metricTiles.add(
        _buildMetricTile(
          title: title,
          percent: percent ?? 0.0,
          amount: amount,
        ),
      );
    }

    addPeriod('1G', dailyPercent, dailyAmount);
    addPeriod('1H', weeklyPercent, weeklyAmount);
    addPeriod('1A', monthlyPercent, monthlyAmount);
    addPeriod('3A', threeMonthlyPercent, threeMonthlyAmount);
    addPeriod('6A', sixMonthlyPercent, sixMonthlyAmount);
    addPeriod('1Y', yearlyPercent, yearlyAmount);
    addPeriod('Ömür Boyu', allTimePercent, allTimeAmount);

    if (metricTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Her kutucuk sadece yüzde ile ~48-52px genişlik ister.
        final minRequiredWidth = metricTiles.length * 52.0 + (metricTiles.length - 1) * gap;

        // Alan yetersizse (dar ekran veya dar portföy kartı) mouse tekerleği destekli yatay kaydırılabilir yap
        if (constraints.maxWidth < minRequiredWidth) {
          return _ScrollablePeriodStrip(
            gap: gap,
            children: metricTiles,
          );
        }

        // Geniş ekranda tüm alana dengeli ve ferah dağıt (tüm 7 tarih tek bakışta sığar)
        return Row(
          children: [
            for (int i = 0; i < metricTiles.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
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
    final isNeutral = percent.abs() < 0.0001 && (amount == null || amount.abs() < 0.01);
    final isPositive = percent > 0;

    final Color color;
    final Color bg;
    final Color borderColor;
    final IconData iconData;

    if (isNeutral) {
      color = AppTheme.textMuted;
      bg = AppTheme.surfaceLight.withValues(alpha: 0.6);
      borderColor = AppTheme.borderSubtle;
      iconData = Icons.remove_rounded;
    } else if (isPositive) {
      color = AppTheme.profit;
      bg = AppTheme.profitBg;
      borderColor = color.withValues(alpha: 0.25);
      iconData = Icons.arrow_drop_up_rounded;
    } else {
      color = AppTheme.loss;
      bg = AppTheme.lossBg;
      borderColor = color.withValues(alpha: 0.25);
      iconData = Icons.arrow_drop_down_rounded;
    }

    final tile = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
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
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: color,
                  size: isNeutral ? 13 : 16,
                ),
                Text(
                  isNeutral
                      ? '%0,00'
                      : Formatters.percent(percent, includeSign: false),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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

/// PC ve web ekranlarında fare tekerleğiyle (mouse wheel) ve dokunmatik olarak
/// pürüzsüz yatay kaydırma sağlayan şerit bileşeni.
class _ScrollablePeriodStrip extends StatefulWidget {
  final List<Widget> children;
  final double gap;

  const _ScrollablePeriodStrip({
    required this.children,
    this.gap = 6.0,
  });

  @override
  State<_ScrollablePeriodStrip> createState() => _ScrollablePeriodStripState();
}

class _ScrollablePeriodStripState extends State<_ScrollablePeriodStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent && _scrollController.hasClients) {
          final delta = pointerSignal.scrollDelta.dy != 0
              ? pointerSignal.scrollDelta.dy
              : pointerSignal.scrollDelta.dx;
          final target = (_scrollController.offset + delta).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(target);
        }
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.children.length; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                  ),
                  child: widget.children[i],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
