# Publishing `package:osqp`

Releases are published automatically via GitHub Actions when a version tag (`v*`) is pushed.

## Release Steps

### 1. Prepare the Release Commit

1. In `pubspec.yaml`, remove the `-wip` suffix from `version:` (e.g., `1.1.0-wip` -> `1.1.0`).
2. In `CHANGELOG.md`, update the top heading to match the release version (e.g., `## 1.1.0`).
3. Commit and push the changes to `main`.

### 2. Tag and Push to Trigger Publishing

Create and push a git tag matching `v<version>`:

```sh
git tag v1.1.0
git push origin v1.1.0
```

Pushing the tag triggers `.github/workflows/ci.yaml`, which automatically:
1. Runs formatting, static analysis, and `ffigen` binding verification (`analyze` job).
2. Builds and tests prebuilt native OSQP libraries across Linux, Android, macOS, iOS, and Windows (`build` job).
3. Collects all prebuilt binaries into `prebuilt/`, runs `dart test` against the bundled binaries, verifies the package with `dart pub publish --dry-run`, and publishes to pub.dev with `dart pub publish --force` (`publish` job).

