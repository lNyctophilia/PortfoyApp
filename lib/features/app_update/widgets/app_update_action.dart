import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/update_info.dart';
import '../services/app_update_service.dart';

/// Apple-minimalist guncelleme denetleme ve tetikleme bileseni.
class AppUpdateAction extends StatefulWidget {
  const AppUpdateAction({super.key});

  @override
  State<AppUpdateAction> createState() => _AppUpdateActionState();
}

class _AppUpdateActionState extends State<AppUpdateAction> {
  bool _isChecking = false;
  bool _isUpdating = false;
  UpdateInfo? _lastResult;

  Future<void> _checkUpdates() async {
    if (_isChecking || _isUpdating) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final result = await AppUpdateService.instance.checkForUpdates();
      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _isChecking = false;
      });

      if (result.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage!,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (result.hasUpdate) {
        await _showUpdateModal(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Uygulama güncel. En son sürümü kullanıyorsunuz.',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Güncelleme denetlenirken bir hata oluştu.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showUpdateModal(UpdateInfo info) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !_isUpdating,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.accentLight,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Yeni Sürüm Mevcut',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mevcut Sürüm:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  info.currentVersion,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Yeni Sürüm:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  info.serverVersion,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Önbellek temizlenerek uygulama en yeni sürüme güncellenecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => Navigator.of(dialogCtx).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Daha Sonra'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        _isUpdating = true;
                                      });
                                      setState(() {
                                        _isUpdating = true;
                                      });
                                      await AppUpdateService.instance
                                          .applyUpdate(info.serverVersion);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLight,
                                foregroundColor: AppColors.textPrimary,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isUpdating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : const Text(
                                      'Şimdi Güncelle',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentLight,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Güncellemeler Denetleniyor...',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_lastResult != null && _lastResult!.hasUpdate) {
      return InkWell(
        onTap: () => _showUpdateModal(_lastResult!),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentLight.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 15,
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 6),
              const Text(
                'Yeni Sürüm Mevcut',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentLight,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Güncelle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _checkUpdates,
      icon: const Icon(Icons.sync_rounded, size: 16),
      label: const Text('Güncellemeleri Denetle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentLight,
        side: const BorderSide(color: AppColors.divider),
        backgroundColor: AppColors.card.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

