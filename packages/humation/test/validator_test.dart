import 'package:humation/humation.dart';
import 'package:test/test.dart';

/// A tiny synthetic pack: one slot, one layer slot, parts supplied per test.
HumationManifest _manifest(List<Map<String, dynamic>> parts) =>
    HumationManifest.fromJson({
      'schemaVersion': '1.0',
      'template': {'id': 't', 'shortId': 't', 'name': 'T', 'version': '1'},
      'defaults': {
        'selections': {'head': 'p1'},
        'colors': {'hair': '000000'},
        'background': 'transparent',
        'crop': 'avatar',
      },
      'colors': [
        {
          'id': 'hair',
          'label': 'Hair',
          'default': '000000',
          'cssVariable': '--hm-hair',
        },
      ],
      'crops': {
        'avatar': {'x': 0, 'y': 0, 'width': 80, 'height': 80},
      },
      'selectionSlots': [
        {'id': 'head', 'label': 'Head', 'defaultPart': 'p1'},
      ],
      'uiGroups': [],
      'layerSlots': [
        {
          'id': 'head',
          'label': 'Head',
          'order': 1,
          'offset': {'x': 0, 'y': 0},
          'size': {'width': 80, 'height': 80},
        },
      ],
      'parts': parts,
      'aliases': [],
    });

Map<String, dynamic> _part(String id, String svg, {String slot = 'head'}) => {
  'id': id,
  'selectionSlot': slot,
  'uiGroups': [],
  'layers': [
    {'layerSlot': 'head', 'svg': svg},
  ],
};

void main() {
  test('accepts a part with only supported path commands', () {
    final manifest = _manifest([
      _part('p1', '<svg><path d="M0 0 L1 1 Z"/></svg>'),
    ]);
    expect(validateManifest(manifest), isEmpty);
  });

  test('flags an arc command in a double-quoted d attribute', () {
    final manifest = _manifest([
      _part('p1', '<svg><path d="M0 0 A1 1 0 0 1 1 1"/></svg>'),
    ]);
    final issues = validateManifest(manifest);
    expect(issues, hasLength(1));
    expect(issues.single.message, contains('unsupported path command'));
  });

  test('flags an arc command in a single-quoted d attribute', () {
    // Regression: the extraction regex used to be double-quote-only, so a
    // single-quoted `d` attribute silently skipped the check and reported no
    // issues even though the same unsupported command was present.
    final manifest = _manifest([
      _part('p1', "<svg><path d='M0 0 A1 1 0 0 1 1 1'/></svg>"),
    ]);
    final issues = validateManifest(manifest);
    expect(issues, hasLength(1));
    expect(issues.single.message, contains('unsupported path command'));
  });

  test('flags a quadratic command mixed with single and double quotes', () {
    final manifest = _manifest([
      _part('p1', '<svg><path d="M0 0 L1 1"/><path d=\'Q1 1 2 2\'/></svg>'),
    ]);
    final issues = validateManifest(manifest);
    expect(issues, hasLength(1));
  });

  test('flags an unknown selectionSlot', () {
    final manifest = _manifest([
      _part('p1', '<svg><path d="M0 0 Z"/></svg>', slot: 'nope'),
    ]);
    final issues = validateManifest(manifest);
    expect(issues.single.message, contains('unknown selectionSlot'));
  });

  test('flags an arc command in a hand-formatted multiline d attribute', () {
    // Regression: `.` does not match line breaks in Dart's RegExp by
    // default, so a `d` value spanning multiple lines used to match zero
    // times and silently skip the check entirely.
    final manifest = _manifest([
      _part('p1', '<svg><path d="M0 0\nL1 1\nA1 1 0 0 1 2 2"/></svg>'),
    ]);
    final issues = validateManifest(manifest);
    expect(issues, hasLength(1));
    expect(issues.single.message, contains('unsupported path command'));
  });

  test('does not treat id="..." as a d attribute', () {
    // Regression: the extraction pattern had no boundary before `d=`, so it
    // matched inside `id="..."` (which ends in the letter "d") and could
    // flag a part as broken based on unrelated attribute text.
    final manifest = _manifest([
      _part('p1', '<svg><path id="quat" fill="red"/></svg>'),
    ]);
    expect(validateManifest(manifest), isEmpty);
  });

  test('still finds the real d attribute next to a d-ending id', () {
    final manifest = _manifest([
      _part('p1', '<svg><path id="quat" d="M0 0 A1 1 0 0 1 1 1"/></svg>'),
    ]);
    final issues = validateManifest(manifest);
    expect(issues, hasLength(1));
    expect(issues.single.message, contains('unsupported path command'));
  });
}
