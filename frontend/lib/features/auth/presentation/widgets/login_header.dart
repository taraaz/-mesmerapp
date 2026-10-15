import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Company Logo
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: Image.asset(
            'assets/logos/mesmer_logo.png',
            height: 44,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'AI Project Hub',
          style: AppTextStyles.h1,
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          'Project Management Simplified',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

      ],
    );
  }
}