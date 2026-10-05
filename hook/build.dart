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
import 'package:osqp/src/hook_helpers/cmake_build.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final localBuild = input.userDefines['local_build'] as bool? ?? false;
    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    final iOSSdk = targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null;
    final fileName = targetFileName(targetOS, targetArchitecture, iOSSdk);
    final assetUri = input.packageRoot.resolve('prebuilt/$fileName');
    final assetFile = File.fromUri(assetUri);

    if (localBuild || !assetFile.existsSync()) {
      print('osqp: Building from source with CMake (local_build=$localBuild)');
      await runBuild(input, output);
    } else {
      print('osqp: Using prebuilt asset ${assetUri.toFilePath()}');
      output.dependencies.add(assetUri);
      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          name: '${input.packageName}.dart',
          linkMode: DynamicLoadingBundled(),
          file: assetUri,
        ),
      );
    }
  });
}
