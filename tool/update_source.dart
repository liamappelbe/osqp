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

const String osqpReleaseUrl =
    'https://github.com/osqp/osqp/archive/refs/tags/v1.0.0.zip';

Future<void> downloadFile(Uri uri, File destination) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(uri)).close();
    assert(response.statusCode == HttpStatus.ok);
    await response.pipe(destination.openWrite());
  } finally {
    client.close();
  }
}

Future<void> main(List<String> args) async {
  final packageRoot = File.fromUri(Platform.script).parent.parent;
  final thirdPartyDir = Directory.fromUri(
    packageRoot.uri.resolve('third_party/'),
  );
  final targetDir = Directory.fromUri(thirdPartyDir.uri.resolve('osqp/'));

  print('Updating OSQP source from: $osqpReleaseUrl');
  print('Target directory: ${targetDir.path}');

  if (!thirdPartyDir.existsSync()) {
    thirdPartyDir.createSync(recursive: true);
  }

  if (targetDir.existsSync()) {
    print('Deleting existing ${targetDir.path}...');
    targetDir.deleteSync(recursive: true);
  }

  final tempDir = Directory.systemTemp.createTempSync('osqp_download_');
  final zipFile = File.fromUri(tempDir.uri.resolve('osqp.zip'));

  try {
    print('Downloading $osqpReleaseUrl...');
    await downloadFile(Uri.parse(osqpReleaseUrl), zipFile);

    print('Extracting ${zipFile.path}...');
    final stagingDir = thirdPartyDir.createTempSync('.osqp_staging_');
    try {
      final result = await Process.run('unzip', [
        '-q',
        zipFile.path,
        '-d',
        stagingDir.path,
      ]);
      assert(result.exitCode == 0);

      final subdirs = stagingDir.listSync().whereType<Directory>().toList();
      subdirs.single.renameSync(targetDir.path);
    } finally {
      if (stagingDir.existsSync()) {
        stagingDir.deleteSync(recursive: true);
      }
    }

    print('OSQP source successfully updated at ${targetDir.path}.');
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
