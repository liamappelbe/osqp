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

import 'dart:ffi';

import 'package:osqp/osqp.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });

    test('OSQP native library is loaded and returns version', () {
      final version = osqpVersion();
      expect(version, isNotEmpty);
      expect(version, startsWith('1.'));
    });

    test('OSQP settings and capabilities via generated bindings', () {
      final capabilities = osqp_capabilities();
      expect(capabilities, isNonZero);

      final settings = OSQPSettings_new();
      expect(settings.address, isNonZero);
      expect(settings.ref.verbose, equals(OSQP_VERBOSE));
      OSQPSettings_free(settings);
    });

    test('OSQP CSC matrix creation via generated bindings', () {
      final mat = OSQPCscMatrix_zeros(3, 3);
      expect(mat.address, isNonZero);
      expect(mat.ref.m, equals(3));
      expect(mat.ref.n, equals(3));
      OSQPCscMatrix_free(mat);
    });
  });
}
