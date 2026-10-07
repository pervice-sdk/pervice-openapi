import 'package:analyzer/dart/ast/token.dart';
import 'package:collection/collection.dart';
import 'package:recase/recase.dart';

import '../config/config.dart';
import 'generator.dart';

/// Name, configuration, values and output buffer for generating one enum.
typedef EnumGeneratorContext = ({
  String name,
  String path,
  Config config,
  List<dynamic> values,
  StringBuffer buffer,
});

typedef _Field = ({
  String key,
  Object value,
});

/// Generates one Dart enum from one OpenAPI schema.
final class EnumGenerator extends Generator<EnumGeneratorContext> {
  const new();

  @override
  bool get hasCodec => true;

  /// Member names reserved by Dart enums and the generated key and codec.
  static const reserved = {'key', 'codec', 'index', 'values'};

  @override
  void generate(EnumGeneratorContext context) {
    // 1. Validate enum values.
    final buffer = context.buffer;
    final values = context.values;

    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'An enum must contain at least one value.');
    }

    // 2. Determine the enum name and key type.
    final enumName = typeName(
      context.name,
      prefix: context.config.enumeration.prefix,
      suffix: context.config.enumeration.suffix,
    );

    final keyType = _keyType(values);

    // 3. Convert values to Dart identifiers.
    final fields = values.mapIndexed<_Field>((index, value) {
      return (
        key: memberName(_key(index, value), context.config, reserved: reserved),
        value: value,
      );
    });

    // 4. Generate the enum declaration and cases.
    buffer.writeln("import 'package:pervice_openapi/pervice_openapi.dart';\n");
    buffer.writeln('/// Enum representing the allowed values of $enumName.');
    buffer.writeln('enum $enumName {');

    for (final field in fields) {
      final isLast = field == fields.last;
      final suffix = isLast ? ';' : ',';

      buffer.writeln('\t${field.key}(${literal(field.value)})$suffix');
    }

    // 5. Generate the constructor, key field and codec.
    buffer.write(
      '\n'
      '\tconst new(this.key);\n'
      '\n'
      '\t/// String key corresponding to the [$enumName].\n'
      '\tfinal $keyType key;\n'
      '\n'
      '\t/// OpenAPI codec for encoding and decoding [$enumName].\n'
      '\tstatic const codec = _Codec();\n'
      '}\n'
      '\n',
    );

    // 6. Generate the codec and decoding branches.
    buffer.writeln('/// OpenAPI codec converting between the enum and its string key.');
    buffer.writeln('class _Codec extends OpenApiCodec<$enumName, $keyType> {');
    buffer.writeln('\tconst new();\n');
    buffer.writeln('\t@override');
    buffer.writeln('\t$enumName decode($keyType key) => switch (key) {');

    for (final field in fields) {
      buffer.writeln("\t\t${literal(field.value)} => .${field.key},");
    }

    buffer.writeln("\t\t_ => throw FormatException('Invalid $enumName key: \$key'),");
    buffer.writeln('\t};');

    // 7. Generate the encoding method.
    buffer.writeln();
    buffer.writeln('\t@override');
    buffer.writeln('\t$keyType encode($enumName value) => value.key;');
    buffer.writeln('}');
  }

  /// Converts an enum value to a Dart identifier or an indexed fallback.
  String _key(int index, Object value) {
    final fallback = 'case${index + 1}';
    final text = value.toString();

    if (!RegExp(r'^[\x00-\x7F]+$').hasMatch(text)) {
      return fallback;
    }

    final name = text.camelCase;
    final isValid = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name);
    final isKeyword = Keyword.keywords.containsKey(name);

    return !isValid || isKeyword ? fallback : name;
  }

  /// Determines the shared key type and rejects null or mixed-type values.
  String _keyType(List<dynamic> values) {
    if (values.any((value) => value == null)) {
      throw UnsupportedError(
        'Enum values containing null are not supported. Use a nullable field instead.',
      );
    }

    if (values.every((value) => value is String)) return 'String';
    if (values.every((value) => value is bool)) return 'bool';
    if (values.every((value) => value is int)) return 'int';
    if (values.every((value) => value is num)) return 'num';

    throw UnsupportedError(
      'Enum "$values" must contain exactly one supported type: String, int, num, or bool.',
    );
  }
}
