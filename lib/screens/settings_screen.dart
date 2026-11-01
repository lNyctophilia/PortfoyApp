import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
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
              // BÖLÜM 1: HESAP VE BULUT SENKRONİZASYONU
              _buildAccountSection(context, provider),

              const SizedBox(height: 28),

              // BÖLÜM 2: GETİRİ HESAPLAMA MODU (RADIO BUTTON SEÇİMİ)
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
                            'Enflasyona (TÜFE) göre yüzdelik kâr/zarar getiri oranınızı gösterir.',
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

              // BÖLÜM 3: UYGULAMA HAKKINDA
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

  Widget _buildAccountSection(BuildContext context, PortfolioProvider provider) {
    final user = provider.currentUser;
    final isSignedIn = provider.isSignedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Hesap ve Bulut Senkronizasyonu'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: isSignedIn && user != null
              ? _buildSignedInContent(context, provider, user)
              : _buildSignedOutContent(context, provider),
        ),
      ],
    );
  }

  Widget _buildSignedOutContent(BuildContext context, PortfolioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_sync_rounded,
                color: AppTheme.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Hesabı ile Giriş Yap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Portföylerinizi güvenle buluta yedekleyin ve tüm cihazlarınızdan senkronize takip edin.',
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: provider.isSyncing
                ? null
                : () async {
                    try {
                      await provider.signInWithGoogle();
                      if (context.mounted && provider.isSignedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.surfaceLight,
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.profit,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Giriş yapıldı: ${provider.currentUser?.displayName ?? provider.currentUser?.email ?? ""}',
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.lossBg,
                            content: Text(
                              'Giriş yapılamadı: ${e.toString().replaceAll("Exception: ", "")}',
                              style: const TextStyle(color: AppTheme.loss),
                            ),
                          ),
                        );
                      }
                    }
                  },
            child: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryLight,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(
                        '''<svg viewBox="0 0 24 24" width="18" height="18"><path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.15z"/><path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/><path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15z"/><path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/></svg>''',
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Google ile Giriş Yap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInContent(
    BuildContext context,
    PortfolioProvider provider,
    User user,
  ) {
    final displayName = user.displayName ?? 'Google Kullanıcısı';
    final email = user.email ?? '';
    final photoUrl = user.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  photoUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildAvatarFallback(displayName),
                ),
              )
            else
              _buildAvatarFallback(displayName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (provider.isSyncing) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Bulut ile eşitleniyor...',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppTheme.profit,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.lastSyncTime != null
                              ? 'Bulutla senkronize (${DateFormat('HH:mm').format(provider.lastSyncTime!)})'
                              : 'Bulut eşitlemesi aktif',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.profit,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: AppTheme.borderSubtle, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceLight,
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderSubtle),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryLight,
                        ),
                      )
                    : const Icon(
                        Icons.sync_rounded,
                        size: 16,
                        color: AppTheme.primaryLight,
                      ),
                label: const Text(
                  'Şimdi Eşitle',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: provider.isSyncing
                    ? null
                    : () async {
                        await provider.syncWithCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.surfaceLight,
                              content: Text(
                                'Portföyler bulutla eşitlendi.',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.lossBg,
                  foregroundColor: AppTheme.loss,
                  side: BorderSide(
                    color: AppTheme.loss.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppTheme.loss,
                ),
                label: const Text(
                  'Çıkış Yap',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _confirmSignOut(context, provider),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppTheme.primaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, PortfolioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Google hesabınızdan çıkış yapmak istediğinize emin misiniz? Yerel portföy verileriniz cihazınızda kalmaya devam eder.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            child: const Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.loss,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Çıkış Yap'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.surfaceLight,
                    content: Text(
                      'Hesabınızdan çıkış yapıldı.',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                );
              }
            },
          ),
        ],
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

