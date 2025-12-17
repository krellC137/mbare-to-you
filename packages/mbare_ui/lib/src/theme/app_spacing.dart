/// Spacing constants for consistent layout
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (8px)
  static const double unit = 8.0;

  // Spacing values
  static const double xs = unit * 0.5; // 4px
  static const double sm = unit; // 8px
  static const double md = unit * 2; // 16px
  static const double lg = unit * 3; // 24px
  static const double xl = unit * 4; // 32px
  static const double xxl = unit * 6; // 48px

  // Common use cases
  static const double padding = md;
  static const double paddingSmall = sm;
  static const double paddingLarge = lg;

  static const double margin = md;
  static const double marginSmall = sm;
  static const double marginLarge = lg;

  static const double cardPadding = md;
  static const double listItemPadding = md;
  static const double screenPadding = md;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusCircular = 999.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Button sizes
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;

  // Input field sizes
  static const double inputHeight = 48.0;
  static const double inputBorderWidth = 1.0;

  // Card elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}
