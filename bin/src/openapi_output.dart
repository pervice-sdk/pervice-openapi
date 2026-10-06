import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../generator/openapi_generator.dart';
import 'output_cleaner.dart';

/// Prepares output directories and saves generated files for one specification.
final class OpenApiOutput {
  OpenApiOutput(this.root);

  final String root;
  final exports = <String>[];

  /// Barrel filename derived from the output root.
  String get barrelName => '${p.basename(p.normalize(root))}.dart';

  /// Validates all cleanup targets before removing any output directory.
  Future<void> prepare(Config config) async {
    final directories = {
      config.enumeration.path ?? 'enum': config.enumeration.clean,
      config.model.path ?? 'model': config.model.clean,
      config.service.path ?? 'service': config.service.clean,
    };

    final cleanup = [
      for (final entry in directories.entries)
        if (entry.value) validateOutputDirectory(root, entry.key, outputPaths: directories.keys),
    ];

    for (final directory in cleanup) {
      await cleanOutputDirectory(directory);
    }
  }

  /// Saves one generated file and records its export path.
  Future<void> write(GeneratedFile generated, {bool includeExport = true}) async {
    final directory = Directory(p.join(root, generated.path));
    await directory.create(recursive: true);

    final fileName = '${generated.name}.dart';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(generated.buffer.toString());

    if (includeExport) {
      exports.add(p.posix.join(generated.path.replaceAll('\\', '/'), fileName));
    }

    stdout.writeln('Generated ${file.path}');
  }
}
