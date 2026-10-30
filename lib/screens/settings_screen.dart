import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
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
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            children: [
              // BÖLÜM 1: HESAPLAMA VE GÖSTERİM AYARLARI
              _buildSectionHeader(
                title: 'Hesaplama ve Gösterim Tercihleri',
                subtitle:
                    'Portföy ve varlık tutarlarının ekranda nasıl gösterileceğini özelleştirin.',
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    // Stopaj Switch Alanı
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppTheme.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Stopaj Kesilmiş Halleri Gösterilsin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Açık olduğunda fon kârlarından stopaj kesintisi düşülerek Net tutarlar gösterilir. '
                                  'Kapalı olduğunda kesinti öncesi Brüt tutarlar listelenir. '
                                  'Tutarlar tek satırda sade olarak sunulur.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Switch.adaptive(
                            value: provider.showNetValues,
                            activeTrackColor: AppTheme.primaryLight,
                            onChanged: (value) {
                              provider.setShowNetValues(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: AppTheme.borderSubtle, height: 1),

                    // Önizleme & Durum Kutusu
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Şu anki mod:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NetGrossBadge(
                            isNet: provider.showNetValues,
                            fontSize: 11,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.showNetValues
                                  ? 'Tüm varlıklar net (stopaj düşülmüş) değerleriyle listeleniyor.'
                                  : 'Tüm varlıklar brüt (kesinti öncesi) değerleriyle listeleniyor.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // BÖLÜM 2: BİLGİLENDİRME (STOPAJ HAKKINDA)
              _buildSectionHeader(
                title: 'Stopaj ve Vergi Bilgilendirmesi',
                subtitle:
                    'TEFAS fonlarında kâr üzerinden kesilen vergi hakkında özet kurallar.',
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppTheme.profit,
                      title: 'Hisse Senedi Yoğun Fonlar (%0 Stopaj)',
                      description:
                          'Portföyünün en az %80\'i BIST hisselerinden oluşan fonlarda elde edilen kazançlar vergiden muaftır (%0 stopaj).',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppTheme.borderSubtle, height: 1),
                    ),
                    _buildInfoRow(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      title: 'Diğer Yatırım Fonları (%10 - %15 Stopaj)',
                      description:
                          'Para piyasası, borçlanma araçları ve değişken fonlarda elde edilen kâr üzerinden ilgili stopaj oranı otomatik hesaplanır.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppTheme.borderSubtle, height: 1),
                    ),
                    _buildInfoRow(
                      icon: Icons.security_rounded,
                      iconColor: AppTheme.warning,
                      title: 'Yalnızca Kâr Üzerinden Hesaplanır',
                      description:
                          'Zararda olan fonlardan veya anaparadan hiçbir stopaj kesilmez; stopaj sadece getiri pozitif olduğunda devreye girer.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // BÖLÜM 3: UYGULAMA BİLGİSİ
              _buildSectionHeader(
                title: 'Uygulama Hakkında',
                subtitle: 'Sistem durumu ve veri depolama bilgileri.',
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppTheme.textPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PortföyApp • v1.0.0',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Portföy, varlık ve işlem verileriniz yerel bilgisayarınızda (%APPDATA%\\PortfoyApp) güvenle saklanır.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

