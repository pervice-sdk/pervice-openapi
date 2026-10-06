/// Converts between a Dart value of type [T] and its data representation [R].
abstract class OpenApiCodec<T, R> {
  const new();

  /// Converts data into a typed Dart value.
  T decode(R value);

  /// Converts a typed Dart value into data.
  R encode(T value);

  /// Registers this codec and its list and map variants.
  void register() {
    _codecs[T] = this;
    _codecs.addAll(_collectionCodecs<T>(this));
  }

  /// Stores registered codecs, including built-in collection codecs.
  static final _codecs = <Type, OpenApiCodec>{
    ..._collectionCodecs(const _ValueCodec<String>()),
    ..._collectionCodecs(const _ValueCodec<int>()),
    ..._collectionCodecs(const _ValueCodec<double>()),
    ..._collectionCodecs(const _ValueCodec<num>()),
    ..._collectionCodecs(const _ValueCodec<bool>()),
    ..._collectionCodecs(const _ValueCodec<DateTime>()),
  };

  /// Creates list and map codecs from an element codec.
  static Map<Type, OpenApiCodec> _collectionCodecs<T>(OpenApiCodec<T, dynamic> codec) => {
    List<T>: OpenApiListCodec<T>(codec),
    Map<String, T>: OpenApiMapCodec<T>(codec),
  };

  /// Decodes [value] with the codec registered for [T], when one exists.
  static T? decodeValue<T>(Object? value) {
    // Handle null and date strings.
    if (value == null) return null;
    if (T == DateTime && value is String) return DateTime.parse(value) as T;

    // Decode with the target codec or cast the value directly.
    final codec = _codecs[T];
    return codec == null ? value as T : codec.decode(value) as T;
  }

  /// Encodes [value] with its registered codec, when one exists.
  static Object? encodeValue(Object? value) {
    // Handle null and convert dates to ISO 8601 strings.
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();

    // Encode collection entries recursively.
    if (value is List) return [for (final item in value) encodeValue(item)];
    if (value is Map) {
      return {
        for (final entry in value.entries) entry.key: encodeValue(entry.value),
      };
    }

    // Encode with the runtime codec or return the value unchanged.
    final codec = _codecs[value.runtimeType];
    return codec == null ? value : codec.encode(value);
  }
}

/// Converts primitive and date entries into typed collection elements.
class _ValueCodec<T> extends OpenApiCodec<T, dynamic> {
  const _ValueCodec();

  @override
  T decode(dynamic value) {
    if (T == DateTime && value is String) {
      return DateTime.parse(value) as T;
    }

    return value as T;
  }

  @override
  dynamic encode(T value) => OpenApiCodec.encodeValue(value);
}

/// Converts list elements using a shared element codec.
class OpenApiListCodec<T> extends OpenApiCodec<List<T>, List<dynamic>> {
  const OpenApiListCodec(this.parent);

  /// Codec used to convert each element.
  final OpenApiCodec<T, dynamic> parent;

  @override
  List<T> decode(List<dynamic> value) {
    return value.map(parent.decode).toList();
  }

  @override
  List<dynamic> encode(List<T> value) {
    return value.map(parent.encode).toList();
  }
}

/// Converts map values while preserving string keys.
class OpenApiMapCodec<T> extends OpenApiCodec<Map<String, T>, Map<String, dynamic>> {
  const OpenApiMapCodec(this.parent);

  /// Codec used to convert each value.
  final OpenApiCodec<T, dynamic> parent;

  @override
  Map<String, T> decode(Map<String, dynamic> value) {
    return {
      for (final entry in value.entries) entry.key: parent.decode(entry.value),
    };
  }

  @override
  Map<String, dynamic> encode(Map<String, T> value) {
    return {
      for (final entry in value.entries) entry.key: parent.encode(entry.value),
    };
  }
}
