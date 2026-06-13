import 'dart:io';
import 'package:path/path.dart' as p;

/// Prepares the funx markdown docs for Hugo + Lotus Docs.
///
/// 1. Copies docs/ into content/docs/ preserving the directory tree.
/// 2. Turns top-level category files (e.g. concurrency.md) into section
///    landing pages: concurrency/_index.md.
/// 3. Adds front matter to every page, including category-specific icons and
///    weights so the sidebar is ordered consistently.
void main() {
  final sourceDir = Directory('../docs');
  final targetDir = Directory('content/docs')..createSync(recursive: true);

  // Clean previous run.
  if (targetDir.existsSync()) targetDir.deleteSync(recursive: true);

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
        '''---
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

  print('Prepared ${files.length} content files.');
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

String _toRfc3339(DateTime dt) {
  final offset = dt.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T'
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}'
      '$sign$hours:$minutes';
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
