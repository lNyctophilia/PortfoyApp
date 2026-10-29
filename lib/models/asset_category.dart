import 'package:flutter/material.dart';
import '../widgets/emtia_vector_icon.dart';

enum AssetCategory {
  fon,
  hisse,
  doviz,
  emtia,
  kripto;

  String get displayName {
    switch (this) {
      case AssetCategory.fon:
        return 'Yatırım Fonu';
      case AssetCategory.hisse:
        return 'Hisse Senedi';
      case AssetCategory.doviz:
        return 'Döviz';
      case AssetCategory.emtia:
        return 'Emtia';
      case AssetCategory.kripto:
        return 'Kripto Para';
    }
  }

  String get shortName {
    switch (this) {
      case AssetCategory.fon:
        return 'Fon';
      case AssetCategory.hisse:
        return 'Hisse';
      case AssetCategory.doviz:
        return 'Döviz';
      case AssetCategory.emtia:
        return 'Emtia';
      case AssetCategory.kripto:
        return 'Kripto';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.fon:
        return Icons.pie_chart_rounded;
      case AssetCategory.hisse:
        return Icons.show_chart_rounded;
      case AssetCategory.doviz:
        return Icons.currency_exchange_rounded;
      case AssetCategory.emtia:
        return Icons.view_in_ar_rounded;
      case AssetCategory.kripto:
        return Icons.currency_bitcoin_rounded;
    }
  }

  Widget buildIcon({double size = 20, Color? color}) {
    if (this == AssetCategory.emtia) {
      return EmtiaVectorIcon(size: size, color: color ?? this.color);
    }
    return Icon(icon, size: size, color: color ?? this.color);
  }

  Color get color {
    switch (this) {
      case AssetCategory.fon:
        return const Color(0xFF6366F1); // Indigo
      case AssetCategory.hisse:
        return const Color(0xFF06B6D4); // Cyan
      case AssetCategory.doviz:
        return const Color(0xFF10B981); // Emerald
      case AssetCategory.emtia:
        return const Color(0xFFF59E0B); // Amber
      case AssetCategory.kripto:
        return const Color(0xFFF7931A); // Bitcoin Orange
    }
  }

  static AssetCategory fromString(String value) {
    final v = value.toLowerCase();
    if (v == 'crypto' || v == 'bitcoin' || v == 'btc') return AssetCategory.kripto;
    return AssetCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == v,
      orElse: () => AssetCategory.fon,
    );
  }
}
