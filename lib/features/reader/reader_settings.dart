import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Available font families for the reader.
enum ReaderFontFamily {
  system('System Default', null),
  serif('Serif', 'Merriweather'),
  sansSerif('Sans-Serif', 'Inter'),
  mono('Monospace', 'JetBrains Mono'),
  literata('Literata', 'Literata'),
  lora('Lora', 'Lora');

  final String label;
  final String? googleFontName;
  const ReaderFontFamily(this.label, this.googleFontName);

  /// CSS font-family value for the WebView.
  String get cssFontFamily {
    switch (this) {
      case ReaderFontFamily.system:
        return "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
      case ReaderFontFamily.serif:
        return "'Merriweather', Georgia, serif";
      case ReaderFontFamily.sansSerif:
        return "'Inter', -apple-system, sans-serif";
      case ReaderFontFamily.mono:
        return "'JetBrains Mono', 'Courier New', monospace";
      case ReaderFontFamily.literata:
        return "'Literata', Georgia, serif";
      case ReaderFontFamily.lora:
        return "'Lora', Georgia, serif";
    }
  }

  /// Google Fonts CSS @import URL for the WebView.
  String? get googleFontsImportUrl {
    if (googleFontName == null) return null;
    final encoded = googleFontName!.replaceAll(' ', '+');
    return 'https://fonts.googleapis.com/css2?family=$encoded:wght@400;600;700&display=swap';
  }
}

class ReaderSettingsSheet extends StatefulWidget {
  final ReaderThemeMode currentTheme;
  final double currentFontSize;
  final ReaderFontFamily currentFontFamily;
  final ValueChanged<ReaderThemeMode> onThemeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<ReaderFontFamily> onFontFamilyChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.currentFontSize,
    required this.currentFontFamily,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderThemeMode _theme;
  late double _fontSize;
  late ReaderFontFamily _fontFamily;

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _fontSize = widget.currentFontSize;
    _fontFamily = widget.currentFontFamily;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Reader Settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Font Family
          Text('Font', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ReaderFontFamily.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final font = ReaderFontFamily.values[index];
                return _buildFontChip(font);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Font Size
          Text('Font Size', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12,
                  max: 28,
                  divisions: 8,
                  label: '${_fontSize.toInt()}',
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    widget.onFontSizeChanged(value);
                  },
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 20),

          // Page Theme
          Text('Page Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption(
                label: 'Light',
                mode: ReaderThemeMode.light,
                bgColor: AppTheme.readerLightBg,
                textColor: AppTheme.readerLightText,
                borderColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                label: 'Dark',
                mode: ReaderThemeMode.dark,
                bgColor: AppTheme.readerDarkBg,
                textColor: AppTheme.readerDarkText,
                borderColor: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                label: 'Sepia',
                mode: ReaderThemeMode.sepia,
                bgColor: AppTheme.readerSepiaBg,
                textColor: AppTheme.readerSepiaText,
                borderColor: const Color(0xFFD4C4A8),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFontChip(ReaderFontFamily font) {
    final isSelected = _fontFamily == font;
    final theme = Theme.of(context);

    // Render the chip label in the font's own typeface
    TextStyle chipStyle = TextStyle(
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      color: isSelected
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface,
    );

    if (font.googleFontName != null) {
      chipStyle = GoogleFonts.getFont(
        font.googleFontName!,
        textStyle: chipStyle,
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _fontFamily = font);
        widget.onFontFamilyChanged(font);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(font.label, style: chipStyle),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required ReaderThemeMode mode,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final isSelected = _theme == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _theme = mode);
          widget.onThemeChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : borderColor,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
