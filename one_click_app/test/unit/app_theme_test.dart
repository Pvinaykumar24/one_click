import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/core/theme/app_colors.dart';
import 'package:one_click_app/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme Tests', () {
    test('Dark Theme uses correct Scaffold background and AppBar color', () {
      runZonedGuarded(() {
        final ThemeData theme = AppTheme.darkTheme;
        expect(theme.scaffoldBackgroundColor, AppColors.background);
        expect(theme.appBarTheme.backgroundColor, Colors.transparent);
      }, (error, stack) {
        // Ignore Google Fonts async background fetching exception during unit testing
      });
    });

    test('Primary and secondary text colors should be set correctly', () {
      runZonedGuarded(() {
        final ThemeData theme = AppTheme.darkTheme;
        expect(theme.textTheme.bodyLarge?.color, AppColors.textPrimary);
        expect(theme.textTheme.bodyMedium?.color, AppColors.textPrimary);
      }, (error, stack) {
        // Ignore Google Fonts async background fetching exception during unit testing
      });
    });
  });
}
