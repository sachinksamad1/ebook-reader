import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Manages local caching of ebook files
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final _cacheManager = DefaultCacheManager();

  /// Download and cache a file from a URL, returns the local file
  Future<File> getCachedFile(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file;
    }
    final file = await _cacheManager.getSingleFile(url);
    return file;
  }

  /// Check if file is already cached
  Future<bool> isCached(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  /// Get the local cache directory for books
  Future<Directory> getBooksDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}
