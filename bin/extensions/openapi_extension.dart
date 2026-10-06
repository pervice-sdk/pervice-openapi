import 'package:collection/collection.dart';
import 'package:openapi_spec_plus/v31.dart';

extension OpenApiExtension on OpenAPI {
  /// Looks up a local component reference by its category and name.
  T resolveRef<T extends Object>(String ref) {
    final segments = ref.split('/');
    final category = segments[2];
    final name = segments.last.replaceAll('~1', '/').replaceAll('~0', '~');

    final Map<String, Object>? definitions = switch (category) {
      'schemas' => components!.schemas,
      'responses' => components!.responses,
      'parameters' => components!.parameters,
      'requestBodies' => components!.requestBodies,
      'headers' => components!.headers,
      'securitySchemes' => components!.securitySchemes,
      'examples' => components!.examples,
      'links' => components!.links,
      'callbacks' => components!.callbacks,
      'pathItems' => components!.pathItems,
      _ => throw UnsupportedError('Unsupported component category: $category'),
    };

    return definitions![name] as T;
  }

  /// Resolves a successful response schema, preferring status 200.
  Schema responseSchema(Operation operation) {
    var response =
        operation.responses['200'] ??
        operation.responses.entries.firstWhereOrNull((entry) => entry.key.startsWith('2'))?.value;

    if (response?.ref case final ref?) {
      response = resolveRef(ref);
    }

    return response?.content?.values.firstOrNull?.schema ?? const Schema(type: 'null');
  }

  /// Resolves parameter references and applies operation-level overrides.
  List<Parameter> parameters(PathItem path, Operation operation) {
    final result = <(String?, String?), Parameter>{};

    for (var parameter in [...?path.parameters, ...operation.parameters]) {
      if (parameter.ref case final ref?) {
        parameter = resolveRef(ref);
      }
      result[(parameter.name, parameter.location?.name)] = parameter;
    }

    return result.values.toList();
  }
}
