import 'dart:io';

import 'package:path/path.dart' as p;

/// Validates one cleanup target and returns its absolute directory.
Directory validateOutputDirectory(
  String root,
  String path, {
  Iterable<String> outputPaths = const [],
}) {
  final rootPath = p.normalize(p.absolute(root));
  final target = p.normalize(p.absolute(p.join(rootPath, path)));

  if (!p.isWithin(rootPath, target)) {
    throw ArgumentError('Clean output must be a subdirectory of $rootPath: $target');
  }

  final others = outputPaths.map((other) => p.normalize(p.absolute(p.join(rootPath, other))));
  if (others.any((other) => other != target && p.isWithin(target, other))) {
    throw ArgumentError('Clean output must not contain another output directory: $target');
  }

  if (FileSystemEntity.typeSync(target, followLinks: false) == FileSystemEntityType.link) {
    throw ArgumentError('Clean output must not be a symbolic link: $target');
  }

  final directory = Directory(target);
  if (directory.existsSync() &&
      !p.isWithin(Directory(rootPath).resolveSymbolicLinksSync(), directory.resolveSymbolicLinksSync())) {
    throw ArgumentError('Clean output resolves outside its root: $target');
  }

  return directory;
}

/// Removes one validated output directory before generating files.
Future<void> cleanOutputDirectory(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}
