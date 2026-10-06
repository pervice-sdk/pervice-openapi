import 'package:openapi_spec_plus/v31.dart';

extension SchemaExtension on Schema {
  /// Whether the schema defines enum values.
  bool get isEnum => enumValues != null;

  /// Whether the schema defines an object model or an allOf composition.
  bool get isModel => properties != null || type == 'object' || allOf != null;

  /// Whether the schema explicitly allows null values.
  bool get isNullable => nullable == true || (type is List && (type as List).contains('null'));
}
