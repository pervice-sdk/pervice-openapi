/// Strategy used to name generated services.
enum ServiceNaming {
  /// Uses the operation ID, falling back to the HTTP method and path.
  operationId,

  /// Always derives the name from the HTTP method and path.
  path,
}

/// Output and naming options for one generator category.
final class ConfigGenerator {
  const ConfigGenerator({
    required this.path,
    required this.prefix,
    required this.suffix,
    this.naming = .operationId,
    this.clean = true,
  });

  /// Output subdirectory, null uses the default directory for the generator.
  final String? path;

  /// Prefix added to generated type names, but not filenames.
  final String prefix;

  /// Suffix added to generated type names, but not filenames.
  final String suffix;

  /// Service naming strategy; ignored by enum and model generators.
  final ServiceNaming naming;

  /// Whether to delete the output folder existing contents before generation.
  final bool clean;

  /// Decodes a YAML generator section, applying defaults for omitted options.
  static ConfigGenerator decode(dynamic obj) {
    return .new(
      path: obj?['path'],
      prefix: obj?['prefix'] ?? '',
      suffix: obj?['suffix'] ?? '',
      naming: .values.byName(obj?['naming'] ?? 'operationId'),
      clean: obj?['clean'] ?? true,
    );
  }
}
