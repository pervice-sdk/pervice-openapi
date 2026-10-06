import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:openapi_spec_plus/v31.dart';

/// Downloads and parses OpenAPI JSON documents.
final class OpenApiLoader {
  /// HTTP client used to fetch documents.
  final dio = Dio();

  /// Loads an OpenAPI document from [url].
  Future<OpenAPI> fromUrl(String url) async {
    final response = await dio.get<String>(
      url,
      options: .new(responseType: .plain),
    );

    final json = jsonDecode(response.data!);
    return OpenAPI.fromJson(json);
  }
}
