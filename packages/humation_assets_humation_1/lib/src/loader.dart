import 'dart:convert';

import 'package:humation/humation.dart';

import 'manifest_data.g.dart';

HumationManifest? _cached;

/// The bundled `humation-1` manifest (86 parts with inline SVG).
///
/// Decoded from an embedded base64 constant on first access and cached for the
/// process lifetime. There is no file or asset loading, so this works on the
/// server, the web, and Flutter alike. Call [prewarmHumation1] once at startup
/// to move the one-time decode off a latency-sensitive frame.
HumationManifest get humation1Manifest => _cached ??= HumationManifest.fromJson(
  json.decode(utf8.decode(base64.decode(humation1ManifestBase64)))
      as Map<String, dynamic>,
);

/// Force the one-time decode of [humation1Manifest] ahead of first use.
void prewarmHumation1() => humation1Manifest;
