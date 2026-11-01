import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../screens/auth_gate_screen.dart';
import '../services/auth_gate_service.dart';

/// Reactive wrapper that enforces access gate authorization before exposing the app shell.
class AuthGateWrapper extends StatefulWidget {
  final Widget child;

  const AuthGateWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthGateWrapper> createState() => _AuthGateWrapperState();
}

class _AuthGateWrapperState extends State<AuthGateWrapper> {
  final AuthGateService _gateService = AuthGateService.instance;

  @override
  void initState() {
    super.initState();
    _gateService.addListener(_onGateStateChanged);
    if (!_gateService.isInitialized) {
      _gateService.initialize();
    }
  }

  @override
  void dispose() {
    _gateService.removeListener(_onGateStateChanged);
    super.dispose();
  }

  void _onGateStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gateService.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentLight,
              ),
            ),
          ),
        ),
      );
    }

    if (!_gateService.isUnlocked) {
      return AuthGateScreen(
        onSuccess: () {
          // AuthGateService handles state notification automatically
        },
      );
    }

    return widget.child;
  }
}

