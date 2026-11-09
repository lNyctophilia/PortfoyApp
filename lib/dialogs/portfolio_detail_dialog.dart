import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/asset_item_tile.dart';
import '../widgets/category_distribution_bar.dart';
import '../models/return_mode.dart';
import '../widgets/period_performance_badge.dart';
import '../core/navigation/adaptive_navigation.dart';
import 'add_transaction_dialog.dart';
class PortfolioDetailDialog extends StatefulWidget {
  final String portfolioId;
  final bool isFullScreen;

  const PortfolioDetailDialog({
    super.key,
    required this.portfolioId,
    this.isFullScreen = false,
  });
  @override
  State<PortfolioDetailDialog> createState() => _PortfolioDetailDialogState();
}
class _PortfolioDetailDialogState extends State<PortfolioDetailDialog> {
  int _selectedTab = 0; // 0: Varlıklar, 1: İşlem Geçmişi
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final portfolio = provider.getPortfolioById(widget.portfolioId);
    if (portfolio == null) {
      if (widget.isFullScreen) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Portföy bulunamadı'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Geri Dön'),
            ),
          ),
        );
      }
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Portföy bulunamadı'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      );
    }
    final filteredAssets = portfolio.assets.where((a) {
      final matchesSearch = _search.isEmpty ||
          a.name.toLowerCase().contains(_search.toLowerCase()) ||
          a.symbol.toLowerCase().contains(_search.toLowerCase());
      return matchesSearch;
    }).toList();
    final mode = provider.returnMode;
    final inflationRates = provider.assetInflationRates;
    final displayValue = portfolio.valueForMode(mode);
    final displayProfit = portfolio.profitForMode(mode, inflationRates);
    final displayProfitPercent =
        portfolio.profitPercentForMode(mode, inflationRates);
    final showNetValues = provider.showNetValues;
    final isProfit = displayProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 720;
    final dialogWidth = isMobile ? size.width * 0.96 : (size.width * 0.94).clamp(650.0, 1100.0);
    final dialogHeight = isMobile ? size.height * 0.95 : (size.height * 0.90).clamp(520.0, 880.0);
    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                portfolio.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (portfolio.description.isNotEmpty)
                Text(
                  portfolio.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => provider.refreshPortfolioPrices(portfolio.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: _buildDetailContent(
                context,
                portfolio,
                provider,
                filteredAssets,
                mode,
                inflationRates,
                displayValue,
                displayProfit,
                displayProfitPercent,
                showNetValues,
                isProfit,
                profitColor,
                true,
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20, vertical: isMobile ? 8 : 16),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopHeader(context, portfolio, provider, isMobile),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isMobile ? 14 : 24, right: 8, bottom: isMobile ? 14 : 20),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(right: isMobile ? 8 : 16),
                  child: _buildDetailContent(
                    context,
                    portfolio,
                    provider,
                    filteredAssets,
                    mode,
                    inflationRates,
                    displayValue,
                    displayProfit,
                    displayProfitPercent,
                    showNetValues,
                    isProfit,
                    profitColor,
                    isMobile,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    Portfolio portfolio,
    PortfolioProvider provider,
    bool isMobile,
  ) {
    return Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, isMobile ? 14 : 24, isMobile ? 14 : 24, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryLight,
                      size: isMobile ? 22 : 26,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (portfolio.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            portfolio.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            );
  }

  Widget _buildDetailContent(
    BuildContext context,
    Portfolio portfolio,
    PortfolioProvider provider,
    List<PortfolioAsset> filteredAssets,
    ReturnCalculationMode mode,
    dynamic inflationRates,
    double displayValue,
    double displayProfit,
    double displayProfitPercent,
    bool showNetValues,
    bool isProfit,
    Color profitColor,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                      // ÖZET KARTLARI (DEÄER, KAZANÇ, TARİHSEL VERİLER)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                        Builder(
                              builder: (context) {
                                final metricValueWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Portföy Değeri',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        Formatters.currency(displayValue),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Maliyet: ${Formatters.currency(portfolio.totalCost)}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                );

                                final metricProfitWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Açık Kâr / Zarar',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            Formatters.currency(displayProfit),
                                            style: TextStyle(
                                              color: profitColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${Formatters.percent(displayProfitPercent)})',
                                            style: TextStyle(
                                              color: profitColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                final metricRealizedWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gerçekleşen Kâr / Zarar',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            portfolio.netRealizedProfit >= 0
                                                ? Icons.check_circle_outline_rounded
                                                : Icons.highlight_off_rounded,
                                            color: portfolio.netRealizedProfit >= 0
                                                ? AppTheme.profit
                                                : AppTheme.loss,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            Formatters.currency(
                                              (portfolio.realizedWithholdingTax > 0 && showNetValues)
                                                  ? portfolio.netRealizedProfit
                                                  : portfolio.realizedProfit,
                                            ),
                                            style: TextStyle(
                                              color: portfolio.netRealizedProfit >= 0
                                                  ? AppTheme.profit
                                                  : AppTheme.loss,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      metricValueWidget,
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Divider(color: AppTheme.borderSubtle, height: 1),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: metricProfitWidget),
                                          Container(
                                            width: 1,
                                            height: 44,
                                            color: AppTheme.borderSubtle,
                                            margin: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          Expanded(child: metricRealizedWidget),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: metricValueWidget),
                                    Container(
                                      width: 1,
                                      height: 44,
                                      color: AppTheme.borderSubtle,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    Expanded(child: metricProfitWidget),
                                    Container(
                                      width: 1,
                                      height: 44,
                                      color: AppTheme.borderSubtle,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    Expanded(child: metricRealizedWidget),
                                  ],
                                );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: AppTheme.borderSubtle, height: 1),
                            ),
                            // Tarihsel Dönem Performansı
                            PeriodPerformanceRow.fromPortfolio(
                              portfolio,
                              compact: false,
                              mode: provider.returnMode,
                              periodInflation: provider.periodInflation,
                              assetInflationRates: provider.assetInflationRates,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: AppTheme.borderSubtle, height: 1),
                            ),
                            // Kategori Dağılım Çubuğu ve Yüzdeler
                            Row(
                              children: [
                                const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                const Text(
                                  'Varlık Dağılımı',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CategoryDistributionBar(
                              portfolio: portfolio,
                              showAmounts: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                                            // SEKME SEÇİCİ VE İŞLEM BUTONLARI
                      if (isMobile) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton(
                                  index: 0,
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Varlıklar (${portfolio.assets.length})',
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildTabButton(
                                  index: 1,
                                  icon: Icons.history_rounded,
                                  label: 'İşlemler (${portfolio.transactions.length})',
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.profit.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.profit,
                              side: const BorderSide(color: AppTheme.profit),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              AdaptiveNavigation.openAddTransaction(context, portfolio: portfolio);
                            },
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: const Text(
                              'Alış / Satış Yap',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabButton(
                                    index: 0,
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Varlıklar (${portfolio.assets.length})',
                                  ),
                                  const SizedBox(width: 4),
                                  _buildTabButton(
                                    index: 1,
                                    icon: Icons.history_rounded,
                                    label: 'İşlem Geçmişi (${portfolio.transactions.length})',
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.profit.withValues(alpha: 0.15),
                                foregroundColor: AppTheme.profit,
                                side: const BorderSide(color: AppTheme.profit),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                AdaptiveNavigation.openAddTransaction(context, portfolio: portfolio);
                              },
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: const Text(
                                'Alış / Satış',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // SEÇİLEN SEKMENİN İÇERİĞİ
                      _selectedTab == 0
                          ? _buildAssetsTab(portfolio, filteredAssets, provider, isMobile)
                          : _buildTransactionsTab(portfolio, provider, isMobile),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    bool compact = false,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppTheme.primary) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                  fontSize: compact ? 12 : 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAssetsTab(Portfolio portfolio,
      List<PortfolioAsset> filteredAssets, PortfolioProvider provider, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Varlık ara...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
            ),
          ),
        ),
        // Varlık Listesi
        if (filteredAssets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    portfolio.assets.isEmpty
                        ? 'Bu portföyde henüz varlık yok'
                        : 'Aramaya uygun varlık bulunamadı',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  if (portfolio.assets.isEmpty) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTransactionDialog(
                            portfolio: portfolio,
                            onSave: (tx, updateHoldings) {
                              provider.addTransaction(
                                portfolio.id,
                                tx,
                                updateHoldings: updateHoldings,
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('İlk Alışı Yap'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredAssets.length,
            itemBuilder: (context, index) {
              final asset = filteredAssets[index];
              return AssetItemTile(
                asset: asset,
                onStatus: () {
                  AdaptiveNavigation.openAssetStatus(
                    context,
                    portfolio: portfolio,
                    asset: asset,
                  );
                },
                onDelete: () {
                  _confirmDeleteAsset(
                      context, provider, portfolio.id, asset);
                },
              );
            },
          ),
      ],
    );
  }
  Widget _buildTransactionsTab(
      Portfolio portfolio, PortfolioProvider provider, bool isMobile) {
    if (portfolio.transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu portföyde henüz işlem kaydı yok',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: portfolio.transactions.length,
      itemBuilder: (context, index) {
        final tx = portfolio.transactions[index];
        final isLatestForAsset = portfolio.transactions
                .firstWhere(
                  (t) => t.symbol.toUpperCase() == tx.symbol.toUpperCase(),
                )
                .id ==
            tx.id;
        final isSatis = tx.type == TransactionType.satis;
        final typeColor = isSatis ? AppTheme.loss : AppTheme.profit;

        final typeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSatis ? Icons.sell_rounded : Icons.add_shopping_cart_rounded,
                size: 13,
                color: typeColor,
              ),
              const SizedBox(width: 4),
              Text(
                tx.type.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ],
          ),
        );

        Widget? profitBadgeWidget;
        if (isSatis) {
          profitBadgeWidget = Builder(
            builder: (context) {
              final showNetValues = context.watch<PortfolioProvider>().showNetValues;
              final hasStopaj = tx.withholdingTax > 0;
              final displayProfit = (hasStopaj && showNetValues) ? tx.netRealizedProfit : tx.realizedProfit;
              final displayPercent = (hasStopaj && showNetValues) ? tx.netProfitPercent : tx.profitPercent;
              final isProfit = displayProfit >= 0;
              final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: profitColor.withValues(alpha: 0.3)),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    Text(
                      Formatters.currency(displayProfit),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: profitColor,
                      ),
                    ),
                    Text(
                      '(${Formatters.percent(displayPercent)})',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        if (isMobile) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    typeBadge,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tx.symbol,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${Formatters.date(tx.date)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            tx.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isLatestForAsset)
                      IconButton(
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        tooltip: 'Geri Al',
                        color: AppTheme.warning,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmUndoTransaction(context, provider, portfolio.id, tx),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.borderSubtle, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Formatters.formatPrice(tx.price)} ₺ × ${tx.quantity.toStringAsFixed(tx.quantity.truncateToDouble() == tx.quantity ? 0 : 2)} Adet',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.currency(tx.totalAmount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    ?profitBadgeWidget,
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              typeBadge,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tx.symbol,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${Formatters.date(tx.date)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Formatters.formatPrice(tx.price)} ₺ × ${tx.quantity.toStringAsFixed(tx.quantity.truncateToDouble() == tx.quantity ? 0 : 2)} Adet',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.currency(tx.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (profitBadgeWidget != null) ...[
                const SizedBox(width: 16),
                profitBadgeWidget,
              ],
              if (isLatestForAsset) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  tooltip: 'İşlemi Geri Al',
                  color: AppTheme.warning,
                  onPressed: () => _confirmUndoTransaction(context, provider, portfolio.id, tx),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  void _confirmUndoTransaction(
    BuildContext context,
    PortfolioProvider provider,
    String portfolioId,
    PortfolioTransaction transaction,
  ) {
    final isSatis = transaction.type == TransactionType.satis;
    final qtyStr = transaction.quantity.toStringAsFixed(
      transaction.quantity.truncateToDouble() == transaction.quantity ? 0 : 2,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Geri Al'),
        content: Text(
          isSatis
              ? '${transaction.symbol} satış işlemi geri alınacaktır.\n\n• Satılan $qtyStr adet portföye geri eklenecektir.\n• Elde edilen gerçekleşen kâr/zarar (${Formatters.currency(transaction.realizedProfit)}) iptal edilecektir.'
              : '${transaction.symbol} alış işlemi geri alınacaktır.\n\n• Alınan $qtyStr adet portföyden geri düşülecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.background,
            ),
            onPressed: () {
              provider.deleteTransaction(portfolioId, transaction.id,
                  reverseHoldings: true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Geri Al'),
          ),
        ],
      ),
    );
  }
  void _confirmDeleteAsset(BuildContext context, PortfolioProvider provider,
      String portfolioId, PortfolioAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Varlığı Sil'),
        content: Text(
          '${asset.symbol} - ${asset.name} varlığını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.loss),
            onPressed: () {
              provider.deleteAsset(portfolioId, asset.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
