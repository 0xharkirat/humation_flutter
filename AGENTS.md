# AGENTS.md

Guidance for AI agents and new contributors working in this repository. Keep it
accurate: update it when the architecture changes.

## What this is

A Dart and Flutter port of Humation, a deterministic hand-drawn avatar engine. A
seed maps to a fixed set of SVG parts, composited and recoloured into an avatar.
Pure computation plus vector drawing. No AI, no network, no platform channels.

## Layout

Melos monorepo using Dart pub workspaces. Three published packages plus one
example.

```
packages/
  humation/                     pure Dart engine (no Flutter)
    lib/src/engine.dart         fnv1a (UTF-16, web-safe), normalizeHex
    lib/src/manifest.dart       manifest model + JSON decode
    lib/src/resolve.dart        seed + overrides -> AvatarState
    lib/src/avatar.dart         createAvatar -> toSvg / toJson / toRenderData
    lib/src/render_data.dart    AvatarRenderData / RenderFragment
    lib/src/ui_helpers.dart     getPartsForSlot / getPartsForUiGroup
    lib/src/validator.dart      validateManifest
  humation_assets_humation_1/   the humation-1 pack, base64-embedded
    lib/src/manifest_data.g.dart  GENERATED, do not edit
    lib/src/loader.dart         humation1Manifest (lazy decode)
    tool/embed.mjs              regenerates the .g.dart from tool/humation-1.json
  humation_flutter/             Flutter widget + renderer
    lib/src/parsing/geometry.dart   Affine, Rgba, SvgColor, PaintStyle, colour/transform parse
    lib/src/parsing/path_parser.dart  SVG `d` parser + primitives -> dart:ui Path
    lib/src/parsing/svg_parser.dart   XML walk -> Shapes (cascade, clips, stroke scaling)
    lib/src/render/humation_painter.dart  CustomPainter
    lib/src/render/parsed_part_cache.dart  parse-once cache, keyed partId#layerSlot
    lib/src/humation_avatar.dart    the HumationAvatar widget
    lib/src/humation.dart           Humation facade (resolve, image, png)
    lib/src/image_export.dart       render to ui.Image / PNG
    example/                        avatar builder app
```

Two more top-level projects, both separate from the Dart packages:
- `playground/`: a Flutter web avatar builder (workspace member, hosted on
  Firebase). See `playground/README.md`.
- `docs/`: a Fumadocs (Next.js, pnpm) site with TinaCMS visual editing; its home
  page embeds the playground by URL. See `docs/README.md`.

## The one rule: determinism

Part selection must stay byte-identical to the reference engine
(humation-labs/humation) and humation-swift. If you change selection, the same
seed would produce a different avatar and break cross-platform parity.

- `fnv1a` hashes **UTF-16 code units** (`String.codeUnits`), not runes or UTF-8.
  It uses a web-safe 32-bit multiply. Do not "simplify" either.
- Seeded picks index `manifest.partsInSlot(slot)` in **raw array order**. Do not
  sort that list. `getPartsForSlot` is the sorted, presentation-only variant.
- Golden vectors live in `packages/humation/test/engine_test.dart` and
  `packages/humation_assets_humation_1/test/humation_1_test.dart`. If they fail,
  the port is wrong, not the test.

## Rendering invariants (humation_flutter)

- SVG and Flutter canvases are both y-down, so coordinates map straight across.
  No vertical flip.
- The renderer supports only the asset subset: path commands `M L H V C S Z`,
  primitives `circle ellipse rect line polygon polyline`, transforms
  `translate scale rotate matrix`, `<style>` class rules, `fill-rule`,
  `clipPath`, and colours `#hex none named var(--hm-slot, #fallback)`. No arcs
  (`A`), no quadratics (`Q`/`T`). `validateManifest` enforces this.
- Stroke width is scaled by the SVG-internal transform at parse time (baked
  geometry does not otherwise scale the stroke). The global widget scale is a
  canvas transform, which scales stroke width on its own. Getting this wrong
  paints thick black blobs over shapes.
- Colours are stored as bindings (`SlotColor` / `FixedColor` / `NoneColor`),
  never concrete colours, so one parsed part redraws under any palette. Resolve
  happens in `HumationPainter`.
- Parsing is cached per `partId#layerSlot`. The cache is colour and size
  independent.

## Public API surface

Core (`package:humation/humation.dart`):
`createAvatar`, `HumationAvatar` (value type), `resolveAvatarState`,
`resolvePartId`, `CreateAvatarOptions`, `AvatarState`, `AvatarRenderData`,
`RenderFragment`, `HumationManifest` and its models, `fnv1a`, `normalizeHex`,
`getPartsForSlot`, `getPartsForUiGroup`, `validateManifest`.

Flutter (`package:humation_flutter/humation_flutter.dart`): everything above
(the core `HumationAvatar` value type is hidden so the widget owns the name),
plus the `HumationAvatar` widget, `HumationPartPreview`, the `Humation` facade,
`humation1Manifest`, `prewarmHumation1`, `renderAvatarToImage`,
`renderAvatarToPng`, the `HumationSlot` / `HumationColorSlot` string constants,
and `humationHex`. The widgets' `colors` accept a hex `String` or a Flutter
`Color`; core stays string-based (`Map<String, String>`) for custom packs.

## Conventions

- Prose and comments use no em dashes.
- Run before committing: `melos run analyze`, `melos run test`,
  `melos run test:flutter`, and `dart format`.
- `*.g.dart` is generated and excluded from analysis. Regenerate, do not edit.
