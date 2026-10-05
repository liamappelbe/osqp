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
import 'package:osqp/src/hook_helpers/targets.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../hook/build.dart' as build_hook;
import '../tool/build.dart';

void main() {
  test('CI workflow builds exact supportedTargets', () {
    final ciYaml = loadYaml(
      File('.github/workflows/ci.yaml').readAsStringSync(),
    ) as YamlMap;
    final steps =
        ((ciYaml['jobs'] as YamlMap)['build'] as YamlMap)['steps'] as YamlList;
    const prefix = 'dart tool/build.dart ';
    final ciTargets = [
      for (final step in steps)
        if (step case {'run': final String run})
          for (final line in run.split('\n'))
            if (line.trim().startsWith(prefix))
              parseArguments(line.trim().substring(prefix.length).split(' ')),
    ];
    expect(ciTargets, equals(supportedTargets));
  });

  test('build hook runs CMake when local_build is true', () async {
    await testCodeBuildHook(
      mainMethod: build_hook.main,
      userDefines: PackageUserDefines(
        workspacePubspec: PackageUserDefinesSource(
          defines: {'local_build': true},
          basePath: Directory.current.uri,
        ),
      ),
      check: (input, output) {
        final targetName = createTargetName(
          OS.current.name,
          Architecture.current.name,
          null,
        );
        final cmakeCache = File.fromUri(
          input.outputDirectory.resolve('$targetName/CMakeCache.txt'),
        );
        expect(cmakeCache.existsSync(), isTrue);
        expect(output.assets.code, hasLength(1));
        expect(
          output.assets.code.single.file!.toFilePath(),
          startsWith(input.outputDirectory.toFilePath()),
        );
      },
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('build hook uses prebuilt asset without running CMake and pub publish includes it', () async {
    final fileName = targetFileName(OS.current, Architecture.current, null);
    final prebuiltExisted = File('prebuilt/$fileName').existsSync();
    final prebuiltFile = prebuiltExisted
        ? File('prebuilt/$fileName').absolute
        : await buildPrebuiltAsset(OS.current, Architecture.current, null);
    final packageRoot = prebuiltFile.parent.parent;
    final tempDir = await Directory.systemTemp.createTemp('osqp_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      if (!prebuiltExisted) {
        if (await prebuiltFile.exists()) {
          await prebuiltFile.delete();
        }
        final prebuiltDir = prebuiltFile.parent;
        if (await prebuiltDir.exists() && await prebuiltDir.list().isEmpty) {
          await prebuiltDir.delete();
        }
      }
    });

    await testCodeBuildHook(
      mainMethod: build_hook.main,
      check: (input, output) {
        final targetName = createTargetName(
          OS.current.name,
          Architecture.current.name,
          null,
        );
        final cmakeCache = File.fromUri(
          input.outputDirectory.resolve('$targetName/CMakeCache.txt'),
        );
        expect(cmakeCache.existsSync(), isFalse);
        final expectedUri = input.packageRoot.resolve('prebuilt/$fileName');
        expect(output.assets.code, hasLength(1));
        expect(output.assets.code.single.file, expectedUri);
        expect(output.dependencies, contains(expectedUri));
      },
    );

    await _copyDirectory(packageRoot, tempDir);

    final publishResult = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'publish',
      '--dry-run',
    ], workingDirectory: tempDir.path);
    expect(
      publishResult.exitCode,
      0,
      reason: '${publishResult.stdout}\n${publishResult.stderr}',
    );
    expect(publishResult.stdout as String, contains(fileName));
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (final entity in source.list(recursive: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (name == '.dart_tool' || name == 'build' || name == '.git') continue;
    if (entity is Directory) {
      final newDir = Directory.fromUri(destination.uri.resolve('$name/'));
      await newDir.create(recursive: true);
      await _copyDirectory(entity, newDir);
    } else if (entity is File) {
      await entity.copy(destination.uri.resolve(name).toFilePath());
    }
  }
}
