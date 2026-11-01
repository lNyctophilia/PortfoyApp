import 'package:flutter/material.dart';
import '../models/return_mode.dart';
import '../theme/app_theme.dart';

class NetGrossBadge extends StatelessWidget {
  final bool? isNet;
  final ReturnCalculationMode? mode;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const NetGrossBadge({
    super.key,
    this.isNet,
    this.mode,
    this.fontSize = 9.5,
    this.padding,
  }) : assert(isNet != null || mode != null,
            'isNet veya mode parametrelerinden en az biri sağlanmalıdır.');

  ReturnCalculationMode get effectiveMode {
    if (mode != null) return mode!;
    return isNet == true
        ? ReturnCalculationMode.net
        : ReturnCalculationMode.brut;
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    String tooltip;

    switch (effectiveMode) {
      case ReturnCalculationMode.brut:
        color = AppTheme.primary; // 0xFF3A86FF
        label = 'BRÜT';
        tooltip = 'Stopaj vergisi ve enflasyon düşülmemiş brüt tutar';
        break;
      case ReturnCalculationMode.net:
        color = AppTheme.profit; // 0xFF06D6A0
        label = 'NET';
        tooltip = 'Stopaj vergisi düşülmüş net tutar';
        break;
      case ReturnCalculationMode.reel:
        color = AppTheme.warning; // 0xFFF9A826
        label = 'REEL';
        tooltip = 'TÜFE enflasyonundan arındırılmış reel getiri';
        break;
    }

    final bgColor = color.withValues(alpha: 0.12);
    final borderColor = color.withValues(alpha: 0.35);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
