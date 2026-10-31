import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dialogs/add_edit_portfolio_dialog.dart';
import 'dialogs/portfolio_detail_dialog.dart';
import 'providers/portfolio_provider.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'models/return_mode.dart';
import 'widgets/net_gross_badge.dart';
import 'widgets/portfolio_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PortfolioProvider(),
      child: const ExcludeSemantics(
        child: PortfoyApp(),
      ),
    ),
  );
}

class PortfoyApp extends StatelessWidget {
  const PortfoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PortfoyApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return ExcludeSemantics(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const PortfolioHomeScreen(),
    );
  }
}

class PortfolioHomeScreen extends StatefulWidget {
  const PortfolioHomeScreen({super.key});

  @override
  State<PortfolioHomeScreen> createState() => _PortfolioHomeScreenState();
}

class _PortfolioHomeScreenState extends State<PortfolioHomeScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _refreshAllData(showFeedback: false);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f5) {
      _refreshAllData();
      return true;
    }
    return false;
  }

  Future<void> _refreshAllData({bool showFeedback = true}) async {
    final provider = context.read<PortfolioProvider>();
    if (provider.isRefreshing) return;

    await provider.refreshAllPortfolios();
    if (!mounted) return;

    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.profit,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tüm varlıkların fiyat ve tarihsel verileri güncellendi.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    }
  }

  void _showAddPortfolioDialog(BuildContext context) {
    final provider = context.read<PortfolioProvider>();
    showDialog(
      context: context,
      builder: (_) => AddEditPortfolioDialog(
        onSave: (name, description) {
          provider.addPortfolio(name: name, description: description);
        },
      ),
    );
  }

  void _confirmDeletePortfolio(BuildContext context, String id, String name) {
    final provider = context.read<PortfolioProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Portföyü Sil'),
        content: Text(
          '"$name" portföyünü ve içindeki tüm varlıkları silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.loss),
            onPressed: () {
              provider.deletePortfolio(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final portfolios = provider.portfolios;
    final isProfit = provider.displayGrandTotalProfit >= 0;
    final profitColor = isProfit ? AppTheme.profit : AppTheme.loss;

    return Scaffold(
      body: Column(
        children: [
          // ÜST BAŞLIK & İSTATİSTİK ŞERİDİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                final hasStopaj = provider.grandTotalWithholdingTax > 0;
                final hasRealizedStopaj =
                    provider.grandTotalRealizedWithholdingTax > 0;
                final mode = provider.returnMode;

                final summaryCards = [
                  _buildHeaderSummaryCard(
                    title: 'Toplam Portföy Değeri',
                    badge: (hasStopaj || mode == ReturnCalculationMode.reel)
                        ? NetGrossBadge(mode: mode)
                        : null,
                    value: Formatters.currency(provider.displayGrandTotalValue),
                    subtitle: mode == ReturnCalculationMode.reel
                        ? 'Düzeltilmiş Maliyet: ${Formatters.currency(provider.grandTotalRealCost)}'
                        : 'Toplam Maliyet: ${Formatters.currency(provider.grandTotalCost)}',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppTheme.primaryLight,
                  ),
                  _buildHeaderSummaryCard(
                    title: mode == ReturnCalculationMode.reel
                        ? 'Reel Kâr / Zarar (TÜFE)'
                        : 'Toplam Kâr / Zarar',
                    badge: NetGrossBadge(mode: mode),
                    value: Formatters.currency(provider.displayGrandTotalProfit),
                    subtitle: Formatters.percent(
                        provider.displayGrandTotalProfitPercent),
                    icon: isProfit
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    iconColor: profitColor,
                    valueColor: profitColor,
                  ),
                  _buildHeaderSummaryCard(
                    title: 'Gerçekleşen Kâr / Zarar',
                    badge: hasRealizedStopaj
                        ? NetGrossBadge(
                            mode: mode == ReturnCalculationMode.brut
                                ? ReturnCalculationMode.brut
                                : ReturnCalculationMode.net,
                          )
                        : null,
                    value: Formatters.currency(
                      (hasRealizedStopaj && mode != ReturnCalculationMode.brut)
                          ? provider.grandTotalNetRealizedProfit
                          : provider.grandTotalRealizedProfit,
                    ),
                    subtitle: 'Kapatılan İşlemler',
                    icon: provider.grandTotalNetRealizedProfit >= 0
                        ? Icons.check_circle_outline_rounded
                        : Icons.highlight_off_rounded,
                    iconColor: provider.grandTotalNetRealizedProfit >= 0
                        ? AppTheme.profit
                        : AppTheme.loss,
                    valueColor: provider.grandTotalNetRealizedProfit >= 0
                        ? AppTheme.profit
                        : AppTheme.loss,
                  ),
                ];

                final actionButtons = SizedBox(
                  width: 210,
                  height: 84,
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddPortfolioDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Yeni Portföy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: provider.isRefreshing
                                    ? null
                                    : () => _refreshAllData(),
                                icon: provider.isRefreshing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(
                                  provider.isRefreshing ? '...' : 'Yenile (F5)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                  foregroundColor: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Ayarlar',
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                  foregroundColor: AppTheme.textPrimary,
                                ),
                                child: const Icon(Icons.settings_outlined, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: summaryCards[0]),
                            const SizedBox(width: 14),
                            Expanded(child: summaryCards[1]),
                            const SizedBox(width: 14),
                            Expanded(child: summaryCards[2]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      actionButtons,
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 250, child: summaryCards[0]),
                        const SizedBox(width: 12),
                        SizedBox(width: 250, child: summaryCards[1]),
                        const SizedBox(width: 12),
                        SizedBox(width: 250, child: summaryCards[2]),
                        const SizedBox(width: 16),
                        actionButtons,
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // ANA PORTFÖY KARTLARI IZGARASI (GRID)
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : portfolios.isEmpty
                    ? _buildEmptyState(context)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Ekran genişliğine göre masaüstü ızgara kolonları (1, 2 veya 3 kolon)
                          int crossAxisCount = 1;
                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(28),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              mainAxisExtent: 345,
                            ),
                            itemCount: portfolios.length,
                            itemBuilder: (context, index) {
                              final portfolio = portfolios[index];
                              return PortfolioCard(
                                portfolio: portfolio,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => PortfolioDetailDialog(
                                      portfolioId: portfolio.id,
                                    ),
                                  );
                                },
                                onEdit: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddEditPortfolioDialog(
                                      portfolio: portfolio,
                                      onSave: (name, description) {
                                        provider.updatePortfolio(
                                          id: portfolio.id,
                                          name: name,
                                          description: description,
                                        );
                                      },
                                    ),
                                  );
                                },
                                onDelete: () => _confirmDeletePortfolio(
                                  context,
                                  portfolio.id,
                                  portfolio.name,
                                ),
                                onToggleVisibility: () {
                                  provider.togglePortfolioVisibility(portfolio.id);
                                },
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    Widget? badge,
  }) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      badge,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Icon(
              Icons.folder_off_outlined,
              size: 52,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Portföy Bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Arama filtrenizi temizleyebilir veya yeni bir portföy oluşturabilirsiniz.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddPortfolioDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Portföy Oluştur'),
          ),
        ],
      ),
    );
  }
}
