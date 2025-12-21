import 'package:flutter/material.dart';

/// Système de border radius
class AppRadius {
  AppRadius._();

  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xlarge = 24.0;
  static const circle = 999.0;

  // BorderRadius helpers
  static const smallAll = BorderRadius.all(Radius.circular(small));
  static const mediumAll = BorderRadius.all(Radius.circular(medium));
  static const largeAll = BorderRadius.all(Radius.circular(large));
  static const xlargeAll = BorderRadius.all(Radius.circular(xlarge));
  static const circleAll = BorderRadius.all(Radius.circular(circle));
}

