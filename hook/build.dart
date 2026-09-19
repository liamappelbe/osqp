import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_cmake/native_toolchain_cmake.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final packageName = input.packageName;
    final sourceDir = input.packageRoot.resolve('third_party/osqp/');
    final installDir = input.outputDirectory.resolve('install/');

    final logger = Logger('')
      ..level = Level.ALL
      ..onRecord.listen((record) => stderr.writeln(record.message));

    final builder = CMakeBuilder.create(
      name: packageName,
      sourceDir: sourceDir,
      defines: {
        'BUILD_SHARED_LIBS': 'ON',
        'OSQP_BUILD_SHARED_LIB': 'ON',
        'OSQP_BUILD_STATIC_LIB': 'OFF',
        'CMAKE_INSTALL_PREFIX': installDir.toFilePath(),
      },
      targets: ['install'],
      logger: logger,
    );

    await builder.run(input: input, output: output, logger: logger);

    await output.findAndAddCodeAssets(
      input,
      names: {r'^(lib)?osqp\.(dll|so|dylib)$': '$packageName.dart'},
      outDir: installDir,
      logger: logger,
      regExp: true,
    );
  });
}
