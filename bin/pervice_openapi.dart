import 'package:openapi_spec_plus/v31.dart' show PathItem;

import 'config/config.dart';
import 'generator/openapi_generator.dart';

import 'src/openapi_loader.dart';
import 'src/openapi_output.dart';
import 'extensions/openapi_extension.dart';
import 'extensions/path_item_extension.dart';
import 'extensions/schema_extension.dart';

void main(List<String> args) async {
  final config = Config.load();
  const generator = OpenApiGenerator();

  for (final spec in config.specs) {
    // Load the OpenAPI document and component schemas.
    final openApi = await OpenApiLoader().fromUrl(spec.url);
    final schemas = openApi.components?.schemas ?? {};

    // Validate and clean the configured output directories.
    final output = OpenApiOutput(spec.output);
    await output.prepare(config);

    // Generate and save each enum or model.
    for (final entry in schemas.entries) {
      if (entry.value.isEnum) {
        await output.write(
          generator.generateEnum(
            name: entry.key,
            schema: entry.value,
            config: config,
          ),
        );
      } else if (entry.value.isModel) {
        await output.write(
          generator.generateModel(
            name: entry.key,
            schema: entry.value,
            schemas: schemas,
            config: config,
            barrelName: output.barrelName,
          ),
        );
      }
    }

    // Generate and save a service for each operation.
    for (final entry in openApi.paths.entries) {
      final PathItem path = entry.value.ref == null ? entry.value : openApi.resolveRef(entry.value.ref!);

      for (final method in path.operations.entries) {
        await output.write(
          generator.generateService(
            openApi: openApi,
            path: path,
            operation: method.value,
            method: method.key,
            url: entry.key,
            config: config,
            barrelName: output.barrelName,
          ),
        );
      }
    }

    // Generate and save the barrel with exports and codec setup.
    await output.write(
      generator.generateBarrel(
        schemas: schemas,
        config: config,
        barrelName: output.barrelName,
        exports: output.exports,
      ),
      includeExport: false,
    );
  }
}
