import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ModelPortfolioBadge extends StatelessWidget {
  final bool compact;

  const ModelPortfolioBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.cityInner.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cityInner.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            size: 11,
            color: AppColors.cityInner,
          ),
          const SizedBox(width: 4),
          Text(
            compact ? 'Model' : 'Model Portföy',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.cityInner,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
