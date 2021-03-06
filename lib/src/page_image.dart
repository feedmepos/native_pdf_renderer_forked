part of 'page.dart';

/// Object containing a rendered image
/// in a pre-selected format in [_render] method
/// of [PdfPage]
class PdfPageImage {
  const PdfPageImage._({
    required this.id,
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
    required this.quality,
  });

  static const MethodChannel _channel =
      MethodChannel('io.scer.native_pdf_renderer');

  /// Page unique id. Needed for rendering and closing page.
  /// Generated when render page.
  final String? id;

  /// Page number. The first page is 1.
  final int pageNumber;

  /// Width of the rendered area in pixels.
  final int? width;

  /// Height of the rendered area in pixels.
  final int? height;

  /// Image bytes
  final Uint8List bytes;

  /// Target compression format
  final PdfPageFormat format;

  /// Target compression format quality
  final int quality;

  /// Render a full image of specified PDF file.
  ///
  /// [width], [height] specify resolution to render in pixels.
  /// As default PNG uses transparent background. For change it you can set
  /// [backgroundColor] property like a hex string ('#000000')
  /// [format] - image type, all types can be seen here [PdfPageFormat]
  /// [crop] - render only the necessary part of the image
  /// [quality] - hint to the JPEG and WebP compression algorithms (0-100)
  static Future<PdfPageImage?> _render({
    required String? pageId,
    required int pageNumber,
    required int width,
    required int height,
    required PdfPageFormat format,
    required String? backgroundColor,
    required Rect? crop,
    required int quality,
    required bool removeTempFile,
  }) async {
    if (format == PdfPageFormat.WEBP &&
        (UniversalPlatform.isIOS ||
            UniversalPlatform.isWindows ||
            UniversalPlatform.isMacOS)) {
      throw PdfNotSupportException(
        'PDF Renderer on IOS & Windows, MacOs platforms '
        'do not support WEBP format',
      );
    }

    backgroundColor ??=
        (format == PdfPageFormat.JPEG) ? '#FFFFFF' : '#00FFFFFF';

    final obj = await _channel.invokeMethod('render', {
      'pageId': pageId,
      'width': width,
      'height': height,
      'format': format.value,
      'backgroundColor': backgroundColor,
      'crop': crop != null,
      'crop_x': crop?.left.toInt(),
      'crop_y': crop?.top.toInt(),
      'crop_height': crop?.height.toInt(),
      'crop_width': crop?.width.toInt(),
      'quality': quality,
    });

    if (!(obj is Map<dynamic, dynamic>)) {
      return null;
    }

    final retWidth = obj['width'] as int?, retHeight = obj['height'] as int?;
    late final Uint8List pixels;
    if (UniversalPlatform.isAndroid ||
        UniversalPlatform.isIOS ||
        UniversalPlatform.isMacOS) {
      pixels = await getPixels(
        path: obj['path'],
        removeTempFile: removeTempFile,
      );
    } else {
      pixels = await getPixels(
        bytes: obj['data'],
        removeTempFile: removeTempFile,
      );
    }

    return PdfPageImage._(
      id: pageId,
      pageNumber: pageNumber,
      width: retWidth,
      height: retHeight,
      bytes: pixels,
      format: format,
      quality: quality,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PdfPageImage && other.bytes.lengthInBytes == bytes.lengthInBytes;

  @override
  int get hashCode => identityHashCode(id) ^ pageNumber;

  @override
  String toString() => '$runtimeType{'
      'id: $id, '
      'page: $pageNumber,  '
      'width: $width, '
      'height: $height, '
      'bytesLength: ${bytes.lengthInBytes}}';
}

class PdfNotSupportException implements Exception {
  PdfNotSupportException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}
