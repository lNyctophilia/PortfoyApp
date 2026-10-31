import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/return_mode.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/net_gross_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          tooltip: 'Geri Dön',
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppTheme.surface,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.borderSubtle, height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            children: [
              // BÖLÜM 1: GETİRİ HESAPLAMA MODU (RADIO BUTTON SEÇİMİ)
              _buildSectionHeader('Getiri Hesaplama ve Gösterim Tercihi'),

              RadioGroup<ReturnCalculationMode>(
                groupValue: provider.returnMode,
                onChanged: (mode) {
                  if (mode != null) {
                    provider.setReturnMode(mode);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık ve Açıklama
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: AppTheme.primaryLight,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Getiri Hesaplama Modu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Portföy ve varlık kâr/zarar ve getiri oranlarının nasıl hesaplanacağını seçin.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // 1. SEÇENEK: BRÜT GETİRİ
                      _buildRadioOption(
                        context: context,
                        provider: provider,
                        mode: ReturnCalculationMode.brut,
                        icon: Icons.pie_chart_outline_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: 'Brüt Getiri',
                        subtitle:
                            'Stopaj vergisi ve enflasyon kesintisi yapılmaksızın tam brüt kârı ve yalın getiri oranını gösterir.',
                      ),

                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // 2. SEÇENEK: NET GETİRİ
                      _buildRadioOption(
                        context: context,
                        provider: provider,
                        mode: ReturnCalculationMode.net,
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppTheme.profit,
                        title: 'Net Getiri',
                        subtitle:
                            'Fon kârlarından yasal stopaj vergisi düşülerek cebe giren net kârı ve net getiri oranını listeler.',
                      ),

                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // 3. SEÇENEK: REEL GETİRİ
                      _buildRadioOption(
                        context: context,
                        provider: provider,
                        mode: ReturnCalculationMode.reel,
                        icon: Icons.auto_graph_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Reel Getiri',
                        subtitle:
                            'Bakiye ve kâr tutarınızı eksiltmeden, enflasyona (TÜFE) göre yüzdelik kâr/zarar getiri oranınızı gösterir.',
                      ),

                      const Divider(color: AppTheme.borderSubtle, height: 1),

                      // Önizleme & Aktif Mod Durum Kutusu
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Şuanki mod:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                NetGrossBadge(
                                  mode: provider.returnMode,
                                  fontSize: 11,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    provider.returnMode.shortDescription,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // REEL MOD İÇİN ÖZEL CANLI TÜFE PANELİ
                            if (provider.returnMode ==
                                ReturnCalculationMode.reel) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (provider.isLoadingInflation)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.cloud_done_rounded,
                                        size: 20,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Resmi TÜFE Oranları:',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                provider.latestAnnualInflation >
                                                        0
                                                    ? 'Son 1 Yıllık TÜFE: %${Formatters.percent(provider.latestAnnualInflation)}'
                                                    : (provider.isLoadingInflation
                                                        ? 'Veriler çekiliyor...'
                                                        : 'Veri güncel'),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (provider.periodInflation != null) ...[
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                _buildTufeBadge('1 Ay', provider.periodInflation!.monthly),
                                                _buildTufeBadge('3 Ay', provider.periodInflation!.threeMonthly),
                                                _buildTufeBadge('6 Ay', provider.periodInflation!.sixMonthly),
                                                _buildTufeBadge('1 Yıl', provider.periodInflation!.yearly),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          const Text(
                                            'Aylık TÜFE raporları esas alınarak hem dönemsel performanslar (1A, 3A, 6A, 1Y) hem de 1 yılı doldurmayan varlıklar dahil tüm tutma süreleri için enflasyon pro-rata düşülür.',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      tooltip:
                                          'TÜFE Verilerini İnternetten Yenile',
                                      onPressed: provider.isLoadingInflation
                                          ? null
                                          : () =>
                                              provider.refreshInflationData(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // BÖLÜM 2: UYGULAMA HAKKINDA
              _buildSectionHeader('Uygulama Hakkında'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.wallet_rounded,
                        color: AppTheme.primaryLight,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PortfoyApp',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          child: const Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kişisel Finans ve Portföy Takip Uygulaması',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 140,
                      child: Divider(color: AppTheme.borderSubtle, height: 1),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 15,
                          color: AppTheme.primaryLight,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Geliştirici: ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'lNyctophilia',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '© 2026 | Tüm hakları saklıdır.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required PortfolioProvider provider,
    required ReturnCalculationMode mode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = provider.returnMode == mode;

    return InkWell(
      onTap: () {
        provider.setReturnMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Button
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Radio<ReturnCalculationMode>(
                value: mode,
                activeColor: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 8),

            // İkon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Metinler ve Rozet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NetGrossBadge(
                        mode: mode,
                        fontSize: 9.5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildTufeBadge(String label, double rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '$label: %${rate.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF59E0B),
        ),
      ),
    );
  }
}

