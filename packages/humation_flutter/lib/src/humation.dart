import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

import 'image_export.dart';

/// One-stop entry point over the bundled `humation-1` pack.
///
/// The widget [HumationAvatar] covers on-screen use; this facade covers the
/// off-widget cases (resolving state, rasterising to an image or PNG). The
/// lower-level core functions remain available for full control.
final class Humation {
  Humation._();

  /// The bundled `humation-1` manifest.
  static HumationManifest get manifest => humation1Manifest;

  /// Decode the bundled manifest ahead of first use (one-time base64 + JSON
  /// parse). Safe to call more than once.
  static void prewarm() => prewarmHumation1();

  /// Seed to resolved state (selections plus default colours).
  static AvatarState resolve(String seed, {HumationManifest? manifest}) =>
      resolveAvatarState(
        manifest ?? humation1Manifest,
        CreateAvatarOptions(seed: seed),
      );

  /// Seed to a `pixels x pixels` image. Remember to `dispose()` it.
  static Future<ui.Image> imageForSeed(
    String seed, {
    required int pixels,
    HumationManifest? manifest,
    String? background,
  }) {
    final pack = manifest ?? humation1Manifest;
    final data = createAvatar(
      pack,
      CreateAvatarOptions(seed: seed, background: background),
    ).toRenderData();
    return renderAvatarToImage(data, pixels: pixels);
  }

  /// Seed to PNG bytes at `pixels x pixels`.
  static Future<Uint8List?> pngForSeed(
    String seed, {
    required int pixels,
    HumationManifest? manifest,
    String? background,
  }) {
    final pack = manifest ?? humation1Manifest;
    final data = createAvatar(
      pack,
      CreateAvatarOptions(seed: seed, background: background),
    ).toRenderData();
    return renderAvatarToPng(data, pixels: pixels);
  }
}
