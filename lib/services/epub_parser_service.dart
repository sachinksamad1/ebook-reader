import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart';

/// A parsed chapter from an EPUB file.
class ParsedChapter {
  final String title;
  final String htmlContent;
  final int index;

  const ParsedChapter({
    required this.title,
    required this.htmlContent,
    required this.index,
  });
}

/// Result of parsing an EPUB file.
class ParsedEpub {
  final String title;
  final String author;
  final List<ParsedChapter> chapters;
  final Map<String, String>
  imageDataUris; // filename → data:image/...;base64,...
  final String combinedCss;

  const ParsedEpub({
    required this.title,
    required this.author,
    required this.chapters,
    required this.imageDataUris,
    required this.combinedCss,
  });
}

/// Service to parse EPUB files using the epubx package.
class EpubParserService {
  /// Parse an EPUB file into structured data.
  Future<ParsedEpub> parseBook(File file) async {
    final bytes = await file.readAsBytes();
    final book = await EpubReader.readBook(bytes);

    final title = book.Title ?? 'Untitled';
    final author = book.Author ?? 'Unknown Author';

    // Extract images as local file URIs
    final imageDataUris = await _extractImages(book);

    // Extract CSS
    final combinedCss = _extractCss(book);

    // Extract chapters
    final chapters = _extractChapters(book, imageDataUris);

    return ParsedEpub(
      title: title,
      author: author,
      chapters: chapters,
      imageDataUris: imageDataUris,
      combinedCss: combinedCss,
    );
  }

  /// Extract all images from the EPUB and save them to temporary files.
  Future<Map<String, String>> _extractImages(EpubBook book) async {
    final result = <String, String>{};
    final images = book.Content?.Images;

    if (images == null) return result;

    final tempDir = await getTemporaryDirectory();
    final epubImagesDir = Directory('${tempDir.path}/epub_images');
    if (!await epubImagesDir.exists()) {
      await epubImagesDir.create(recursive: true);
    }

    for (final entry in images.entries) {
      final fileName = entry.key;
      final imageFile = entry.value;
      final content = imageFile.Content;

      if (content != null) {
        // Clean filename to be safe for OS
        final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');
        final file = File('${epubImagesDir.path}/$safeName');
        await file.writeAsBytes(content);

        // Return as a file:// URI
        final fileUri = 'file://${file.path}';
        result[fileName] = fileUri;

        // Also store with just the filename (without path) for fallback matching
        final baseName = fileName.split('/').last;
        if (!result.containsKey(baseName)) {
          result[baseName] = fileUri;
        }
      }
    }

    return result;
  }

  /// Extract all CSS from the EPUB.
  String _extractCss(EpubBook book) {
    final cssFiles = book.Content?.Css;
    if (cssFiles == null) return '';

    final buffer = StringBuffer();
    for (final cssFile in cssFiles.values) {
      if (cssFile.Content != null) {
        buffer.writeln(cssFile.Content);
      }
    }
    return buffer.toString();
  }

  /// Extract chapters from the EPUB book.
  List<ParsedChapter> _extractChapters(
    EpubBook book,
    Map<String, String> imageDataUris,
  ) {
    final chapters = book.Chapters;
    if (chapters == null || chapters.isEmpty) {
      // Fallback: use HTML content files directly
      return _extractFromContentFiles(book, imageDataUris);
    }

    final result = <ParsedChapter>[];
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      var html = chapter.HtmlContent ?? '';
      html = _resolveImageSources(html, imageDataUris);

      result.add(
        ParsedChapter(
          title: chapter.Title ?? 'Chapter ${i + 1}',
          htmlContent: html,
          index: i,
        ),
      );

      // Also add sub-chapters
      if (chapter.SubChapters != null) {
        for (var j = 0; j < chapter.SubChapters!.length; j++) {
          final sub = chapter.SubChapters![j];
          var subHtml = sub.HtmlContent ?? '';
          subHtml = _resolveImageSources(subHtml, imageDataUris);

          result.add(
            ParsedChapter(
              title: sub.Title ?? 'Section ${j + 1}',
              htmlContent: subHtml,
              index: result.length,
            ),
          );
        }
      }
    }

    return result;
  }

  /// Fallback: extract content from HTML files when chapters aren't available.
  List<ParsedChapter> _extractFromContentFiles(
    EpubBook book,
    Map<String, String> imageDataUris,
  ) {
    final htmlFiles = book.Content?.Html;
    if (htmlFiles == null) return [];

    final result = <ParsedChapter>[];
    var i = 0;
    for (final entry in htmlFiles.entries) {
      var html = entry.value.Content ?? '';
      html = _resolveImageSources(html, imageDataUris);

      result.add(
        ParsedChapter(title: 'Section ${i + 1}', htmlContent: html, index: i),
      );
      i++;
    }

    return result;
  }

  /// Replace image src paths with base64 data URIs.
  ///
  /// Handles standard `src` attributes as well as SVG `href` and `xlink:href`
  /// attributes used by `<image>` elements in many EPUB files.
  String _resolveImageSources(String html, Map<String, String> imageDataUris) {
    // Match src, href, and xlink:href attributes
    final srcPattern = RegExp('(src|href|xlink:href)=["\']([^"\']+)["\']');
    return html.replaceAllMapped(srcPattern, (match) {
      final attrName = match.group(1)!;
      final originalSrc = match.group(2)!;

      // Skip non-image URIs (stylesheets, anchors, HTML links, etc.)
      if (originalSrc.startsWith('http') ||
          originalSrc.endsWith('.css') ||
          originalSrc.endsWith('.xhtml') ||
          originalSrc.endsWith('.html') ||
          originalSrc.endsWith('.ncx') ||
          originalSrc.endsWith('.opf') ||
          originalSrc.startsWith('#') ||
          originalSrc.startsWith('mailto:')) {
        return match.group(0)!;
      }

      // Try exact match first
      if (imageDataUris.containsKey(originalSrc)) {
        return '$attrName="${imageDataUris[originalSrc]}"';
      }
      // Try without leading ../
      final cleaned = originalSrc.replaceAll('../', '');
      if (imageDataUris.containsKey(cleaned)) {
        return '$attrName="${imageDataUris[cleaned]}"';
      }
      // Try just the filename
      final baseName = originalSrc.split('/').last;
      if (imageDataUris.containsKey(baseName)) {
        return '$attrName="${imageDataUris[baseName]}"';
      }
      return match.group(0)!;
    });
  }
}
