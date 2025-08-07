import 'package:flutter/material.dart';

/// Extension for Color to provide database-safe color values
extension ColorUtils on Color {
  /// Convert Color to int32-safe value by removing alpha channel
  /// Returns RGB value that fits in PostgreSQL INTEGER (int32) range
  int toARGB32() {
    // Remove alpha channel and keep only RGB values
    // This ensures the value fits within int32 range (0 to 16,777,215)
    return value & 0x00FFFFFF;
  }

  /// Convert Color to database-safe int value
  /// Alias for toARGB32() for clarity
  int toDatabaseColor() {
    return toARGB32();
  }
}

/// Utility functions for color handling
class ColorHelper {
  /// Convert database color value back to Flutter Color
  /// Adds opaque alpha channel to RGB value from database
  static Color fromDatabaseColor(int colorValue) {
    // Add opaque alpha channel (0xFF) to RGB value
    return Color(colorValue | 0xFF000000);
  }

  /// Check if a color value is safe for int32 database storage
  static bool isInt32Safe(int colorValue) {
    return colorValue >= 0 && colorValue <= 2147483647; // Max int32 value
  }

  /// Make any color value safe for int32 database storage
  static int makeInt32Safe(int colorValue) {
    return colorValue & 0x00FFFFFF; // Remove alpha, keep RGB only
  }
}
