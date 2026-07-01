// Regenerate lib/src/manifest_data.g.dart from tool/humation-1.json.
//
// The manifest (manifest + inline SVG for 86 parts) is embedded as a base64
// Dart constant so the pack is pure Dart and needs no asset loading. Base64 is
// used rather than a raw string so no character in the SVG data can break the
// literal.
//
// Usage: node tool/embed.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const source = join(here, 'humation-1.json');
const out = join(here, '..', 'lib', 'src', 'manifest_data.g.dart');

const b64 = readFileSync(source).toString('base64');

const header = [
  '// GENERATED FILE - DO NOT EDIT.',
  '//',
  '// Base64-encoded humation-1 asset manifest (manifest + inline SVG for 86',
  '// parts), sourced from @humation/assets-humation-1 (MIT). Decoded once,',
  '// lazily, by [humation1Manifest]. Regenerate with tool/embed.mjs.',
  '// ignore_for_file: type=lint',
  '',
].join('\n');

const body = `const String humation1ManifestBase64 =\n    '${b64}';\n`;

writeFileSync(out, header + body);
console.log(`wrote ${out} (${b64.length} base64 chars)`);
