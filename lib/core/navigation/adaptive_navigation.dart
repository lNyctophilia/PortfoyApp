import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dialogs/add_edit_asset_dialog.dart';
import '../../dialogs/add_edit_portfolio_dialog.dart';
import '../../dialogs/add_transaction_dialog.dart';
import '../../dialogs/asset_status_dialog.dart';
import '../../dialogs/portfolio_detail_dialog.dart';
import '../../models/portfolio.dart';
import '../../models/portfolio_asset.dart';
import '../../models/portfolio_transaction.dart';
import '../../providers/portfolio_provider.dart';

/// Mobil (telefon) ve Masaüstü (PC) ekranları arasında arayüz sunumunu
/// kusursuz şekilde ayıran adaptif yönlendirme yardımcısı.
class AdaptiveNavigation {
  /// 720px altı ekranlar telefon/mobil arayüzü olarak kabul edilir.
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 720;
  }

  /// Portföy Detay Ekranını açar.
  /// PC'de: Geniş modal popup olarak açılır.
  /// Telefonda: Tam ekran sayfa (Scaffold) olarak açılır.
  static Future<T?> openPortfolioDetail<T>(
    BuildContext context,
    String portfolioId,
  ) {
    if (isMobile(context)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (_) => PortfolioDetailDialog(
            portfolioId: portfolioId,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (_) => PortfolioDetailDialog(
          portfolioId: portfolioId,
          isFullScreen: false,
        ),
      );
    }
  }

  /// Alış / Satış İşlem Ekleme Ekranını açar.
  /// PC'de: Klasik form popup olarak açılır.
  /// Telefonda: Tam ekran form sayfası olarak açılır (klavye ve kaydırma optimize).
  static Future<T?> openAddTransaction<T>(
    BuildContext context, {
    required Portfolio portfolio,
    PortfolioAsset? initialAsset,
    TransactionType initialType = TransactionType.alis,
    Function(PortfolioTransaction transaction, bool updateHoldings)? onSave,
  }) {
    final saveCallback = onSave ??
        (tx, updateHoldings) {
          context.read<PortfolioProvider>().addTransaction(
                portfolio.id,
                tx,
                updateHoldings: updateHoldings,
              );
        };

    if (isMobile(context)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (_) => AddTransactionDialog(
            portfolio: portfolio,
            initialAsset: initialAsset,
            initialType: initialType,
            onSave: saveCallback,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (_) => AddTransactionDialog(
          portfolio: portfolio,
          initialAsset: initialAsset,
          initialType: initialType,
          onSave: saveCallback,
          isFullScreen: false,
        ),
      );
    }
  }

  /// Varlık Durum ve FIFO Lot Detaylarını açar.
  /// PC'de: Çok sekmeli popup modal olarak açılır.
  /// Telefonda: Tam ekran görünüm olarak açılır.
  static Future<T?> openAssetStatus<T>(
    BuildContext context, {
    required Portfolio portfolio,
    required PortfolioAsset asset,
  }) {
    final provider = context.read<PortfolioProvider>();
    if (isMobile(context)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (_) => AssetStatusDialog(
            portfolio: portfolio,
            asset: asset,
            provider: provider,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (_) => AssetStatusDialog(
          portfolio: portfolio,
          asset: asset,
          provider: provider,
          isFullScreen: false,
        ),
      );
    }
  }

  /// Varlık Ekleme / Düzenleme Ekranını açar.
  /// PC'de: Popup modal olarak açılır.
  /// Telefonda: Tam ekran sayfa olarak açılır.
  static Future<T?> openAddEditAsset<T>(
    BuildContext context, {
    PortfolioAsset? asset,
    required Function(PortfolioAsset) onSave,
  }) {
    if (isMobile(context)) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          builder: (_) => AddEditAssetDialog(
            asset: asset,
            onSave: onSave,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (_) => AddEditAssetDialog(
          asset: asset,
          onSave: onSave,
          isFullScreen: false,
        ),
      );
    }
  }

  /// Portföy Oluşturma / Düzenleme Ekranını açar.
  /// PC'de: Popup modal olarak açılır.
  /// Telefonda: Akıcı modal alt çekmece (Bottom Sheet) olarak açılır.
  static Future<T?> openAddEditPortfolio<T>(
    BuildContext context, {
    Portfolio? portfolio,
    required Function(String name, String description) onSave,
  }) {
    if (isMobile(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddEditPortfolioDialog(
          portfolio: portfolio,
          onSave: onSave,
          isBottomSheet: true,
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (_) => AddEditPortfolioDialog(
          portfolio: portfolio,
          onSave: onSave,
          isBottomSheet: false,
        ),
      );
    }
  }
}

