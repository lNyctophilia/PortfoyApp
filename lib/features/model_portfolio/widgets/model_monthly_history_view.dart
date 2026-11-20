import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/model_portfolio_analysis.dart';

class ModelMonthlyHistoryView extends StatelessWidget {
  final ModelPortfolioAnalysis analysis;
  final bool isMobile;

  const ModelMonthlyHistoryView({
    super.key,
    required this.analysis,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final history = analysis.monthlyHistory;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.calendar_month_outlined,
                size: 40,
                color: AppTheme.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'Aylık getiri geçmişi bulunamadı',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ÖZET İSTATİSTİKLER (Ortalama, En İyi, En Kötü)
        _buildStatsBar(),
        const SizedBox(height: 14),

        // AYLIK GEÇMİŞ LİSTESİ
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildMonthRow(item);
          },
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final avg = analysis.averageMonthlyReturn;
    final best = analysis.bestMonth;
    final worst = analysis.worstMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildStatItem('Ort. Aylık Getiri', Formatters.percent(avg),
                    avg >= 0 ? AppColors.success : AppColors.danger),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.borderSubtle, height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'En İyi Ay',
                        best != null ? Formatters.percent(best.returnPercent) : '-',
                        AppColors.success,
                        subtitle: best?.monthLabel,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: AppTheme.borderSubtle,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'En Kötü Ay',
                        worst != null ? Formatters.percent(worst.returnPercent) : '-',
                        AppColors.danger,
                        subtitle: worst?.monthLabel,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildStatItem('Ortalama Aylık Getiri', Formatters.percent(avg),
                      avg >= 0 ? AppColors.success : AppColors.danger),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: AppTheme.borderSubtle,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildStatItem(
                    'En İyi Ay',
                    best != null ? Formatters.percent(best.returnPercent) : '-',
                    AppColors.success,
                    subtitle: best?.monthLabel,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: AppTheme.borderSubtle,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildStatItem(
                    'En Kötü Ay',
                    worst != null ? Formatters.percent(worst.returnPercent) : '-',
                    AppColors.danger,
                    subtitle: worst?.monthLabel,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    Color valueColor, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '($subtitle)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMonthRow(ModelMonthReturn item) {
    final isProfit = item.returnPercent >= 0;
    final color = isProfit ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.hasWarning
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.hasWarning
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          // Ay ikonu ve ismi
          const Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.monthLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Ünlem uyarısı (Eğer bu ayda bir veya daha fazla varlığın max tarihi aşıldıysa)
          if (item.hasWarning) ...[
            Tooltip(
              message: item.warningMessage,
              waitDuration: const Duration(milliseconds: 150),
              triggerMode: TooltipTriggerMode.tap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.warnedAssetNames.length == 1
                          ? item.warnedAssetNames.first
                          : '${item.warnedAssetNames.length} Varlık',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Getiri Yüzdesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              Formatters.percent(item.returnPercent),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
