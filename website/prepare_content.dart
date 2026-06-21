// `prepare_content.dart` is a build-time script; stdout feedback is
// intentional.
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;

/// Prepares the funx markdown docs for Hugo + Lotus Docs.
///
/// 1. Copies `doc/` into `content/docs/` preserving the directory tree.
/// 2. Turns top-level category files (e.g. `concurrency.md`) into section
///    landing pages: `concurrency/_index.md`.
/// 3. Adds front matter to every page, including category-specific icons and
///    weights so the sidebar is ordered consistently.
/// 4. Generates `static/raw/` — plain-text mirrors of every documentation
///    page served as `index.html` files containing only the original Markdown
///    source.
///    These pages are intentionally free of navigation, styling, or HTML
///    wrappers so LLMs can fetch them with minimal token overhead.
/// 5. Regenerates `static/llms.txt` to point LLMs at the raw pages.
void main() {
  final sourceDir = Directory('../doc');
  final docsDir = Directory('content/docs')..createSync(recursive: true);
  final staticRawDir = Directory('static/raw')..createSync(recursive: true);

  // Clean previous run.
  if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
  if (staticRawDir.existsSync()) staticRawDir.deleteSync(recursive: true);

  // Prepare the human-readable docs section.
  _prepareDocs(sourceDir, docsDir);

  // Prepare the AI-friendly raw section as plain Markdown files.
  _prepareStaticRaw(sourceDir, staticRawDir);

  // Generate the LLM discovery file.
  _generateLlmsTxt(sourceDir, Directory('static'));
}

/// Prepares `content/docs/` from the source `doc/` tree.
void _prepareDocs(Directory sourceDir, Directory targetDir) {
  targetDir.createSync(recursive: true);

  // Copy everything preserving structure.
  _copyDirectory(sourceDir, targetDir);

  // Move top-level category files into their own section folders.
  final topFiles = targetDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md') && !f.path.endsWith('/index.md'))
      .toList();

  for (final file in topFiles) {
    final name = p.basenameWithoutExtension(file.path);
    final sectionDir = Directory(p.join(targetDir.path, name))..createSync();
    file.renameSync(p.join(sectionDir.path, '_index.md'));
  }

  // Root index becomes the docs section landing page.
  final rootIndex = File(p.join(targetDir.path, 'index.md'));
  if (rootIndex.existsSync()) {
    rootIndex.renameSync(p.join(targetDir.path, '_index.md'));
  }

  // Add front matter to every markdown file.
  final now = _toRfc3339(DateTime.now());
  final files = targetDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  for (final file in files) {
    final text = file.readAsStringSync();
    if (text.startsWith('---')) continue;

    final title = _extractTitle(text) ?? _titleFromPath(file.path);
    final description = _extractDescription(text);
    final parent = p.basename(p.dirname(file.path));
    final weight = _weightFromPath(file.path, parent);
    final icon = _iconForPath(file.path, parent);

    final frontMatter =
        '''
---
title: "$title"
description: "$description"
icon: "$icon"
date: "$now"
lastmod: "$now"
draft: false
toc: true
weight: $weight
---

''';
    file.writeAsStringSync(frontMatter + text);
  }

  print('Prepared ${files.length} docs content files.');
}

/// Generates `static/raw/` from the source `doc/` tree.
///
/// Each Markdown file becomes an `index.html` file containing only the
/// Markdown source. The directory layout mirrors the docs URLs, so
/// `doc/concurrency/lock.md` is served at `/raw/concurrency/lock/`.
void _prepareStaticRaw(Directory sourceDir, Directory targetDir) {
  targetDir.createSync(recursive: true);

  final files = sourceDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  for (final file in files) {
    final relative = p.relative(file.path, from: sourceDir.path);
    final normalized = relative.replaceAll(r'\', '/');
    final content = _stripFrontMatter(file.readAsStringSync());
    final urlPath = _rawUrlPath(normalized);

    final targetPath = urlPath.isEmpty
        ? p.join(targetDir.path, 'index.html')
        : p.join(targetDir.path, urlPath, 'index.html');

    final targetFile = File(targetPath);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(content);
  }

  print('Prepared ${files.length} raw content files.');
}

/// Removes Hugo front matter from [text] if present.
///
/// Source files in `doc/` do not contain front matter, but this makes the
/// generator robust against future changes.
String _stripFrontMatter(String text) {
  if (!text.startsWith('---')) return text;
  final end = text.indexOf('---', 3);
  if (end == -1) return text;
  return text.substring(end + 3).trimLeft();
}

void _copyDirectory(Directory source, Directory target) {
  target.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    final dest = File(p.join(target.path, name));
    if (entity is Directory) {
      _copyDirectory(entity, Directory(dest.path));
    } else if (entity is File) {
      entity.copySync(dest.path);
    }
  }
}

/// Generates `static/llms.txt` with links to the plain-text raw documentation.
void _generateLlmsTxt(Directory sourceDir, Directory staticDir) {
  const baseUrl = 'https://makjac.github.io/funx';
  final buffer = StringBuffer()
    ..writeln('# funx')
    ..writeln()
    ..writeln('> A Dart package of composable function decorators.')
    ..writeln()
    ..writeln(
      'funx wraps ordinary functions in small, chainable, reusable building '
      'blocks for timing, concurrency, reliability, caching, observability, '
      'and more.',
    )
    ..writeln()
    ..writeln('## Author')
    ..writeln()
    ..writeln('Maksymilian Jakcowski — https://github.com/makjac')
    ..writeln()
    ..writeln('## Resources')
    ..writeln()
    ..writeln('- Package: https://pub.dev/packages/funx')
    ..writeln('- API reference: https://pub.dev/documentation/funx/latest/')
    ..writeln('- Library docs: https://pub.dev/documentation/funx/latest/funx/')
    ..writeln('- Repository: https://github.com/makjac/funx')
    ..writeln('- Author: https://github.com/makjac')
    ..writeln('- Website: $baseUrl')
    ..writeln()
    ..writeln('## Documentation sections (AI-friendly plain text)')
    ..writeln()
    ..writeln('- Overview: $baseUrl/raw/');

  for (final category in _categoryOrder) {
    final sectionDir = Directory(p.join(sourceDir.path, category));
    final sectionFile = File(p.join(sourceDir.path, '$category.md'));
    if (!sectionDir.existsSync() && !sectionFile.existsSync()) continue;

    final title =
        _categoryTitles[category] ??
        category[0].toUpperCase() + category.substring(1).replaceAll('_', ' ');
    buffer.writeln('- $title: $baseUrl/raw/$category/');
  }

  buffer
    ..writeln()
    ..writeln('## Per-topic raw pages')
    ..writeln();

  final topicFiles =
      sourceDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => p.relative(f.path, from: sourceDir.path))
          .where((relative) => relative != 'index.md')
          .toList()
        ..sort();

  for (final relative in topicFiles) {
    final normalized = relative.replaceAll(r'\', '/');
    final urlPath = _rawUrlPath(normalized);
    final title = _titleFromRawPath(relative);
    buffer.writeln('- $title: $baseUrl/raw/$urlPath');
  }

  final llmsFile = File(p.join(staticDir.path, 'llms.txt'));
  staticDir.createSync(recursive: true);
  llmsFile.writeAsStringSync(buffer.toString());

  print('Generated llms.txt with ${topicFiles.length} topic links.');
}

/// Maps a normalized documentation path to the raw URL path.
///
/// * `index.md` -> `` (root)
/// * `concurrency/_index.md` -> `concurrency/`
/// * `concurrency/lock.md` -> `concurrency/lock/`
String _rawUrlPath(String normalizedPath) {
  if (normalizedPath == 'index.md') return '';
  if (normalizedPath.endsWith('/_index.md')) {
    return normalizedPath.replaceAll('/_index.md', '/');
  }
  return normalizedPath.replaceAll('.md', '/');
}

/// Returns a human-readable title from a raw documentation path such as
/// `concurrency/lock.md`.
String _titleFromRawPath(String relativePath) {
  final normalized = relativePath.replaceAll(r'\', '/');
  final withoutIndex = normalized == '_index.md'
      ? 'Overview'
      : normalized.replaceAll('_index.md', '').replaceAll('.md', '');
  final segments = withoutIndex
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(
        (s) => s[0].toUpperCase() + s.substring(1).replaceAll('_', ' '),
      )
      .toList();
  return segments.isEmpty ? 'Overview' : segments.join(' / ');
}

String _toRfc3339(DateTime dt) {
  final offset = dt.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final year = dt.year;
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$year-$month-${day}T$hour:$minute:$second$sign$hours:$minutes';
}

String? _extractTitle(String text) {
  final match = RegExp(r'^#\s+(.+)\s*$', multiLine: true).firstMatch(text);
  return match?.group(1)?.trim();
}

String _extractDescription(String text) {
  final match = RegExp(
    r'## What it is\s*\n\s*([^\n]+)',
  ).firstMatch(text.replaceAll('\r\n', '\n'));
  final raw = match?.group(1)?.trim() ?? '';
  // The replacement must be a literal backslash + quote; a raw string is
  // rejected by the same lint in the opposite direction.
  // ignore: use_raw_strings
  return raw.replaceAll('"', '\\"').replaceAll('\n', ' ');
}

String _titleFromPath(String filePath) {
  final dir = p.dirname(filePath);
  final base = p.basenameWithoutExtension(filePath);
  if (base != '_index') {
    return base[0].toUpperCase() + base.substring(1).replaceAll('_', ' ');
  }
  final parent = p.basename(dir);
  return parent[0].toUpperCase() + parent.substring(1).replaceAll('_', ' ');
}

const _categoryOrder = [
  'core',
  'concurrency',
  'control_flow',
  'error_handling',
  'observability',
  'orchestration',
  'performance',
  'reliability',
  'scheduling',
  'state',
  'timing',
  'transformation',
  'validation',
];

const _categoryIcons = {
  'core': 'token',
  'concurrency': 'sync_alt',
  'control_flow': 'account_tree',
  'error_handling': 'error_outline',
  'observability': 'monitoring',
  'orchestration': 'hub',
  'performance': 'speed',
  'reliability': 'replay',
  'scheduling': 'event_note',
  'state': 'storage',
  'timing': 'timer',
  'transformation': 'transform',
  'validation': 'verified',
};

const _categoryTitles = {
  'core': 'Core',
  'concurrency': 'Concurrency',
  'control_flow': 'Control Flow',
  'error_handling': 'Error Handling',
  'observability': 'Observability',
  'orchestration': 'Orchestration',
  'performance': 'Performance',
  'reliability': 'Reliability',
  'scheduling': 'Scheduling',
  'state': 'State',
  'timing': 'Timing',
  'transformation': 'Transformation',
  'validation': 'Validation',
};

String _iconForPath(String filePath, String parent) {
  if (p.basename(filePath) != '_index.md') return 'article';
  if (parent == 'docs') return 'home';
  return _categoryIcons[parent] ?? 'folder';
}

int _weightFromPath(String filePath, String parent) {
  final base = p.basename(filePath);
  if (base == '_index.md') {
    if (parent == 'docs') return 100;
    final idx = _categoryOrder.indexOf(parent);
    if (idx != -1) return (idx + 2) * 100;
  }
  final depth = filePath.split('/').length - 3;
  return (depth + 2) * 100;
}
