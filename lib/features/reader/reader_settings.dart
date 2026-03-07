import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final ReaderThemeMode currentTheme;
  final double currentFontSize;
  final ValueChanged<ReaderThemeMode> onThemeChanged;
  final ValueChanged<double> onFontSizeChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.currentFontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderThemeMode _theme;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _fontSize = widget.currentFontSize;
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
