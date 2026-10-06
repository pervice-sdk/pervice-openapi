import 'package:openapi_spec_plus/v31.dart';

extension PathItemExtension on PathItem {
  /// HTTP methods and operations defined on this path.
  Map<String, Operation> get operations {
    final methods = {
      'get': get,
      'post': post,
      'put': put,
      'patch': patch,
      'delete': delete,
      'head': head,
      'options': options,
      'trace': trace,
    };
    return {
      for (final entry in methods.entries) entry.key: ?entry.value,
    };
  }
}
