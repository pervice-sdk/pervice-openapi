import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pervice/pervice.dart';

/// HTTP methods supported by OpenAPI services.
enum OpenApiMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD'),
  options('OPTIONS'),
  trace('TRACE');

  const new(this.key);

  /// Uppercase HTTP method used in requests.
  final String key;
}

/// Sends an OpenAPI request and decodes its response into [T].
abstract class OpenApiService<T> extends Service<T> {
  /// Configured HTTP client used to send requests.
  Dio get $dio;

  /// HTTP method for this endpoint.
  OpenApiMethod get $method;

  /// Endpoint path, including encoded path parameters.
  String get $url;

  /// Encoded request body, when present.
  Object? get $body => null;

  /// Query parameters with null entries omitted before sending.
  Map<String, dynamic>? get $query => null;

  /// Request headers with null entries omitted before sending.
  Map<String, dynamic>? get $headers => null;

  /// Cookies combined into a request header after removing null entries.
  Map<String, dynamic>? get $cookies => null;

  /// Request media type, or null to use the client default.
  String? get $contentType => null;

  /// Converts response data into [T].
  T decode(Object? obj) {
    throw UnimplementedError();
  }

  @override
  Future<T> fetchData() async {
    // Prepare the request body and remove null parameter values.
    final body = $body;
    final cookies = {...?$cookies}..removeWhere((key, value) => value == null);
    final headers = {...?$headers}..removeWhere((key, value) => value == null);
    final query = {...?$query}..removeWhere((key, value) => value == null);

    final response = await $dio.request(
      $url,
      // Converting multipart bodies into form data.
      data: $contentType == 'multipart/form-data' && body is Map<String, dynamic> ? FormData.fromMap(body) : body,
      queryParameters: query,
      options: .new(
        method: $method.key,
        contentType: $contentType,
        responseType: .plain,
        headers: {
          // Include the configured headers.
          ...headers,

          // Encode cookies into a single Cookie header.
          if (cookies.isNotEmpty)
            'Cookie': cookies.entries
                .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
                .join('; '),
        },
      ),
    );

    // Skip decoding when the response has no data.
    final data = response.data;
    if (data == null || data == '') return null as T;

    // Parse JSON responses before applying the service decoder.
    final isJson = response.headers.value(Headers.contentTypeHeader)?.contains('json') == true;
    return decode(data is String && data.isNotEmpty && isJson ? jsonDecode(data) : data);
  }
}
