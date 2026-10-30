import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NetGrossBadge extends StatelessWidget {
  final bool isNet;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const NetGrossBadge({
    super.key,
    required this.isNet,
    this.fontSize = 9.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = isNet ? AppTheme.profit : const Color(0xFF38BDF8);
    final bgColor = isNet
        ? AppTheme.profit.withValues(alpha: 0.12)
        : const Color(0xFF38BDF8).withValues(alpha: 0.12);
    final borderColor = isNet
        ? AppTheme.profit.withValues(alpha: 0.32)
        : const Color(0xFF38BDF8).withValues(alpha: 0.32);
    final label = isNet ? 'NET' : 'BRÜT';
    final tooltip = isNet
        ? 'Stopaj vergisi düşülmüş net tutar'
        : 'Stopaj vergisi düşülmemiş brüt tutar';

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

