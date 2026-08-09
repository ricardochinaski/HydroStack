import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // -- Font families
  static final _metric = GoogleFonts.montserratTextTheme();
  static final _mono = GoogleFonts.jetBrainsMonoTextTheme();
  static final _body = GoogleFonts.interTextTheme();

  static TextTheme get textTheme {
    return TextTheme(
      // Metric values (pH, EC, Temp) — Montserrat ExtraBold 24-32px
      displayLarge: _metric.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
      displayMedium: _metric.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
      displaySmall: _metric.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w800),

      // Headings — Montserrat Bold
      headlineLarge: _metric.headlineLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      headlineMedium: _metric.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      headlineSmall: _metric.headlineSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),

      // Titles — Inter Semibold
      titleLarge: _body.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: _body.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: _body.titleSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),

      // Body — Inter Regular
      bodyLarge: _body.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: _body.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: _body.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400),

      // Labels — JetBrains Mono, uppercase, letter-spacing 1px
      labelLarge: _mono.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, height: 1.4),
      labelMedium: _mono.labelMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, height: 1.4),
      labelSmall: _mono.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 1, height: 1.4),
    );
  }

  // -- Convenience for inline metric text
  static const TextStyle metricStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.1,
  );

  static const TextStyle metricSmall = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w800,
    fontSize: 18,
    height: 1.1,
  );

  static const TextStyle techLabel = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1,
    height: 1.4,
  );

  static const TextStyle techLabelSmall = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontWeight: FontWeight.w500,
    fontSize: 9,
    letterSpacing: 0.8,
    height: 1.3,
  );
}
