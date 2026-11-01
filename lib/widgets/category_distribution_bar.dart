import 'package:flutter/material.dart';
import '../models/portfolio.dart';
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
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFFE11D48), // Rose
    Color(0xFF84CC16), // Lime
    Color(0xFF0284C7), // Sky
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
          color: const Color(0xFF94A3B8),
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
