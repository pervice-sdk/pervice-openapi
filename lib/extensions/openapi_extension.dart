import 'package:pervice_openapi/pervice_openapi.dart';

/// Decodes named fields using registered OpenAPI codecs.
extension OpenApiMapExtension on Map<String, dynamic> {
  /// Decodes the field at [key] into [T], preserving null values.
  T? decode<T>(String key) => OpenApiCodec.decodeValue<T>(this[key]);
}

/// Converts values using OpenAPI codecs and URI encoding.
extension OpenApiValueExtension on Object? {
  /// Decodes this value into [T], preserving null values.
  T? decode<T>() => OpenApiCodec.decodeValue<T>(this);

  /// Encodes this value into its data representation.
  Object? encode() => OpenApiCodec.encodeValue(this);

  /// Encodes this value as a URI component for path parameters.
  String encodeUri() {
    return Uri.encodeComponent(encode().toString());
  }
}
