import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:humation/humation.dart';

import 'render/humation_painter.dart';

/// Rasterise [data] to a `pixels x pixels` [ui.Image].
///
/// Works on every platform (it uses only `dart:ui`). Remember to `dispose()` the
/// returned image when done.
Future<ui.Image> renderAvatarToImage(
  AvatarRenderData data, {
  required int pixels,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  HumationPainter(
    data: data,
    repaintToken: '',
  ).paint(canvas, ui.Size(pixels.toDouble(), pixels.toDouble()));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(pixels, pixels);
  } finally {
    picture.dispose();
  }
}

/// Rasterise [data] to PNG bytes at `pixels x pixels`.
Future<Uint8List?> renderAvatarToPng(
  AvatarRenderData data, {
  required int pixels,
}) async {
  final image = await renderAvatarToImage(data, pixels: pixels);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
