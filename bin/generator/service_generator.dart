import 'package:collection/collection.dart';
import 'package:openapi_spec_plus/v31.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import '../config/config.dart';
import 'generator.dart';

/// Operation metadata and output state for generating one service.
typedef ServiceGeneratorContext = ({
  String name,
  Config config,
  Schema schema,
  Map<String, Schema> schemas,
  StringBuffer buffer,
  String path,
  String barrelName,
  Operation operation,
  String method,
  String url,
  List<Parameter> parameters,
});

typedef _Field = ({
  String key,
  String name,
  String type,
  bool required,
  String location,
});

/// Generates one service from one OpenAPI path operation.
final class ServiceGenerator extends Generator<ServiceGeneratorContext> {
  const new();

  /// Member names reserved by OpenApiService and its inherited service API.
  static const reserved = {
    'decode',
    'fetchData',
    'status',
    'isLoading',
    'isRefreshing',
    'isError',
    'canRethrow',
    'canDebugPrint',
    'data',
    'error',
    'maybeData',
    'maybeError',
    'fail',
    'done',
    'load',
    'refresh',
    'request',
    'requestOrNull',
    'notifyUpdated',
    'dispose',
    'addListener',
    'removeListener',
    'notifyListeners',
    'hasListeners',
  };

  @override
  void generate(ServiceGeneratorContext context) {
    // 1. Resolve the service, response and request fields.
    final buffer = context.buffer;
    final options = context.config.service;

    final serviceName = typeName(
      context.name,
      prefix: options.prefix,
      suffix: options.suffix,
    );

    final responseType = context.schema.type == 'null'
        ? 'void'
        : schemaType(context.schema, context.config, context.schemas);

    final apiName = p.basenameWithoutExtension(context.barrelName).pascalCase;
    final request = context.operation.requestBody;
    final media = request?.content.entries.first;

    // Apply conflict affixes to field names that collide with service members.
    String fieldName(String name) => memberName(
      name,
      context.config,
      reserved: reserved,
    );

    final fields = <_Field>[
      // Convert path, query, header and cookie parameters into fields.
      for (final parameter in context.parameters)
        (
          key: parameter.name!,
          name: fieldName(parameter.name!.camelCase),
          type: schemaType(parameter.schema!, context.config, context.schemas),
          required: parameter.location!.name == 'path' || parameter.required == true,
          location: parameter.location!.name,
        ),

      // Add the request body as a single field when present.
      if (media != null)
        (
          key: 'request',
          name: fieldName('request'),
          type: schemaType(media.value.schema!, context.config, context.schemas),
          required: request!.$required == true,
          location: 'body',
        ),
    ];

    final groups = fields.groupListsBy((field) => field.location);

    // 2. Generate the constructor and fields.
    final arguments = fields.map((field) => '\t\t${field.required ? 'required ' : ''}this.${field.name},').join('\n');

    buffer.write(
      "import 'package:dio/dio.dart';\n"
      "import 'package:pervice_openapi/pervice_openapi.dart';\n\n"
      "import '${relativeBarrelPath(context.path, context.barrelName)}';\n"
      '\n'
      '/// Service implementation for the `${context.method.toUpperCase()} ${context.url}` API endpoint.\n'
      'final class $serviceName extends OpenApiService<$responseType> {',
    );

    final constructor = fields.isEmpty ? null : '{\n$arguments\n\t}';
    if (constructor != null) {
      buffer.writeln('\n\tnew($constructor);\n');
    }

    for (final field in fields) {
      buffer.writeln('\tfinal ${field.type}${field.required ? '' : '?'} ${field.name};');
    }

    // 3. Bind the client, HTTP method and encoded URL.
    var url = literal(context.url);
    for (final field in groups['path'] ?? <_Field>[]) {
      url = url.replaceAll('{${field.key}}', '\${${field.name}.encodeUri()}');
    }

    _getter(buffer, 'Dio', 'dio', '$apiName.dio');
    _getter(buffer, 'OpenApiMethod', 'method', '.${context.method}');
    _getter(buffer, 'String', 'url', url);

    // 4. Generate parameter maps and the request body.
    for (final location in ['query', 'header', 'cookie']) {
      final parameters = groups[location];
      if (parameters == null) continue;

      final entries = parameters.map((field) => '\t\t${literal(field.key)}: ${field.name}.encode(),').join('\n');
      final getter = switch (location) {
        'header' => 'headers',
        'cookie' => 'cookies',
        _ => 'query',
      };

      _getter(buffer, 'Map<String, dynamic>', getter, '{\n$entries\n\t}');
    }

    if (media != null) {
      _getter(buffer, 'String', 'contentType', literal(media.key));

      final body = groups['body']!.single;
      _getter(buffer, 'Object?', 'body', '${body.name}${body.required ? '' : '?'}.encode()');
    }

    // 5. Decode the successful response.
    if (responseType != 'void') {
      buffer.writeln('\n\t@override');
      buffer.writeln('\t$responseType decode(Object? obj) {');
      buffer.writeln('\t\treturn obj.decode<$responseType>()!;');
      buffer.writeln('\t}');
    }

    buffer.writeln('}');
  }

  /// Writes an overridden getter.
  void _getter(StringBuffer buffer, String type, String name, String value) {
    buffer.writeln('\n\t@override\n\t$type get \$$name => $value;');
  }
}
