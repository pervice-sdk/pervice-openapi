import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import 'generator.dart';

/// Imports, exports, codec names and output buffer for one barrel library.
typedef BarrelGeneratorContext = ({
  String barrelName,
  List<String> exports,
  List<String> codecs,
  StringBuffer buffer,
});

/// Generates one barrel library with API configuration and codec registration.
final class BarrelGenerator extends Generator<BarrelGeneratorContext> {
  const new();

  @override
  void generate(BarrelGeneratorContext context) {
    final buffer = context.buffer;
    final className = p.basenameWithoutExtension(context.barrelName).pascalCase;

    // 1. Generate imports and exports.
    buffer.write(
      "import 'package:dio/dio.dart';\n"
      "import 'package:pervice_openapi/pervice_openapi.dart';\n\n"
      "import '${context.barrelName}';\n\n",
    );

    for (final path in context.exports) {
      buffer.writeln("export '$path';");
    }

    // 2. Generate the API configuration and codec list.
    buffer.write(
      '\n'
      '/// Generated API configuration and codec registration.\n'
      'abstract final class $className {\n'
      '\t/// Codecs registered by [setup].\n'
      '\tstatic const _codecs = <OpenApiCodec>[\n',
    );

    for (final name in context.codecs) {
      buffer.writeln('\t\t$name.codec,');
    }

    // 3. Generate the HTTP client and setup method.
    buffer.write(
      '\t];\n\n'
      '\t/// Dio instance configured by [setup].\n'
      '\tstatic Dio? _dio;\n\n'
      '\t/// HTTP client used by the generated services.\n'
      '\tstatic Dio get dio {\n'
      "\t\tassert(_dio != null, '$className.setup(dio) must be called before use.');\n"
      '\t\treturn _dio!;\n'
      '\t}\n\n'
      '\t/// Configures the HTTP client and registers the generated codecs.\n'
      '\tstatic void setup(Dio dio) {\n'
      '\t\tfor (final codec in _codecs) {\n'
      '\t\t\tcodec.register();\n'
      '\t\t}\n'
      '\n'
      '\t\t_dio = dio;\n'
      '\t}\n'
      '}\n',
    );
  }
}
