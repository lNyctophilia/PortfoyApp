import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/model_portfolio_analysis.dart';

class ModelPeriodPerformanceRow extends StatelessWidget {
  final ModelPortfolioAnalysis analysis;
  final bool compact;

  const ModelPeriodPerformanceRow({
    super.key,
    required this.analysis,
    this.compact = false,
  });

  static const List<String> periods = [
    '1G',
    '1H',
    '1A',
    '3A',
    '6A',
    '1Y',
    '2Y',
    '3Y',
    '5Y',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 9 kutucuk için minimum genişlik ihtiyacı
        final neededWidth = periods.length * 62.0;

        if (totalWidth >= neededWidth) {
          return Row(
            children: periods.map((p) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildTile(p, compact: compact),
                ),
              );
            }).toList(),
          );
        }

        return _ScrollableModelPeriodStrip(
          analysis: analysis,
          compact: compact,
        );
      },
    );
  }

  Widget _buildTile(String period, {required bool compact}) {
    final val = analysis.periodReturns[period] ?? 0.0;
    final isProfit = val >= 0;
    final color = isProfit ? AppColors.success : AppColors.danger;
    final missing = analysis.getMissingAssetsForPeriod(period);
    final hasWarning = missing.isNotEmpty;

    final tile = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasWarning
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppTheme.borderSubtle,
          width: hasWarning ? 1.2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                period,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasWarning) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 11,
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.percent(val),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (hasWarning) {
      return Tooltip(
        message: 'Bu dönemin tamamını kapsamayan varlıklar: ${missing.join(', ')}',
        waitDuration: const Duration(milliseconds: 200),
        child: tile,
      );
    }

    return tile;
  }
}

class _ScrollableModelPeriodStrip extends StatefulWidget {
  final ModelPortfolioAnalysis analysis;
  final bool compact;

  const _ScrollableModelPeriodStrip({
    required this.analysis,
    required this.compact,
  });

  @override
  State<_ScrollableModelPeriodStrip> createState() =>
      _ScrollableModelPeriodStripState();
}

class _ScrollableModelPeriodStripState
    extends State<_ScrollableModelPeriodStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent && _controller.hasClients) {
          final newOffset = (_controller.offset + pointerSignal.scrollDelta.dy)
              .clamp(0.0, _controller.position.maxScrollExtent);
          _controller.jumpTo(newOffset);
        }
      },
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ModelPeriodPerformanceRow.periods.map((p) {
            final val = widget.analysis.periodReturns[p] ?? 0.0;
            final isProfit = val >= 0;
            final color = isProfit ? AppColors.success : AppColors.danger;
            final missing = widget.analysis.getMissingAssetsForPeriod(p);
            final hasWarning = missing.isNotEmpty;

            final tile = Container(
              constraints: const BoxConstraints(minWidth: 58),
              margin: const EdgeInsets.only(right: 6),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 6 : 8,
                vertical: widget.compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasWarning
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : AppTheme.borderSubtle,
                  width: hasWarning ? 1.2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasWarning) ...[
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.percent(val),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );

            if (hasWarning) {
              return Tooltip(
                message:
                    'Bu dönemin tamamını kapsamayan varlıklar: ${missing.join(', ')}',
                waitDuration: const Duration(milliseconds: 200),
                child: tile,
              );
            }
            return tile;
          }).toList(),
        ),
      ),
    );
  }
}
