import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'button_size.dart';

/// Bouton secondaire avec bordure
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.size = ButtonSize.medium,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading || onPressed == null;

    return Container(
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.mediumAll,
        border: Border.all(
          color: isDisabled ? AppColors.border : AppColors.primary,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: AppRadius.mediumAll,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: size.iconSize,
                    height: size.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: size.iconSize,
                    color: AppColors.primary,
                  ),
                if (isLoading || icon != null) SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: size.textStyle.copyWith(
                    color: isDisabled ? AppColors.textTertiary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
          delay: 50.ms,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

