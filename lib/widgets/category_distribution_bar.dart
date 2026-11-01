import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CategoryDistributionBar extends StatelessWidget {
  final Portfolio portfolio;
  final bool showAmounts;
  final int? maxItems;

  const CategoryDistributionBar({
    super.key,
    required this.portfolio,
    this.showAmounts = false,
    this.maxItems,
  });

  static const List<Color> _palette = [
    AppColors.accentLight, // 0xFF3A86FF
    AppColors.cityInner,   // 0xFF48BFE3
    AppColors.success,     // 0xFF06D6A0
    AppColors.warning,     // 0xFFF9A826
    AppColors.danger,      // 0xFFEF476F
    Color(0xFF8B5CF6),     // Purple
    Color(0xFF14B8A6),     // Teal
    Color(0xFFFB923C),     // Orange
    Color(0xFF60A5FA),     // Light Blue
    Color(0xFFF472B6),     // Pink
    Color(0xFFA3E635),     // Lime
    Color(0xFF38BDF8),     // Sky
  ];

  @override
  Widget build(BuildContext context) {
    final allocations = portfolio.assetAllocations;

    if (allocations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerLeft,
        child: const Text(
          'Henüz varlık eklenmedi (%0 Dağılım)',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final List<_AllocationDisplayItem> displayItems = [];
    final bool shouldGroup = maxItems != null && allocations.length > maxItems!;
    final int takeCount = shouldGroup ? (maxItems! - 1) : allocations.length;

    for (int i = 0; i < takeCount; i++) {
      final a = allocations[i];
      displayItems.add(
        _AllocationDisplayItem(
          label: a.symbol,
          percentage: a.percentage,
          value: a.value,
          color: _palette[i % _palette.length],
        ),
      );
    }

    if (shouldGroup) {
      final remaining = allocations.sublist(takeCount);
      final remainingPct = remaining.fold(0.0, (sum, a) => sum + a.percentage);
      final remainingVal = remaining.fold(0.0, (sum, a) => sum + a.value);

      displayItems.add(
        _AllocationDisplayItem(
          label: '+${remaining.length} Diğer',
          percentage: remainingPct,
          value: remainingVal,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dağılım İlerleme Çubuğu (Segmented bar)
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: displayItems.map((item) {
                return Expanded(
                  flex: (item.percentage * 10).round().clamp(1, 1000),
                  child: Container(
                    color: item.color,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Yüzde Etiketleri (Varlık bazlı etiketler)
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: displayItems.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${Formatters.percent(item.percentage, includeSign: false)} ${item.label}',
                    style: TextStyle(
                      color: item.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showAmounts) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${Formatters.compactCurrency(item.value)})',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AllocationDisplayItem {
  final String label;
  final double percentage;
  final double value;
  final Color color;

  const _AllocationDisplayItem({
    required this.label,
    required this.percentage,
    required this.value,
    required this.color,
  });
}
