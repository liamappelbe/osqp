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

import 'package:ffigen/ffigen.dart';

const String licenseHeader = '''
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
''';

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final srcDir = packageRoot.resolve('src/');
  final osqpPublicInclude = packageRoot.resolve(
    'third_party/osqp/include/public/',
  );
  final header = srcDir.resolve('osqp.h');
  final output = packageRoot.resolve('lib/src/osqp_bindings.g.dart');

  final generator = FfiGenerator(
    input: Input(
      entryPoints: [header],
      include: (headerUri) =>
          headerUri.path.contains('third_party/osqp/include/public'),
      compilerOptions: [
        '-DFFIGEN',
        '-I${File.fromUri(srcDir).path}',
        '-I${File.fromUri(osqpPublicInclude).path}',
      ],
    ),
    output: Output(
      dart: DartOutput(path: output),
      style: const NativeExternalBindings(assetId: 'package:osqp/osqp.dart'),
      preamble: licenseHeader,
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = true,
        struct: (node) => node.isIncluded = true,
        union: (node) => node.isIncluded = true,
        enumClass: (node) {
          node.isIncluded = true;
          node.silenceWarning = true;
        },
        macroConstant: (node) {
          if (!node.originalName.startsWith('_')) {
            node.isIncluded = true;
          }
        },
        global: (node) => node.isIncluded = true,
        unnamedEnumConstant: (node) => node.isIncluded = true,
        typealias: (node) => node.isIncluded = TypealiasInclude.always,
      ),
    ],
  );

  await generator.generate();
}
