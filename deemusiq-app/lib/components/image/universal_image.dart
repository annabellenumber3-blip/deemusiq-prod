import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:deemusiq/collections/assets.gen.dart';

/// Configured cache manager with reasonable size limits for album art.
/// Defaults: max 200 files, max 100MB total cache, stale period 30 days.
class AlbumArtCacheManager {
  static CacheManager? _instance;
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        'album_art_cache',
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'album_art_cache'),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class UniversalImage extends HookWidget {
  final String path;
  final double? height;
  final double? width;
  final double scale;
  final String? placeholder;
  final BoxFit? fit;
  const UniversalImage({
    required this.path,
    this.height,
    this.width,
    this.placeholder,
    this.fit,
    this.scale = 1,
    super.key,
  });

  static ImageProvider imageProvider(
    String path, {
    final double? height,
    final double? width,
    final double scale = 1,
  }) {
    if (path.startsWith("http")) {
      return CachedNetworkImageProvider(
        path,
        maxHeight: height?.toInt(),
        maxWidth: width?.toInt(),
        cacheKey: path,
        scale: scale,
        cacheManager: AlbumArtCacheManager.instance,
      );
    } else if (path.startsWith("assets/")) {
      return AssetImage(path);
    } else if (Uri.tryParse(path) != null) {
      return FileImage(File(path), scale: scale);
    }
    return MemoryImage(base64Decode(path), scale: scale);
  }

  @override
  Widget build(BuildContext context) {
    if (path.startsWith("http")) {
      return FadeInImage(
        image: CachedNetworkImageProvider(
          path,
          maxHeight: height?.toInt(),
          maxWidth: width?.toInt(),
          cacheKey: path,
          scale: scale,
          cacheManager: AlbumArtCacheManager.instance,
        ),
        height: height,
        width: width,
        placeholder: AssetImage(placeholder ?? Assets.images.placeholder.path),
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset(
            placeholder ?? Assets.images.placeholder.path,
            width: width,
            height: height,
            cacheHeight: height?.toInt(),
            cacheWidth: width?.toInt(),
            scale: scale,
          );
        },
        fit: fit,
      );
    } else if (Uri.tryParse(path) != null && !path.startsWith("assets")) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        cacheHeight: height?.toInt(),
        cacheWidth: width?.toInt(),
        scale: scale,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            placeholder ?? Assets.images.placeholder.path,
            width: width,
            height: height,
            cacheHeight: height?.toInt(),
            cacheWidth: width?.toInt(),
            scale: scale,
          );
        },
      );
    } else if (path.startsWith("assets")) {
      return Image.asset(
        path,
        width: width,
        height: height,
        cacheHeight: height?.toInt(),
        cacheWidth: width?.toInt(),
        scale: scale,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            placeholder ?? Assets.images.placeholder.path,
            width: width,
            height: height,
            cacheHeight: height?.toInt(),
            cacheWidth: width?.toInt(),
            scale: scale,
          );
        },
      );
    }

    return Image.memory(
      base64Decode(path),
      width: width,
      height: height,
      cacheHeight: height?.toInt(),
      cacheWidth: width?.toInt(),
      scale: scale,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          placeholder ?? Assets.images.placeholder.path,
          width: width,
          height: height,
          cacheHeight: height?.toInt(),
          cacheWidth: width?.toInt(),
          scale: scale,
        );
      },
    );
  }
}
