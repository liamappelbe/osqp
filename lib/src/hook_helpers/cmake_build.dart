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

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_cmake/native_toolchain_cmake.dart';

/// Builds the OSQP C library using CMake.
Future<void> runBuild(BuildInput input, BuildOutputBuilder output) async {
  final packageName = input.packageName;
  final targetOS = input.config.code.targetOS;
  final targetArchitecture = input.config.code.targetArchitecture;
  final iOSSdk = targetOS == OS.iOS
      ? input.config.code.iOS.targetSdk.type
      : null;
  final targetName = createTargetName(
    targetOS.name,
    targetArchitecture.name,
    iOSSdk,
  );
  final sourceDir = input.packageRoot.resolve('third_party/osqp/');
  final buildDir = input.outputDirectory.resolve('$targetName/');
  final installDir = buildDir.resolve('install/');

  final logger = Logger.detached('')
    ..level = Level.ALL
    ..onRecord.listen((record) => print(record.message));

  final builder = CMakeBuilder.create(
    name: packageName,
    sourceDir: sourceDir,
    outDir: buildDir,
    defines: {
      'BUILD_SHARED_LIBS': 'ON',
      'OSQP_BUILD_SHARED_LIB': 'ON',
      'OSQP_BUILD_STATIC_LIB': 'OFF',
      'OSQP_ENABLE_INTERRUPT': 'OFF',
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
}

/// Creates a target name based on the OS, architecture, and iOS SDK.
///
/// For example, `osqp_ios_arm64_iphonesimulator` or `osqp_windows_x64`.
String createTargetName(String osString, String architecture, String? iOSSdk) {
  var targetName = 'osqp_${osString}_$architecture';
  if (iOSSdk != null) {
    targetName += '_$iOSSdk';
  }
  return targetName;
}

/// Returns the dynamic library file name for the given target.
String targetFileName(
  OS targetOS,
  Architecture targetArchitecture,
  IOSSdk? iOSSdk,
) => targetOS.dylibFileName(
  createTargetName(targetOS.name, targetArchitecture.name, iOSSdk?.type),
);
