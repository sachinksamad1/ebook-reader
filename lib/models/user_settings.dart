import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_theme.dart';
import '../features/reader/reader_settings.dart';

/// User's global reader preferences.
class UserSettings {
  final String userId;
  final double fontSize;
  final ReaderFontFamily fontFamily;
  final ReaderThemeMode themeMode;

  const UserSettings({
    required this.userId,
    this.fontSize = 16.0,
    this.fontFamily = ReaderFontFamily.system,
    this.themeMode = ReaderThemeMode.light,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse font family safely
    var parsedFont = ReaderFontFamily.system;
    if (data.containsKey('font_family')) {
      final familyStr = data['font_family'] as String;
      parsedFont = ReaderFontFamily.values.firstWhere(
        (f) => f.name == familyStr,
        orElse: () => ReaderFontFamily.system,
      );
    }

    // Parse theme mode safely
    var parsedTheme = ReaderThemeMode.light;
    if (data.containsKey('theme_mode')) {
      final themeStr = data['theme_mode'] as String;
      parsedTheme = ReaderThemeMode.values.firstWhere(
        (t) => t.name == themeStr,
        orElse: () => ReaderThemeMode.light,
      );
    }

    return UserSettings(
      userId: doc.id,
      fontSize: (data['font_size'] ?? 16.0).toDouble(),
      fontFamily: parsedFont,
      themeMode: parsedTheme,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'font_size': fontSize,
      'font_family': fontFamily.name,
      'theme_mode': themeMode.name,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  UserSettings copyWith({
    String? userId,
    double? fontSize,
    ReaderFontFamily? fontFamily,
    ReaderThemeMode? themeMode,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
