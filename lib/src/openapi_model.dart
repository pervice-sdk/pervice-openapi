import 'package:equatable/equatable.dart';

/// Base class for generated OpenAPI models, providing value based equality
/// and a readable string representation from their field names and values.
abstract class OpenApiModel extends Equatable {
  const new();

  /// The model field names and values used for equality
  /// and string representation.
  Map<String, Object?> get fields;

  @override
  String toString() {
    final entries = fields.entries.map((e) => '${e.key}: ${e.value}').join(', ');

    return '$runtimeType($entries)';
  }

  @override
  List<Object?> get props => fields.values.toList();
}
