import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../services/auth_gate_service.dart';

/// Ultra-minimalist Apple-inspired passcode verification card.
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
          const SizedBox(height: 32.0),

          // Password Field
          TextField(
            controller: _passwordController,
            focusNode: _focusNode,
            obscureText: _isObscured,
            enabled: !_isSubmitting && !isLockedOut,
            autofocus: true,
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
              onPressed: (_isSubmitting || isLockedOut) ? null : _submit,
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

