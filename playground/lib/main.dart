import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humation_flutter/humation_flutter.dart';
import 'package:web/web.dart' as web;

void main() {
  Humation.prewarm();
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Humation Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6A4C93),
        scaffoldBackgroundColor: const Color(0xFFFAFAF9),
        useMaterial3: true,
      ),
      home: const BuilderPage(),
    );
  }
}

/// Selection slots the reference builder hides (kept out of the tabs).
const _hiddenSlots = {'bottom'};

/// Colour slots the reference builder hides (kept out of the colour sheet).
const _hiddenColors = {'bottom'};

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key});

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  final HumationManifest _manifest = Humation.manifest;
  final TextEditingController _seed = TextEditingController(text: 'felix');

  // Tab order matches the reference builder (head first).
  static const _slotOrder = ['head', 'body', 'item', 'glasses'];
  late final List<SelectionSlot> _slots =
      _manifest.selectionSlots
          .where((s) => !_hiddenSlots.contains(s.id))
          .toList()
        ..sort((a, b) {
          int rank(String id) =>
              _slotOrder.contains(id) ? _slotOrder.indexOf(id) : 99;
          return rank(a.id).compareTo(rank(b.id));
        });
  late final List<ColorSlot> _colorSlots = _manifest.colors
      .where((c) => !_hiddenColors.contains(c.id))
      .toList();

  late Map<String, String> _selections;
  late Map<String, String> _colors;
  String _background = 'F6F5F4';
  late String _slotId = _slots.first.id;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _applySeed('felix');
  }

  @override
  void dispose() {
    _seed.dispose();
    super.dispose();
  }

  AvatarState get _state => createAvatar(
    _manifest,
    CreateAvatarOptions(
      selections: _selections,
      colors: _colors,
      background: _background,
    ),
  ).state;

  void _applySeed(String seed) {
    final state = Humation.resolve(seed);
    setState(() {
      _selections = Map.of(state.selections);
      _colors = Map.of(state.colors);
    });
  }

  void _randomize() {
    var salt = _seed.text.hashCode ^ DateTime.now().millisecond;
    setState(() {
      for (final slot in _slots) {
        final parts = getPartsForSlot(_manifest, slot.id);
        if (parts.isEmpty) continue;
        salt = (salt * 1103515245 + 12345) & 0x7fffffff;
        _selections[slot.id] = parts[salt % parts.length].id;
      }
    });
  }

  Future<void> _downloadPng() async {
    setState(() => _downloading = true);
    try {
      final data = createAvatar(
        _manifest,
        CreateAvatarOptions(
          selections: _selections,
          colors: _colors,
          background: _background,
        ),
      ).toRenderData();
      final png = await renderAvatarToPng(data, pixels: 512);
      if (png != null) _saveBytes(png, 'humation-avatar.png', 'image/png');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _downloadSvg() {
    final svg = createAvatar(
      _manifest,
      CreateAvatarOptions(
        selections: _selections,
        colors: _colors,
        background: _background,
      ),
    ).toSvg();
    _saveText(svg, 'humation-avatar.svg', 'image/svg+xml');
  }

  Future<void> _copyJson() async {
    final json = const JsonEncoder.withIndent('  ').convert(_state.toJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar JSON copied'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final preview = _previewPanel(wide);
                final picker = _pickerPanel();
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: preview),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: picker),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    preview,
                    const SizedBox(height: 16),
                    SizedBox(height: 460, child: picker),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewPanel(bool wide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _manifest.template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Avatar playground',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _openColors,
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Colours',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  maxHeight: 320,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: CustomPaint(
                      painter: _background == 'transparent'
                          ? _CheckerPainter()
                          : null,
                      child: HumationAvatar(
                        selections: _selections,
                        colors: _colors,
                        background: _background,
                        size: 320,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _seed,
            onChanged: _applySeed,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Seed',
              isDense: true,
              prefixIcon: const Icon(Icons.tag, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _randomize,
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Random'),
              ),
              FilledButton.icon(
                onPressed: _downloading ? null : _downloadPng,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined, size: 18),
                label: const Text('PNG'),
              ),
              FilledButton.tonalIcon(
                onPressed: _downloadSvg,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('SVG'),
              ),
              FilledButton.tonalIcon(
                onPressed: _copyJson,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('JSON'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final slot in _slots)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(slot.label),
                        selected: _slotId == slot.id,
                        onSelected: (_) => setState(() => _slotId = slot.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Expanded(child: _partGrid()),
        ],
      ),
    );
  }

  Widget _partGrid() {
    final parts = getPartsForSlot(_manifest, _slotId);
    final zoom = _slotId == 'glasses' ? 2.15 : 1.0;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        final selected = _selections[_slotId] == part.id;
        return InkWell(
          onTap: () => setState(() => _selections[_slotId] = part.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08)
                  : const Color(0xFFFAFAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black.withValues(alpha: 0.06),
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: HumationPartPreview(
                part: part,
                colors: _colors,
                size: 72,
                zoom: zoom,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openColors() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void pick(String slotId, String hex) {
              setState(() {
                if (slotId == 'background') {
                  _background = hex;
                } else {
                  _colors[slotId] = hex;
                }
              });
              setSheetState(() {});
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Colours',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final slot in _colorSlots) ...[
                        Text(
                          slot.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final hex
                                in _palette[slot.id] ?? const <String>[])
                              _Swatch(
                                hex: hex,
                                selected:
                                    (slot.id == 'background'
                                            ? _background
                                            : _colors[slot.id])
                                        ?.toUpperCase() ==
                                    hex.toUpperCase(),
                                onTap: () => pick(slot.id, hex),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const Map<String, List<String>> _palette = {
    'background': [
      'F6F5F4',
      'FFFFFF',
      'FFE5EC',
      'E6F4EA',
      'E3F2FD',
      'EDE7F6',
      'transparent',
    ],
    'stroke': ['000000', '3A2E2E', '2B2D42', '4A4A4A'],
    'hair': [
      '000000',
      '3A2E2E',
      '5B3A1E',
      '8B4513',
      'C8843C',
      'D4A017',
      'BFBFBF',
      'B23A48',
    ],
    'skin': [
      'FFFFFF',
      'FFDCB8',
      'F1C27D',
      'E0AC69',
      'C68642',
      '8D5524',
      '5C3A21',
    ],
    'clothes': [
      'FFFFFF',
      '2A2A2A',
      'E63946',
      'F4A261',
      '2A9D8F',
      '457B9D',
      '6A4C93',
    ],
  };
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final transparent = hex == 'transparent';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: transparent
              ? Colors.white
              : Color(int.parse('FF$hex', radix: 16)),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.black.withValues(alpha: 0.15),
            width: selected ? 3 : 1,
          ),
        ),
        child: transparent
            ? Icon(
                Icons.block,
                size: 18,
                color: Colors.black.withValues(alpha: 0.4),
              )
            : null,
      ),
    );
  }
}

/// A light checkerboard, shown behind a transparent-background avatar.
class _CheckerPainter extends CustomPainter {
  static const double _cell = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFECEBE9);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        if (((x ~/ _cell) + (y ~/ _cell)).isEven) continue;
        canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), dark);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => false;
}

// -- Web download helpers -----------------------------------------------------

void _saveBytes(Uint8List bytes, String filename, String mime) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  _saveBlob(blob, filename);
}

void _saveText(String text, String filename, String mime) {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: '$mime;charset=utf-8'),
  );
  _saveBlob(blob, filename);
}

void _saveBlob(web.Blob blob, String filename) {
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Revoke after the click is processed; an immediate revoke cancels the
  // download in some browsers.
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
}
