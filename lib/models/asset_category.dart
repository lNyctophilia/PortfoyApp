import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
        return AppColors.accentLight; // Vibrant Blue (0xFF3A86FF)
      case AssetCategory.hisse:
        return AppColors.cityInner; // Light Cyan / Sky (0xFF48BFE3)
      case AssetCategory.doviz:
        return AppColors.success; // Emerald / Mint (0xFF06D6A0)
      case AssetCategory.emtia:
        return AppColors.warning; // Warm Amber / Gold (0xFFF9A826)
      case AssetCategory.kripto:
        return const Color(0xFFFB923C); // Bitcoin / Orange
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
