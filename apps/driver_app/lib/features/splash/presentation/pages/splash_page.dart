import 'package:flutter/material.dart';
import 'package:mbare_ui/mbare_ui.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 80, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('MbareToYou Driver', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
