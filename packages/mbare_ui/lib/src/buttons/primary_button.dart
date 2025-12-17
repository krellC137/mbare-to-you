import 'package:flutter/material.dart';
import 'package:mbare_ui/src/theme/app_spacing.dart';
import 'package:mbare_ui/src/widgets/loading_indicator.dart';

/// Primary elevated button with loading state
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SmallLoadingIndicator(color: Colors.white)
                : Icon(icon),
            label: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SmallLoadingIndicator(color: Colors.white)
                : child,
          );

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: button,
          )
        : SizedBox(
            height: AppSpacing.buttonHeight,
            child: button,
          );
  }
}
