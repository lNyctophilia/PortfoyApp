import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_category.dart';
import '../models/portfolio.dart';
import '../models/portfolio_asset.dart';
import '../models/portfolio_transaction.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/asset_item_tile.dart';
import '../widgets/category_distribution_bar.dart';
import '../widgets/period_performance_badge.dart';
import 'add_edit_asset_dialog.dart';
import 'add_edit_portfolio_dialog.dart';
import 'add_transaction_dialog.dart';
import 'asset_status_dialog.dart';

class PortfolioDetailDialog extends StatefulWidget {
  final String portfolioId;

  const PortfolioDetailDialog({
    super.key,
    required this.portfolioId,
  });

  @override
  State<PortfolioDetailDialog> createState() => _PortfolioDetailDialogState();
}

class _PortfolioDetailDialogState extends State<PortfolioDetailDialog> {
  int _selectedTab = 0; // 0: Varlıklar, 1: İşlem Geçmişi
  AssetCategory? _filterCategory;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final portfolio = provider.getPortfolioById(widget.portfolioId);

    if (portfolio == null) {
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
      final matchesCat =
          _filterCategory == null || a.category == _filterCategory;
      final matchesSearch = _search.isEmpty ||
          a.name.toLowerCase().contains(_search.toLowerCase()) ||
          a.symbol.toLowerCase().contains(_search.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final isProfit = portfolio.netTotalProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width * 0.94).clamp(650.0, 1100.0);
    final dialogHeight = (size.height * 0.90).clamp(520.0, 880.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST BAŞLIK & İŞLEM BUTONLARI
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryLight,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style: const TextStyle(
                            fontSize: 22,
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
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isRefreshing
                        ? null
                        : () => provider.refreshPortfolioPrices(portfolio.id),
                    icon: provider.isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(provider.isRefreshing ? 'Güncelleniyor...' : 'Fiyatları Güncelle'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddEditPortfolioDialog(
                          portfolio: portfolio,
                          onSave: (name, desc) {
                            provider.updatePortfolio(
                              id: portfolio.id,
                              name: name,
                              description: desc,
                            );
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Portföyü Düzenle'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 8, bottom: 20),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ÖZET KARTLARI (DEĞER, KAZANÇ, TARİHSEL VERİLER)
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
                            // Üçlü İstatistik Şeridi
                            Row(
                              children: [
                                // 1. Portföy Değeri & Maliyet
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Toplam Portföy Değeri',
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
                                          Formatters.currency(
                                            portfolio.totalWithholdingTax > 0
                                                ? portfolio.netTotalValue
                                                : portfolio.totalValue,
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Toplam Maliyet: ${Formatters.currency(portfolio.totalCost)}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (portfolio.totalWithholdingTax > 0)
                                        Text(
                                          'Brüt: ${Formatters.currency(portfolio.totalValue)}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 44,
                                  color: AppTheme.borderSubtle,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),

                                // 2. Açık Kâr / Zarar
                                Expanded(
                                  child: Column(
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
                                          children: [
                                            Icon(
                                              isProfit
                                                  ? Icons.trending_up_rounded
                                                  : Icons.trending_down_rounded,
                                              color: profitColor,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              Formatters.currency(
                                                portfolio.totalWithholdingTax > 0
                                                    ? portfolio.netTotalProfit
                                                    : portfolio.totalProfit,
                                              ),
                                              style: TextStyle(
                                                color: profitColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Getiri: ${Formatters.percent(portfolio.totalWithholdingTax > 0 ? portfolio.netTotalProfitPercent : portfolio.totalProfitPercent)}',
                                        style: TextStyle(
                                          color: profitColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (portfolio.totalWithholdingTax > 0)
                                        Text(
                                          'Brüt: ${Formatters.currency(portfolio.totalProfit)}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 44,
                                  color: AppTheme.borderSubtle,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),

                                // 3. Gerçekleşen Kâr / Zarar
                                Expanded(
                                  child: Column(
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
                                                portfolio.realizedWithholdingTax > 0
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
                                      const SizedBox(height: 2),
                                      if (portfolio.realizedWithholdingTax > 0)
                                        Text(
                                          'Brüt: ${Formatters.currency(portfolio.realizedProfit)}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Kapatılan Satış İşlemleri',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: AppTheme.borderSubtle, height: 1),
                            ),

                            // Tarihsel Dönem Verileri
                            Row(
                              children: [
                                const Icon(Icons.history_rounded, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                const Text(
                                  'Tarihsel Getiriler',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            PeriodPerformanceRow.fromPortfolio(
                              portfolio,
                              compact: false,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
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

                      // SEKME SEÇİCİ VE İŞLEM BUTONLARI (VARLIKLAR & İŞLEM GEÇMİŞİ)
                      Row(
                        children: [
                          // Sekme Butonları (Varlıklar / İşlem Geçmişi)
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
                                  label:
                                      'İşlem Geçmişi (${portfolio.transactions.length})',
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Alış / Satış Butonu
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.profit.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.profit,
                              side: const BorderSide(color: AppTheme.profit),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
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
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: const Text(
                              'Alış / Satış',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // SEÇİLEN SEKMENİN İÇERİĞİ
                      _selectedTab == 0
                          ? _buildAssetsTab(portfolio, filteredAssets, provider)
                          : _buildTransactionsTab(portfolio, provider),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppTheme.primary) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsTab(Portfolio portfolio,
      List<PortfolioAsset> filteredAssets, PortfolioProvider provider) {
    return Column(
      children: [
        // Filtre ve Arama Çubuğu
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tümü', null),
                    const SizedBox(width: 6),
                    ...AssetCategory.values.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildFilterChip(c.displayName, c),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              height: 38,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Varlık ara...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
                        : 'Aramaya veya filtreye uygun varlık bulunamadı',
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
                  showDialog(
                    context: context,
                    builder: (_) => AssetStatusDialog(
                      portfolio: portfolio,
                      asset: asset,
                      provider: provider,
                    ),
                  );
                },
                onEdit: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditAssetDialog(
                      asset: asset,
                      onSave: (updatedAsset) {
                        provider.updateAsset(
                          portfolio.id,
                          updatedAsset,
                        );
                      },
                    ),
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
      Portfolio portfolio, PortfolioProvider provider) {
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
              const SizedBox(height: 4),
              const Text(
                'Satış yaptıkça gerçekleşen kâr ve zararlarınız burada listelenir.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.profit.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.profit,
                  side: const BorderSide(color: AppTheme.profit),
                ),
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
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('İlk İşlemi Ekle'),
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
        final isSatis = tx.type == TransactionType.satis;
        final isProfit = tx.realizedProfit >= 0;
        final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              // İşlem Türü Rozeti
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSatis
                      ? (isProfit ? AppTheme.profit : AppTheme.loss)
                          .withValues(alpha: 0.15)
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSatis
                        ? (isProfit ? AppTheme.profit : AppTheme.loss)
                            .withValues(alpha: 0.4)
                        : AppTheme.primaryLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSatis
                          ? (isProfit
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded)
                          : Icons.add_shopping_cart_rounded,
                      size: 14,
                      color: isSatis
                          ? (isProfit ? AppTheme.profit : AppTheme.loss)
                          : AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tx.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSatis
                            ? (isProfit ? AppTheme.profit : AppTheme.loss)
                            : AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Sembol & Varlık Detayları
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

              // Fiyat ve Tutar Detayları
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Formatters.currency(tx.price)} × ${tx.quantity.toStringAsFixed(tx.quantity.truncateToDouble() == tx.quantity ? 0 : 2)} Adet',
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
              const SizedBox(width: 16),

              // Gerçekleşen Kâr / Zarar Göstergesi (Satış ise)
              if (isSatis) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: profitColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kâr: ${Formatters.currency(tx.category == AssetCategory.fon && tx.withholdingTax > 0 ? tx.netRealizedProfit : tx.realizedProfit)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: profitColor,
                        ),
                      ),
                      if (tx.category == AssetCategory.fon &&
                          tx.withholdingTax > 0)
                        Text(
                          'Brüt: ${Formatters.currency(tx.realizedProfit)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      Text(
                        'Oran: ${Formatters.percent(tx.category == AssetCategory.fon && tx.withholdingTax > 0 ? tx.netProfitPercent : tx.profitPercent)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: profitColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Geri Al Butonu
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                tooltip: 'İşlemi Geri Al (Varlık & K/Z iade edilir)',
                color: const Color(0xFFF59E0B),
                onPressed: () {
                  _confirmUndoTransaction(
                      context, provider, portfolio.id, tx);
                },
              ),

              // Silme Butonu
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'İşlemi Sil (Varlıklar korunur, K/Z silinir)',
                color: AppTheme.loss,
                onPressed: () {
                  _confirmDeleteTransaction(
                      context, provider, portfolio.id, tx);
                },
              ),
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
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
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

  void _confirmDeleteTransaction(
    BuildContext context,
    PortfolioProvider provider,
    String portfolioId,
    PortfolioTransaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: Text(
          '${transaction.symbol} (${transaction.type.label}) kaydı işlem geçmişinden silinecektir.\n\n• Portföydeki varlık adetleriniz DEĞİŞMEYECEKTİR (işlem gerçekleşmiş sayılır).\n• Bu işleme ait gerçekleşen kâr/zarar silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.loss),
            onPressed: () {
              provider.deleteTransaction(portfolioId, transaction.id,
                  reverseHoldings: false);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AssetCategory? cat) {
    final isSelected = _filterCategory == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterCategory = cat),
      showCheckmark: false,
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      backgroundColor: AppTheme.surfaceLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.borderSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
