import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

import 'forgot_password_link.dart';
import 'login_header.dart';
import 'password_field.dart';
import 'remember_me_checkbox.dart';
import 'sign_in_button.dart';
import 'username_field.dart';
import 'version_footer.dart';

class LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const LoginCard({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoginHeader(),

          const SizedBox(height: AppSpacing.xl),

          UsernameField(controller: emailController),

          const SizedBox(height: AppSpacing.lg),

          PasswordField(
            controller: passwordController,
            onSubmitted: onSubmit,
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RememberMeCheckbox(),
              ForgotPasswordLink(),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          SignInButton(
            isLoading: isLoading,
            onPressed: onSubmit,
          ),

          const SizedBox(height: AppSpacing.lg),

          const VersionFooter(),
        ],
      ),
    );
  }
}
