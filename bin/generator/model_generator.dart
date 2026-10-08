import 'package:openapi_spec_plus/v31.dart';
import 'package:recase/recase.dart';

import '../config/config.dart';
import '../extensions/schema_extension.dart';
import 'generator.dart';

/// Schema, configuration and output state for generating one model.
typedef ModelGeneratorContext = ({
  String name,
  Config config,
  Schema schema,
  Map<String, Schema> schemas,
  StringBuffer buffer,
  String path,
  String barrelName,
});

typedef _Field = ({
  String jsonKey,
  String name,
  String type,
  bool nullable,
});

/// Generates one Dart model from one OpenAPI object schema.
final class ModelGenerator extends Generator<ModelGeneratorContext> {
  const new();

  @override
  bool get hasCodec => true;

  /// Member name reserved by the generated model codec.
  static const reserved = {'codec'};

  @override
  void generate(ModelGeneratorContext context) {
    // 1. Determine the model name.
    final buffer = context.buffer;
    final modelName = typeName(
      context.name,
      prefix: context.config.model.prefix,
      suffix: context.config.model.suffix,
    );

    // 2. Resolve field names, types and nullability.
    final required = context.schema.$required ?? const <String>[];
    final fields = (context.schema.properties?.entries ?? [])
        .map<_Field>(
          (entry) => (
            jsonKey: entry.key,
            name: memberName(entry.key.camelCase, context.config, reserved: reserved),
            type: schemaType(entry.value, context.config, context.schemas),
            nullable: !required.contains(entry.key) || entry.value.isNullable,
          ),
        )
        .toList();

    // 3. Generate imports and the model constructor.
    final barrelImport = relativeBarrelPath(context.path, context.barrelName);

    buffer.write(
      '// ignore_for_file: unused_import\n'
      'import \'package:pervice_openapi/pervice_openapi.dart\';\n'
      '\n'
      'import \'$barrelImport\';\n'
      '\n'
      '/// Model representing the $modelName schema.\n'
      'final class $modelName {\n',
    );

    buffer.write('\tconst new({\n');

    for (final field in fields) {
      buffer.write(
        field.nullable ? '\t\tthis.${field.name},\n' : '\t\trequired this.${field.name},\n',
      );
    }

    buffer.writeln('\t});\n');

    // 4. Generate fields and the codec constant.
    for (final field in fields) {
      buffer.writeln('\tfinal ${field.type}${field.nullable ? '?' : ''} ${field.name};');
    }

    // A comma-separated list of 'fieldName: value' pairs for toString().
    final toStringFields = fields.map((field) => '${field.name}: \$${field.name}');

    buffer.write(
      '\n'
      '\t/// OpenAPI codec for encoding and decoding [$modelName].\n'
      '\tstatic const codec = _Codec();\n'
      '\n'
      '\t@override\n'
      "\tString toString() => '$modelName(${toStringFields.join(', ')})';\n"
      '}\n'
      '\n',
    );

    // 5. Generate the codec and decoding method.
    buffer.writeln('/// OpenAPI codec converting between [$modelName] and a JSON object.');
    buffer.writeln('class _Codec extends OpenApiCodec<$modelName, Map<String, dynamic>> {');
    buffer.writeln('\tconst new();');
    buffer.writeln();
    buffer.writeln('\t@override');
    buffer.writeln('\t$modelName ${context.config.decodeMethodName}(Map<String, dynamic> obj) => .new(');

    for (final field in fields) {
      buffer.writeln(
        "\t\t${field.name}: obj.decode<${field.type}>('${field.jsonKey}')${field.nullable ? '' : '!'},",
      );
    }

    buffer.writeln('\t);');
    buffer.writeln();
    buffer.writeln('\t@override');

    // 6. Generate the encoding method.
    buffer.writeln('\tMap<String, dynamic> ${context.config.encodeMethodName}($modelName value) => {');

    for (final field in fields) {
      buffer.writeln(
        "\t\t'${field.jsonKey}': value.${field.name}${field.nullable ? '?' : ''}.encode(),",
      );
    }

    buffer.writeln('\t};');
    buffer.writeln('}');
  }
}
