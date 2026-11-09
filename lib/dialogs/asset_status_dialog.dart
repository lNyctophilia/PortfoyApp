import '../core/navigation/adaptive_navigation.dart';
import 'package:flutter/material.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../theme/app_theme.dart';
import '../utils/fifo_calculator.dart';
import '../utils/formatters.dart';
import '../widgets/asset_logo.dart';
import '../models/return_mode.dart';
import '../providers/portfolio_provider.dart';

class AssetStatusDialog extends StatefulWidget {
  final Portfolio portfolio;
  final PortfolioAsset asset;
  final PortfolioProvider provider;

  final bool isFullScreen;

  const AssetStatusDialog({
    super.key,
    required this.portfolio,
    required this.asset,
    required this.provider,
    this.isFullScreen = false,
  });

  @override
  State<AssetStatusDialog> createState() => _AssetStatusDialogState();
}

class _AssetStatusDialogState extends State<AssetStatusDialog> {
  int _selectedTab = 0; // 0: Alış Lotları, 1: Satış Geçmişi

  @override
  Widget build(BuildContext context) {
    // Portföyün güncel halini al
    final currentPortfolio =
        widget.provider.getPortfolioById(widget.portfolio.id) ??
            widget.portfolio;
    // Varlığın güncel halini bul (satış sonrası miktarı değişmiş olabilir)
    final currentAsset = currentPortfolio.assets.firstWhere(
      (a) =>
          a.id == widget.asset.id ||
          a.symbol.toUpperCase() == widget.asset.symbol.toUpperCase(),
      orElse: () => widget.asset,
    );

    final fifoResult = FifoCalculator.calculate(
      currentPortfolio,
      currentAsset.symbol,
      assetFallback: currentAsset,
    );

    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 700;
    final dialogWidth = isMobile ? size.width * 0.96 : (size.width * 0.90).clamp(600.0, 840.0);
    final dialogHeight = isMobile ? size.height * 0.95 : (size.height * 0.88).clamp(520.0, 780.0);

    final mode = widget.provider.returnMode;
    final inflationRate = widget.provider.getAssetInflation(currentAsset.id);
    final showNetValues = widget.provider.showNetValues;
    final hasStopaj = currentAsset.category == AssetCategory.fon &&
        currentAsset.withholdingTaxAmount > 0;
    final displayCurrentPrice = (hasStopaj && mode != ReturnCalculationMode.brut)
        ? currentAsset.netCurrentPrice
        : currentAsset.currentPrice;
    final displayProfit = currentAsset.profitForMode(mode, inflationRate);
    final displayProfitPercent =
        currentAsset.profitPercentForMode(mode, inflationRate);

    final isProfit = displayProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

        if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              AssetLogo(
                iconUrl: currentAsset.iconUrl,
                symbol: currentAsset.symbol,
                name: currentAsset.name,
                category: currentAsset.category,
                size: 32,
                iconSize: 16,
                borderRadius: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAsset.symbol,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentAsset.name,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ÖZET İSTATİSTİK KARTLARI
              _buildSummaryMetricsBar(
                isMobile: true,
                fifoResult: fifoResult,
                currentAsset: currentAsset,
                displayCurrentPrice: displayCurrentPrice,
                displayProfit: displayProfit,
                displayProfitPercent: displayProfitPercent,
                profitColor: profitColor,
                showNetValues: showNetValues,
              ),

            // TAB BUTONLARI (Alış Lotları / Satışlar)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      0,
                      isMobile ? 'Alış Lotları' : 'Alış Lotları & Maliyetler',
                      fifoResult.allLots.length,
                      Icons.history_rounded,
                      isMobile: isMobile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      1,
                      isMobile ? 'Satış Geçmişi' : 'Satış & Gerçekleşen Kâr',
                      fifoResult.saleRecords.length,
                      Icons.sell_outlined,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // İÇERİK LİSTESİ
            Expanded(
              child: _selectedTab == 0
                  ? _buildLotsTab(fifoResult, currentAsset, isMobile)
                  : _buildSalesTab(fifoResult, currentAsset, isMobile),
            ),

            ],
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20, vertical: isMobile ? 8 : 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 20, 14),
              child: Row(
                children: [
                  AssetLogo(
                    iconUrl: currentAsset.iconUrl,
                    symbol: currentAsset.symbol,
                    name: currentAsset.name,
                    category: currentAsset.category,
                    size: 46,
                    iconSize: 22,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              currentAsset.symbol,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: currentAsset.category.color
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentAsset.category.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: currentAsset.category.color,
                                ),
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentAsset.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Kapat',
                    color: AppTheme.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            // ÖZET İSTATİSTİK KARTLARI
            _buildSummaryMetricsBar(
              isMobile: false,
              fifoResult: fifoResult,
              currentAsset: currentAsset,
              displayCurrentPrice: displayCurrentPrice,
              displayProfit: displayProfit,
              displayProfitPercent: displayProfitPercent,
              profitColor: profitColor,
              showNetValues: showNetValues,
            ),

            // TAB BUTONLARI (Alış Lotları / Satışlar)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      0,
                      isMobile ? 'Alış Lotları' : 'Alış Lotları & Maliyetler',
                      fifoResult.allLots.length,
                      Icons.history_rounded,
                      isMobile: isMobile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      1,
                      isMobile ? 'Satış Geçmişi' : 'Satış & Gerçekleşen Kâr',
                      fifoResult.saleRecords.length,
                      Icons.sell_outlined,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // İÇERİK LİSTESİ
            Expanded(
              child: _selectedTab == 0
                  ? _buildLotsTab(fifoResult, currentAsset, isMobile)
                  : _buildSalesTab(fifoResult, currentAsset, isMobile),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetricsBar({
    required bool isMobile,
    required FifoResult fifoResult,
    required PortfolioAsset currentAsset,
    required double displayCurrentPrice,
    required double displayProfit,
    required double displayProfitPercent,
    required Color profitColor,
    required bool showNetValues,
  }) {
    final metricAdet = _buildMetricItem(
      'Adet',
      _formatQty(fifoResult.remainingQuantity),
      icon: Icons.inventory_2_outlined,
    );

    final metricMaliyet = _buildMetricItem(
      'Ort. Maliyet',
      Formatters.currency(fifoResult.averageRemainingCost),
      icon: Icons.price_change_outlined,
    );

    final metricFiyat = _buildMetricItem(
      'Güncel Fiyat',
      Formatters.currency(displayCurrentPrice),
      icon: Icons.show_chart_rounded,
    );

    final metricKalanKar = _buildMetricItem(
      'Kalan Kâr / Zarar',
      '${Formatters.currency(displayProfit)} (${Formatters.percent(displayProfitPercent)})',
      valueColor: profitColor,
      icon: Icons.insights_rounded,
    );

    Widget? metricRealized;
    if (fifoResult.totalRealizedProfit != 0) {
      final hasRealizedStopaj = currentAsset.category == AssetCategory.fon &&
          fifoResult.totalRealizedProfit > 0 &&
          currentAsset.effectiveWithholdingTaxRate > 0;
      final netRealized = fifoResult.totalRealizedProfit -
          fifoResult.totalRealizedProfit *
              (currentAsset.effectiveWithholdingTaxRate / 100);
      final displayRealized = (hasRealizedStopaj && showNetValues)
          ? netRealized
          : fifoResult.totalRealizedProfit;

      metricRealized = _buildMetricItem(
        'Gerçekleşen Kâr',
        Formatters.currency(displayRealized),
        valueColor: displayRealized >= 0 ? AppTheme.profit : AppTheme.loss,
        icon: Icons.monetization_on_outlined,
      );
    }

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Container(
          key: const Key('asset_status_summary_card'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(child: metricAdet),
              _buildDivider(isMobile: false),
              Expanded(child: metricMaliyet),
              _buildDivider(isMobile: false),
              Expanded(child: metricFiyat),
              _buildDivider(isMobile: false),
              Expanded(child: metricKalanKar),
              if (metricRealized != null) ...[
                _buildDivider(isMobile: false),
                Expanded(child: metricRealized),
              ],
            ],
          ),
        ),
      );
    }

    // Mobil Görünüm: 2 satır, kaydırma olmadan tam ekrana sığacak şekilde
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        key: const Key('asset_status_summary_card'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (metricRealized != null) ...[
              // 5 Metrik: 1. Satırda 3 temel metrik, 2. Satırda 2 getiri metriği
              Row(
                children: [
                  Expanded(child: metricAdet),
                  _buildDivider(isMobile: true),
                  Expanded(child: metricMaliyet),
                  _buildDivider(isMobile: true),
                  Expanded(child: metricFiyat),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppTheme.borderSubtle, height: 1),
              ),
              Row(
                children: [
                  Expanded(child: metricKalanKar),
                  _buildDivider(isMobile: true),
                  Expanded(child: metricRealized),
                ],
              ),
            ] else ...[
              // 4 Metrik: 2x2 dengeli ızgara
              Row(
                children: [
                  Expanded(child: metricAdet),
                  _buildDivider(isMobile: true),
                  Expanded(child: metricMaliyet),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppTheme.borderSubtle, height: 1),
              ),
              Row(
                children: [
                  Expanded(child: metricFiyat),
                  _buildDivider(isMobile: true),
                  Expanded(child: metricKalanKar),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
    String? subtitle,
    Color? subtitleColor,
    Widget? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              badge,
            ],
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subtitleColor ?? AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider({bool isMobile = false}) {
    return Container(
      width: 1,
      height: isMobile ? 24 : 32,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      color: AppTheme.borderSubtle,
    );
  }

  Widget _buildTabButton(int index, String label, int count, IconData icon, {bool isMobile = false}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11.5 : 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryLight.withValues(alpha: 0.25)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ALIÅ LOTLARI SEKMESİ
  Widget _buildLotsTab(FifoResult result, PortfolioAsset asset, bool isMobile) {
    if (result.allLots.isEmpty) {
      return const Center(
        child: Text(
          'Alış kaydı bulunamadı',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      itemCount: result.allLots.length,
      itemBuilder: (context, index) {
        final lot = result.allLots[index];
        final lotProfit = lot.unrealizedProfit(asset.currentPrice);
        final lotProfitPercent = lot.unrealizedProfitPercent(asset.currentPrice);
        final isProfit = lotProfit >= 0;
        final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lot.isFullySold
                ? AppTheme.surfaceLight.withValues(alpha: 0.5)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lot.isFullySold
                  ? AppTheme.borderSubtle.withValues(alpha: 0.5)
                  : (lot.isPartiallySold
                      ? AppTheme.warning.withValues(alpha: 0.35)
                      : AppTheme.borderSubtle),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: Tarih & Durum Rozeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.profit.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 14,
                          color: AppTheme.profit,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alış: ${Formatters.date(lot.date)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${Formatters.daysAgo(lot.date)})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  _buildLotStatusBadge(lot),
                ],
              ),
              const SizedBox(height: 10),

              // Alış Bilgileri
              if (isMobile) ...[
                Row(
                  children: [
                    Expanded(child: _buildSubStat('Alınan Miktar', '${_formatQty(lot.originalQuantity)} Adet')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSubStat('Alış Fiyatı', Formatters.currency(lot.purchasePrice))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSubStat('Toplam Maliyet', Formatters.currency(lot.totalOriginalCost))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSubStat(
                        'Kalan Miktar',
                        '${_formatQty(lot.remainingQuantity)} Adet',
                        highlightColor: lot.isFullySold ? AppTheme.textMuted : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildSubStat('Alınan Miktar', '${_formatQty(lot.originalQuantity)} Adet')),
                    Expanded(child: _buildSubStat('Alış Fiyatı', Formatters.currency(lot.purchasePrice))),
                    Expanded(child: _buildSubStat('Toplam Maliyet', Formatters.currency(lot.totalOriginalCost))),
                    Expanded(
                      child: _buildSubStat(
                        'Kalan Miktar',
                        '${_formatQty(lot.remainingQuantity)} Adet',
                        highlightColor: lot.isFullySold ? AppTheme.textMuted : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],

              // Kalan Miktar varsa Kâr / Zarar Satırı
              if (!lot.isFullySold) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.borderSubtle, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kalan Lot Değeri: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          Formatters.currency(
                            lot.remainingQuantity * asset.currentPrice,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isProfit ? AppTheme.profitBg : AppTheme.lossBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Kâr/Zarar: ${Formatters.currency(lotProfit)} (${Formatters.percent(lotProfitPercent)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: profitColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // SATIÅ GEÇMİÅİ SEKMESİ
  Widget _buildSalesTab(FifoResult result, PortfolioAsset asset, bool isMobile) {
    if (result.saleRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sell_outlined,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bu varlık için henüz satış yapılmadı',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Satış yaptığınızda FIFO maliyeti ve gerçekleşen kâr burada listelenir.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      itemCount: result.saleRecords.length,
      itemBuilder: (context, index) {
        final saleRecord = result.saleRecords[index];
        final tx = saleRecord.transaction;
        final isProfit = saleRecord.realizedProfit >= 0;
        final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: Satış Tarihi ve Gerçekleşen Kâr Rozeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.loss.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: AppTheme.loss,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Satış: ${Formatters.date(tx.date)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${Formatters.daysAgo(tx.date)})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final hasStopaj = tx.category == AssetCategory.fon &&
                          saleRecord.realizedProfit > 0 &&
                          tx.effectiveWithholdingTaxRate > 0;
                      final netRealized = hasStopaj
                          ? saleRecord.realizedProfit -
                              saleRecord.realizedProfit *
                                  (tx.effectiveWithholdingTaxRate / 100)
                          : saleRecord.realizedProfit;
                      final netPct = (hasStopaj &&
                              saleRecord.unitCost > 0 &&
                              tx.quantity > 0)
                          ? (netRealized /
                                  (saleRecord.unitCost * tx.quantity)) *
                              100
                          : saleRecord.realizedProfitPercent;

                      final showNetValues = widget.provider.showNetValues;
                      final displayRealized = (hasStopaj && showNetValues) ? netRealized : saleRecord.realizedProfit;
                      final displayPct = (hasStopaj && showNetValues) ? netPct : saleRecord.realizedProfitPercent;
                      final isSaleProfit = displayRealized >= 0;
                      final saleProfitColor = isSaleProfit ? AppTheme.profit : AppTheme.loss;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSaleProfit ? AppTheme.profitBg : AppTheme.lossBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gerçekleşen: ${Formatters.currency(displayRealized)} (${Formatters.percent(displayPct)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: saleProfitColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Satış Detayları
              if (isMobile) ...[
                Row(
                  children: [
                    Expanded(child: _buildSubStat('Satılan Miktar', '${_formatQty(tx.quantity)} Adet')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSubStat('Satış Fiyatı', Formatters.currency(tx.price))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSubStat('FIFO Maliyet', Formatters.currency(saleRecord.unitCost))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSubStat('Toplam Gelir', Formatters.currency(tx.quantity * tx.price))),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _buildSubStat('Satılan Miktar', '${_formatQty(tx.quantity)} Adet')),
                    Expanded(child: _buildSubStat('Satış Fiyatı', Formatters.currency(tx.price))),
                    Expanded(child: _buildSubStat('FIFO Maliyet Fiyatı', Formatters.currency(saleRecord.unitCost))),
                    Expanded(child: _buildSubStat('Toplam Gelir', Formatters.currency(tx.quantity * tx.price))),
                  ],
                ),
              ],

              // Tüketilen Lotlar
              if (saleRecord.consumptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: saleRecord.consumptions.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        'â†³ ${_formatQty(c.quantityConsumed)} Adet (${Formatters.date(c.lot.date)} alışından @ ${Formatters.currency(c.unitCost)})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLotStatusBadge(AssetLot lot) {
    if (lot.isFullySold) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Text(
          'Tamamı Satıldı (FIFO)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
      );
    } else if (lot.isPartiallySold) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Kısmen Satıldı (${_formatQty(lot.soldQuantity)} satıldı)',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.warning,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.profit.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Tamamı Duruyor',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.profit,
          ),
        ),
      );
    }
  }

  Widget _buildSubStat(String label, String value, {Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatQty(double val) {
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }
}
