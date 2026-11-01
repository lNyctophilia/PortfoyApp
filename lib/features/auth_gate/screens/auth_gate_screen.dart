import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../widgets/auth_gate_card.dart';

/// Fullscreen responsive gate screen protecting the application with Apple minimalism.
class AuthGateScreen extends StatelessWidget {
  final VoidCallback onSuccess;

  const AuthGateScreen({
    super.key,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400.0,
                  ),
                  child: AuthGateCard(
                    onAuthenticated: onSuccess,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

