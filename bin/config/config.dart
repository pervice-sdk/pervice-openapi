import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config_generator.dart';
import 'config_spec.dart';

/// OpenAPI sources and options loaded from the project YAML configuration.
final class Config {
  const Config({
    required this.specs,
    required this.enumeration,
    required this.service,
    required this.model,
    required this.encodeMethodName,
    required this.decodeMethodName,
  });

  /// OpenAPI documents and their output roots.
  final List<ConfigSpec> specs;

  /// Options shared by generated enums.
  final ConfigGenerator enumeration;

  /// Options shared by generated services.
  final ConfigGenerator service;

  /// Options shared by generated models.
  final ConfigGenerator model;

  /// Name of the generated model codec encoding method.
  final String encodeMethodName;

  /// Name of the generated model codec decoding method.
  final String decodeMethodName;

  /// Loads `pervice_openapi.yaml` from the current working directory.
  static Config load() {
    // 1. Locate the configuration file.
    final yamlFile = File('pervice_openapi.yaml');
    if (!yamlFile.existsSync()) {
      throw Exception('pervice_openapi.yaml was not found.');
    }

    // 2. Parse and validate the YAML structure.
    final yamlText = yamlFile.readAsStringSync();
    final yaml = loadYaml(yamlText);
    if (yaml is! Map) {
      throw FormatException('pervice_openapi.yaml must contain a YAML mapping.');
    }

    final yamlSpecs = yaml['specs'] as YamlList?;
    if (yamlSpecs == null) {
      throw FormatException('"specs" must be a list of configurations.');
    }

    // 3. Decode source entries and generator options with defaults.
    return .new(
      specs: yamlSpecs.map(ConfigSpec.decode).toList(),
      enumeration: .decode(yaml['enum']),
      service: .decode(yaml['service']),
      model: .decode(yaml['model']),
      encodeMethodName: yaml['encode_method_name'] ?? 'encode',
      decodeMethodName: yaml['decode_method_name'] ?? 'decode',
    );
  }
}
