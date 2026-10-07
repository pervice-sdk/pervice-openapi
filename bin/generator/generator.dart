import 'dart:convert';

import 'package:analyzer/dart/ast/token.dart';
import 'package:openapi_spec_plus/v31.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import '../config/config.dart';

/// Base class for API generators and shared source-generation helpers.
abstract class Generator<T> {
  const new();

  static const objectReserved = {
    'hashCode',
    'runtimeType',
    'toString',
    'noSuchMethod',
  };

  /// Whether the generated type provides an OpenAPI codec.
  bool get hasCodec => false;

  /// Writes Dart source to the buffer in [context].
  void generate(T context);

  /// Adds the configured affixes only when a member name conflicts.
  String memberName(String name, Config config, {Set<String> reserved = const {}}) {
    final $1 = reserved.contains(name);
    final $2 = objectReserved.contains(name);
    final $3 = Keyword.keywords[name]?.isReservedWord == true;

    final conflict = $1 || $2 || $3;
    return conflict ? '${config.conflictPrefix}$name${config.conflictSuffix}' : name;
  }

  /// Resolves a schema to a Dart type, including references and collections.
  String schemaType(Schema schema, Config config, Map<String, Schema> schemas) {
    if (schema.allOf case [final item]) return schemaType(item, config, schemas);
    if (schema.ref case final ref?) {
      final name = ref.split('/').last.replaceAll('~1', '/').replaceAll('~0', '~');
      final options = schemas[name]!.enumValues != null ? config.enumeration : config.model;
      return typeName(
        name,
        prefix: options.prefix,
        suffix: options.suffix,
      );
    }

    final type = schema.type;
    final kind = type is List ? type.firstWhere((value) => value != 'null') : type;
    return switch (kind) {
      'string' when schema.format == 'date' || schema.format == 'date-time' => 'DateTime',
      'string' => 'String',
      'integer' => 'int',
      'number' => 'num',
      'boolean' => 'bool',
      'array' => 'List<${schemaType(schema.items!, config, schemas)}>',
      'object' when schema.additionalProperties is Schema =>
        'Map<String, ${schemaType(schema.additionalProperties as Schema, config, schemas)}>',
      'object' => 'Map<String, dynamic>',
      _ => 'dynamic',
    };
  }

  /// Builds a PascalCase type name with the configured prefix and suffix.
  String typeName(
    String value, {
    required String prefix,
    required String suffix,
  }) {
    return '$prefix$value$suffix'.pascalCase;
  }

  /// Converts [value] to a Dart literal with escaped string interpolation.
  String literal(Object? value) {
    final isPrimitiveOrNull = value == null || value is num || value is bool;
    final encoded = jsonEncode(isPrimitiveOrNull ? value : value);
    return encoded.replaceAll(r'$', r'\$').replaceAll('"', '\'');
  }

  /// Returns the relative import path to the shared barrel library.
  String relativeBarrelPath(String path, String barrelName) {
    return p.posix.relative(barrelName, from: path.replaceAll('\\', '/'));
  }
}
