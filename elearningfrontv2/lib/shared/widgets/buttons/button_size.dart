import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

enum ButtonSize {
  small(40, 12, 16, AppTextStyles.buttonSmall),
  medium(56, 24, 20, AppTextStyles.button),
  large(64, 32, 24, AppTextStyles.button);

  final double height;
  final double horizontalPadding;
  final double iconSize;
  final TextStyle textStyle;

  const ButtonSize(
    this.height,
    this.horizontalPadding,
    this.iconSize,
    this.textStyle,
  );
}

