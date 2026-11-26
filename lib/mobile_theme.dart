part of 'production_app.dart';

double _homeGutter(double width) => width >= 700
    ? 32
    : width < 360
    ? 16
    : 20;

final _mobileTheme = _buildMobileTheme();

ThemeData _buildMobileTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brand,
    primary: _brand,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xffd5eeea),
    onPrimaryContainer: const Color(0xff104c51),
    secondary: const Color(0xff575499),
    secondaryContainer: const Color(0xffeae9fa),
    onSecondaryContainer: const Color(0xff39385f),
    surface: Colors.white,
    onSurface: _ink,
    onSurfaceVariant: const Color(0xff506075),
    outlineVariant: _line,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
  );
  final type = base.textTheme;
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: _line),
  );
  final actionShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  final actionText = type.labelLarge?.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -.15,
  );
  const actionInsets = EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  return base.copyWith(
    scaffoldBackgroundColor: _background,
    textTheme: type.copyWith(
      headlineSmall: type.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.9,
      ),
      titleLarge: type.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      titleMedium: type.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -.25,
      ),
      bodyMedium: type.bodyMedium?.copyWith(height: 1.45, letterSpacing: 0),
      labelLarge: type.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -.15,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _background,
      foregroundColor: _ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: type.titleLarge?.copyWith(
        color: _ink,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -.65,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: actionInsets,
        textStyle: actionText,
        shape: actionShape,
        elevation: 0,
        iconSize: 19,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: actionShape,
        padding: actionInsets,
        textStyle: actionText,
        iconSize: 19,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: actionShape,
            textStyle: actionText,
            foregroundColor: _ink,
            padding: actionInsets,
            iconSize: 19,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused) ? _brand : _line,
                width: states.contains(WidgetState.focused) ? 2 : 1,
              ),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: actionShape,
        textStyle: actionText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: _brand,
        iconSize: 18,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: actionShape,
        iconSize: 21,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: actionShape,
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        side: const BorderSide(color: _line),
        textStyle: actionText,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _brand,
      foregroundColor: Colors.white,
      shape: actionShape,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: type.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: _brand, width: 1.6),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? _brand
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          letterSpacing: -.18,
          color: states.contains(WidgetState.selected)
              ? _ink
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}
