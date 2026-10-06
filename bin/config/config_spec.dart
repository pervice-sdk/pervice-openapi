/// One OpenAPI source and its generated output root.
final class ConfigSpec {
  const ConfigSpec({
    required this.url,
    required this.output,
  });

  /// URL used to download the OpenAPI document.
  final String url;

  /// Root directory for generated files, relative to the working directory or absolute.
  final String output;

  /// Decodes a YAML `specs` entry containing `url` and `output`.
  static ConfigSpec decode(dynamic obj) {
    return .new(
      url: obj['url'],
      output: obj['output'],
    );
  }
}
