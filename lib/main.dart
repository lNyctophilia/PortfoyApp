import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/auth_gate/services/auth_gate_service.dart';
import 'features/auth_gate/widgets/auth_gate_wrapper.dart';
import 'providers/portfolio_provider.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'models/portfolio.dart';
import 'core/navigation/adaptive_navigation.dart';
import 'models/return_mode.dart';
import 'widgets/net_gross_badge.dart';
import 'widgets/portfolio_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase başlatma uyarısı (Henüz yapılandırılmamış olabilir): $e');
  }
  await AuthGateService.instance.initialize();
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
      home: const AuthGateWrapper(
        child: PortfolioHomeScreen(),
      ),
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
    AdaptiveNavigation.openAddEditPortfolio(
      context,
      onSave: (name, description) {
        provider.addPortfolio(name: name, description: description);
      },
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
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      return _buildMobileView(context, provider, portfolios, isProfit, profitColor);
    }
    return _buildDesktopView(context, provider, portfolios, isProfit, profitColor);
  }

  Widget _buildDesktopView(
    BuildContext context,
    PortfolioProvider provider,
    List<Portfolio> portfolios,
    bool isProfit,
    Color profitColor,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          // ÜST BAŞLIK & İSTATİSTİK ŞERİDİ
          Container(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 600 ? 14 : 28, vertical: MediaQuery.sizeOf(context).width < 600 ? 12 : 16),
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

                final isMobile = constraints.maxWidth < 700;
                final summaryCards = [
                  _buildHeaderSummaryCard(
                    title: 'Toplam Portföy Değeri',
                    badge: (hasStopaj || mode == ReturnCalculationMode.reel)
                        ? NetGrossBadge(mode: mode)
                        : null,
                    value: Formatters.currency(provider.displayGrandTotalValue),
                    subtitle: 'Toplam Maliyet: ${Formatters.currency(provider.grandTotalCost)}',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppTheme.primaryLight,
                  ),
                  _buildHeaderSummaryCard(
                    title: 'Toplam Kâr / Zarar',
                    badge: NetGrossBadge(mode: mode),
                    value: Formatters.currency(provider.displayGrandTotalProfit),
                    subtitle: Formatters.percent(
                        provider.displayGrandTotalProfitPercent),
                    subtitleColor: mode == ReturnCalculationMode.reel
                        ? (provider.displayGrandTotalProfitPercent >= 0
                            ? AppTheme.profit
                            : AppTheme.loss)
                        : null,
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
                  width: 250,
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
                              message: 'Portföyleri Sırala',
                              child: OutlinedButton(
                                onPressed: () => AdaptiveNavigation.openReorderPortfolios(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                  foregroundColor: AppTheme.textPrimary,
                                ),
                                child: const Icon(Icons.swap_vert_rounded, size: 18),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
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

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mobil Üst Aksiyon Çubuğu
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddPortfolioDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Yeni Portföy',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: provider.isRefreshing ? null : () => _refreshAllData(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              foregroundColor: AppTheme.textPrimary,
                            ),
                            child: provider.isRefreshing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              foregroundColor: AppTheme.textPrimary,
                            ),
                            child: const Icon(Icons.settings_outlined, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      summaryCards[0],
                      const SizedBox(height: 8),
                      if (constraints.maxWidth < 500) ...[
                        summaryCards[1],
                        const SizedBox(height: 8),
                        summaryCards[2],
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: summaryCards[1]),
                            const SizedBox(width: 10),
                            Expanded(child: summaryCards[2]),
                          ],
                        ),
                      ],
                    ],
                  );
                } else if (isWide) {
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
                    physics: const BouncingScrollPhysics(),
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

                          final isMobileScreen = constraints.maxWidth < 600;
                          return GridView.builder(
                            padding: EdgeInsets.all(isMobileScreen ? 14 : 28),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isMobileScreen ? 12 : 20,
                              mainAxisSpacing: isMobileScreen ? 12 : 20,
                              mainAxisExtent: isMobileScreen ? 395 : 380,
                            ),
                            itemCount: portfolios.length,
                            itemBuilder: (context, index) {
                              final portfolio = portfolios[index];
                              return PortfolioCard(
                                portfolio: portfolio,
                                onTap: () {
                                  AdaptiveNavigation.openPortfolioDetail(
                                    context,
                                    portfolio.id,
                                  );
                                },
                                onEdit: () {
                                  AdaptiveNavigation.openAddEditPortfolio(
                                    context,
                                    portfolio: portfolio,
                                    onSave: (name, description) {
                                      provider.updatePortfolio(
                                        id: portfolio.id,
                                        name: name,
                                        description: description,
                                      );
                                    },
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
      ),
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    PortfolioProvider provider,
    List<Portfolio> portfolios,
    bool isProfit,
    Color profitColor,
  ) {
    final mode = provider.returnMode;
    final hasStopaj = provider.grandTotalWithholdingTax > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Portföylerim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (hasStopaj || mode == ReturnCalculationMode.reel)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: NetGrossBadge(mode: mode),
            ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: provider.isRefreshing ? null : () => _refreshAllData(),
            icon: provider.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            color: AppTheme.textSecondary,
          ),
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: AppTheme.textSecondary,
          ),
          PopupMenuButton<String>(
            tooltip: 'Seçenekler',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            color: AppTheme.surfaceElevated,
            onSelected: (value) {
              if (value == 'reorder') {
                AdaptiveNavigation.openReorderPortfolios(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reorder',
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, size: 18, color: AppTheme.textPrimary),
                    SizedBox(width: 10),
                    Text(
                      'Portföyleri Sırala',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshAllData(showFeedback: false),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : portfolios.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        _buildMobileSummaryCard(provider, isProfit, profitColor, mode),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Portföyler (${portfolios.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...portfolios.map((portfolio) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: PortfolioCard(
                              portfolio: portfolio,
                              onTap: () {
                                AdaptiveNavigation.openPortfolioDetail(
                                  context,
                                  portfolio.id,
                                );
                              },
                              onEdit: () {
                                AdaptiveNavigation.openAddEditPortfolio(
                                  context,
                                  portfolio: portfolio,
                                  onSave: (name, description) {
                                    provider.updatePortfolio(
                                      id: portfolio.id,
                                      name: name,
                                      description: description,
                                    );
                                  },
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
                            ),
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPortfolioDialog(context),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Yeni Portföy',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    PortfolioProvider provider,
    bool isProfit,
    Color profitColor,
    ReturnCalculationMode mode,
  ) {
    final hasRealizedStopaj = provider.grandTotalRealizedWithholdingTax > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Varlık Değeri',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              if (provider.grandTotalWithholdingTax > 0 || mode == ReturnCalculationMode.reel)
                NetGrossBadge(mode: mode),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.currency(provider.displayGrandTotalValue),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isProfit ? AppTheme.profitBg : AppTheme.lossBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: profitColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                  color: profitColor,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '${Formatters.currency(provider.displayGrandTotalProfit)} (${Formatters.percent(provider.displayGrandTotalProfitPercent)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: profitColor,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppTheme.borderSubtle, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam Maliyet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(provider.grandTotalCost),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: AppTheme.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gerçekleşen K/Z',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(
                        (hasRealizedStopaj && mode != ReturnCalculationMode.brut)
                            ? provider.grandTotalNetRealizedProfit
                            : provider.grandTotalRealizedProfit,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: provider.grandTotalNetRealizedProfit >= 0
                            ? AppTheme.profit
                            : AppTheme.loss,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    Color? subtitleColor,
    Widget? badge,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  style: TextStyle(
                    color: subtitleColor ?? AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: subtitleColor != null
                        ? FontWeight.w600
                        : FontWeight.normal,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      'Henüz Portföy Yok',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aşağıdaki butondan yeni bir portföy oluşturabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.4,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
