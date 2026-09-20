// Copyright 2026 The Dart package:osqp authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
        'CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS': 'ON',
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
