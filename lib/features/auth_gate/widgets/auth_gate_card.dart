import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_colors.dart';
import '../services/auth_gate_service.dart';

/// Ultra-minimalist Apple-inspired passcode verification and Google Sign-in card.
class AuthGateCard extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthGateCard({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthGateCard> createState() => _AuthGateCardState();
}

class _AuthGateCardState extends State<AuthGateCard> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isObscured = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownCheck();
  }

  void _startCountdownCheck() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && AuthGateService.instance.isLockedOut) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleSubmitting || _isSubmitting) return;

    setState(() {
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userCred = await AuthService().signInWithGoogle();
      if (userCred?.user != null) {
        final user = userCred!.user!;
        await FirestoreService().markUserApproved(user);
        await AuthGateService.instance.unlockByGoogleUser(user.uid);
        if (mounted) {
          widget.onAuthenticated();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen şifreyi giriniz';
      });
      return;
    }

    if (AuthGateService.instance.isLockedOut) {
      final seconds = AuthGateService.instance.remainingLockoutSeconds;
      setState(() {
        _errorMessage = 'Çok fazla deneme. Lütfen $seconds sn bekleyin';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await AuthGateService.instance.verifyAndUnlock(password);

    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else {
      final isLocked = AuthGateService.instance.isLockedOut;
      final seconds = AuthGateService.instance.remainingLockoutSeconds;
      setState(() {
        _isSubmitting = false;
        _errorMessage = isLocked
            ? 'Çok fazla hatalı deneme. $seconds sn bekleyin'
            : 'Geçersiz şifre';
        _passwordController.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockedOut = AuthGateService.instance.isLockedOut;
    final remaining = AuthGateService.instance.remainingLockoutSeconds;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: _errorMessage != null ? AppColors.danger : AppColors.divider,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32.0,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimal Icon
          Center(
            child: Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1.0,
                ),
              ),
              child: const Icon(
                CupertinoIcons.lock_shield,
                color: AppColors.accentLight,
                size: 28.0,
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // Title
          const Text(
            'PortfoyApp',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24.0),

          // Google Sign-In Button
          SizedBox(
            height: 48.0,
            child: OutlinedButton(
              onPressed: (_isGoogleSubmitting || _isSubmitting) ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: 0,
              ),
              child: _isGoogleSubmitting
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentLight,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          '''<svg viewBox="0 0 24 24" width="18" height="18"><path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.15z"/><path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/><path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15z"/><path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/></svg>''',
                        ),
                        const SizedBox(width: 10.0),
                        const Text(
                          'Google ile Giriş Yap',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20.0),

          // Subtle Divider: "veya"
          const Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.divider,
                  thickness: 1.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'veya',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.divider,
                  thickness: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20.0),

          // Password Field
          TextField(
            controller: _passwordController,
            focusNode: _focusNode,
            obscureText: _isObscured,
            enabled: !_isSubmitting && !_isGoogleSubmitting && !isLockedOut,
            autofocus: false,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
            cursorColor: AppColors.accentLight,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: isLockedOut
                  ? 'Bekleyin ($remaining sn)'
                  : 'Erişim Şifresi',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14.0,
              ),
              prefixIcon: const Icon(
                CupertinoIcons.lock,
                color: AppColors.textSecondary,
                size: 18.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured
                      ? CupertinoIcons.eye_slash
                      : CupertinoIcons.eye,
                  color: AppColors.textSecondary,
                  size: 18.0,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.0),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.0),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.0),
                borderSide: const BorderSide(
                  color: AppColors.accentLight,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Error / Status feedback
          if (_errorMessage != null) ...[
            const SizedBox(height: 16.0),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 24.0),

          // Submit Action Button
          SizedBox(
            height: 48.0,
            child: ElevatedButton(
              onPressed: (_isSubmitting || _isGoogleSubmitting || isLockedOut) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLight,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
