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
  final packageRoot = File.fromUri(Platform.script).parent;
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
