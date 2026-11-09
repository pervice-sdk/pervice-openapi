library;

export 'src/openapi_codec.dart';
export 'src/openapi_model.dart';
export 'src/openapi_service.dart';

export 'extensions/openapi_extension.dart';

// Re-export so generated models can use value equality without
// requiring consuming projects to add equatable as a direct dependency.
export 'package:equatable/equatable.dart' show Equatable;
