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

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:osqp/osqp.dart';
import 'package:test/test.dart';

void main() {
  group('Utilities', () {
    test('top-level osqpVersion and osqpCapabilities', () {
      expect(osqpVersion, isNotEmpty);
      expect(osqpVersion, startsWith('1.'));
      expect(osqpCapabilities, isNonZero);
      expect(
        osqpCapabilities &
            osqp_capabilities_type.OSQP_CAPABILITY_DIRECT_SOLVER.value,
        isNonZero,
      );
    });

    test(
      'OsqpInfo.statusString converts null-terminated char array to string',
      () {
        using((arena) {
          final info = arena<OSQPInfo>();
          const text = 'test_status';
          for (var i = 0; i < text.length; i++) {
            info.ref.status[i] = text.codeUnitAt(i);
          }
          info.ref.status[text.length] = 0;
          expect(info.ref.statusString, equals('test_status'));
        });
      },
    );

    test('copyFloatList and copyIntList allocate and copy correctly', () {
      using((arena) {
        expect(copyFloatList(arena, null), equals(ffi.nullptr));
        expect(copyIntList(arena, null), equals(ffi.nullptr));

        final floatPtr = copyFloatList(arena, [1.5, -2.5, 3.0]);
        expect(floatPtr[0], equals(1.5));
        expect(floatPtr[1], equals(-2.5));
        expect(floatPtr[2], equals(3.0));

        final intPtr = copyIntList(arena, [10, -20, 30]);
        expect(intPtr[0], equals(10));
        expect(intPtr[1], equals(-20));
        expect(intPtr[2], equals(30));
      });
    });

    test('copyFloatList clamps double.infinity and -double.infinity', () {
      using((arena) {
        final floatPtr = copyFloatList(arena, [
          double.infinity,
          -double.infinity,
          1.5,
          -2.5,
        ]);
        expect(floatPtr[0], equals(OSQP_INFTY));
        expect(floatPtr[1], equals(-OSQP_INFTY));
        expect(floatPtr[2], equals(1.5));
        expect(floatPtr[3], equals(-2.5));
      });
    });

    test('OsqpException formats known and unknown error codes', () {
      final known = OsqpException(
        osqp_error_type.OSQP_DATA_VALIDATION_ERROR.value,
      );
      expect(
        known.errorCode,
        equals(osqp_error_type.OSQP_DATA_VALIDATION_ERROR.value),
      );
      expect(known.message, isNotEmpty);
      expect(known.toString(), contains('OsqpException'));

      final unknown = OsqpException(9999);
      expect(unknown.errorCode, equals(9999));
      expect(unknown.message, contains('Unknown OSQP error (9999)'));
    });
  });
}
