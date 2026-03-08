import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/epub_parser_service.dart';
import 'reader_settings.dart';

/// A WebView-based EPUB chapter renderer with smooth native scrolling.
///
/// Renders chapter HTML in a WebView and communicates with Flutter via
/// JavaScript channels for scroll progress, tap events, and content readiness.
class EpubWebViewReader extends StatefulWidget {
  final ParsedChapter chapter;
  final String combinedCss;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final ReaderFontFamily fontFamily;
  final ValueChanged<double> onScrollProgress;
  final VoidCallback onTap;
  final ValueChanged<String>? onTextSelected;
  final VoidCallback? onContentReady;

  const EpubWebViewReader({
    super.key,
    required this.chapter,
    required this.combinedCss,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.fontFamily,
    required this.onScrollProgress,
    required this.onTap,
    this.onTextSelected,
    this.onContentReady,
  });

  @override
  State<EpubWebViewReader> createState() => EpubWebViewReaderState();
}

class EpubWebViewReaderState extends State<EpubWebViewReader> {
  late WebViewController _controller;
  bool _isReady = false;
  File? _tempHtmlFile;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..addJavaScriptChannel('FlutterBridge', onMessageReceived: _onJsMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _isReady = true;
            widget.onContentReady?.call();
          },
        ),
      );

    _loadContent(widget.chapter);
  }

  @override
  void didUpdateWidget(EpubWebViewReader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If chapter changed, reload content
    if (oldWidget.chapter.index != widget.chapter.index) {
      _isReady = false;
      _loadContent(widget.chapter);
      return;
    }

    // If theme or font changed, update styles via JS
    if (oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.textColor != widget.textColor ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.fontFamily != widget.fontFamily) {
      _updateStyles();
    }
  }

  /// Load a chapter's HTML into the WebView.
  ///
  /// Writes the HTML to a temporary file and loads it via [loadFile] instead
  /// of [loadHtmlString] to avoid Android WebView's internal URL-encoding
  /// which can truncate chapters containing large base64-encoded images.
  Future<void> _loadContent(ParsedChapter chapter) async {
    final html = _buildHtmlDocument(chapter);
    final tempDir = await getTemporaryDirectory();
    _tempHtmlFile = File('${tempDir.path}/epub_reader_content.html');
    await _tempHtmlFile!.writeAsString(html);
    await _controller.loadFile(_tempHtmlFile!.path);
  }

  /// Update CSS styles dynamically without reloading.
  void _updateStyles() {
    if (!_isReady) return;

    final bgHex = _colorToHex(widget.backgroundColor);
    final textHex = _colorToHex(widget.textColor);
    final fontSize = widget.fontSize;
    final fontCss = widget.fontFamily.cssFontFamily;

    _controller.runJavaScript('''
      document.body.style.backgroundColor = '$bgHex';
      document.body.style.color = '$textHex';
      document.body.style.fontSize = '${fontSize}px';
      document.body.style.fontFamily = "$fontCss";
    ''');
  }

  /// Scroll to a specific percentage of the page.
  void scrollToPercent(double percent) {
    if (!_isReady) return;
    _controller.runJavaScript('''
      var maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      window.scrollTo({ top: maxScroll * $percent, behavior: 'smooth' });
    ''');
  }

  /// Handle messages from JavaScript.
  void _onJsMessage(JavaScriptMessage message) {
    final data = message.message;

    if (data.startsWith('scroll:')) {
      final percent = double.tryParse(data.substring(7)) ?? 0.0;
      widget.onScrollProgress(percent.clamp(0.0, 1.0));
    } else if (data.startsWith('select:')) {
      final selectedText = data.substring(7).trim();
      if (selectedText.isNotEmpty) {
        widget.onTextSelected?.call(selectedText);
      }
    } else if (data == 'tap') {
      widget.onTap();
    }
  }

  /// Build a full HTML document wrapping the chapter content.
  String _buildHtmlDocument(ParsedChapter chapter) {
    final bgHex = _colorToHex(widget.backgroundColor);
    final textHex = _colorToHex(widget.textColor);
    final fontSize = widget.fontSize;
    final fontCss = widget.fontFamily.cssFontFamily;
    final fontImportUrl = widget.fontFamily.googleFontsImportUrl;

    // Extract just the body content from the chapter HTML
    final bodyContent = _extractBodyContent(chapter.htmlContent);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  ${fontImportUrl != null ? '<link rel="stylesheet" href="$fontImportUrl">' : ''}
  <style>
    /* Reset */
    * { margin: 0; padding: 0; box-sizing: border-box; }

    /* EPUB original styles (filtered) */
    ${_sanitizeCss(widget.combinedCss)}

    /* Reader overrides */
    html {
      scroll-behavior: smooth;
      -webkit-overflow-scrolling: touch;
    }
    body {
      background-color: $bgHex;
      color: $textHex;
      font-family: $fontCss;
      font-size: ${fontSize}px;
      line-height: 1.8;
      padding: 16px 20px 60px 20px;
      word-wrap: break-word;
      overflow-wrap: break-word;
      -webkit-font-smoothing: antialiased;
    }
    img {
      max-width: 100%;
      height: auto;
      display: block;
      margin: 12px auto;
    }
    p { margin-bottom: 0.8em; }
    div { margin-bottom: 0.5em; }
    section { margin-bottom: 1em; }
    figure { margin: 1em 0; text-align: center; }
    figcaption { font-size: 0.9em; opacity: 0.7; margin-top: 0.5em; }
    svg { max-width: 100%; height: auto; display: block; margin: 12px auto; }
    image { max-width: 100%; height: auto; }
    h1, h2, h3, h4, h5, h6 {
      margin: 1em 0 0.5em 0;
      line-height: 1.3;
    }
    a { color: #6C63FF; text-decoration: none; }
    blockquote {
      border-left: 3px solid #6C63FF;
      padding-left: 16px;
      margin: 1em 0;
      opacity: 0.85;
    }
    pre, code {
      font-size: 0.9em;
      background: rgba(128,128,128,0.1);
      padding: 2px 4px;
      border-radius: 3px;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1em 0;
    }
    td, th {
      border: 1px solid rgba(128,128,128,0.3);
      padding: 8px;
    }
  </style>
</head>
<body>
  $bodyContent

  <script>
    // Scroll progress reporter
    var _scrollTimer = null;
    window.addEventListener('scroll', function() {
      if (_scrollTimer) clearTimeout(_scrollTimer);
      _scrollTimer = setTimeout(function() {
        var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        var scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
        var percent = scrollHeight > 0 ? (scrollTop / scrollHeight) : 0;
        FlutterBridge.postMessage('scroll:' + percent.toFixed(4));
      }, 100);
    }, { passive: true });

    // Text selection detection
    var _isSelecting = false;
    document.addEventListener('selectionchange', function() {
      var selection = window.getSelection();
      _isSelecting = selection.toString().trim().length > 0;
    });

    function _handleSelectionEnd() {
      var selection = window.getSelection().toString().trim();
      if (selection.length > 0) {
        FlutterBridge.postMessage('select:' + selection);
      }
    }

    document.addEventListener('mouseup', _handleSelectionEnd);
    document.addEventListener('touchend', _handleSelectionEnd);

    // Tap detection (only on non-interactive elements and when not selecting text)
    document.addEventListener('click', function(e) {
      if (_isSelecting) return;
      var tag = e.target.tagName.toLowerCase();
      if (tag !== 'a' && tag !== 'button' && tag !== 'input' && tag !== 'select') {
        FlutterBridge.postMessage('tap');
      }
    });

    // Signal content ready
    window.addEventListener('load', function() {
      FlutterBridge.postMessage('ready');
    });
  </script>
</body>
</html>
''';
  }

  /// Extract the inner content of the body tag, or return as-is.
  String _extractBodyContent(String html) {
    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*)</body>',
      caseSensitive: false,
    ).firstMatch(html);

    if (bodyMatch != null) {
      return bodyMatch.group(1) ?? html;
    }

    // If no body tag, check for full HTML document and strip head
    if (html.contains('<html') || html.contains('<HTML')) {
      // Remove everything outside body, or return content after </head>
      final headEnd = RegExp(r'</head>', caseSensitive: false).firstMatch(html);
      if (headEnd != null) {
        var content = html.substring(headEnd.end);
        // Remove closing tags
        content = content.replaceAll(
          RegExp(r'</html>', caseSensitive: false),
          '',
        );
        content = content.replaceAll(
          RegExp(r'<body[^>]*>', caseSensitive: false),
          '',
        );
        content = content.replaceAll(
          RegExp(r'</body>', caseSensitive: false),
          '',
        );
        return content.trim();
      }
    }

    return html;
  }

  /// Sanitize EPUB CSS to avoid conflicting with our reader styles.
  String _sanitizeCss(String css) {
    if (css.isEmpty) return '';
    // Remove any body/html rules from EPUB CSS (we override those)
    var sanitized = css.replaceAll(
      RegExp(r'(html|body)\s*\{[^}]*\}', caseSensitive: false),
      '',
    );
    // Remove @font-face rules (they won't resolve in data URI context)
    sanitized = sanitized.replaceAll(
      RegExp(r'@font-face\s*\{[^}]*\}', caseSensitive: false),
      '',
    );
    return sanitized;
  }

  /// Convert a Flutter Color to a CSS hex string.
  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tempHtmlFile?.delete().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
