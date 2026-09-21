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

import 'package:osqp/osqp.dart';
import 'package:test/test.dart';

void main() {
  group('Matrix', () {
    test('fromDense constructs correct CSC structure', () {
      final mat = Matrix.fromDense([
        [1.0, 2.0, 0.0],
        [0.0, 3.0, 4.0],
        [5.0, 0.0, 6.0],
      ]);

      expect(mat.rows, equals(3));
      expect(mat.cols, equals(3));
      expect(mat.nnz, equals(6));
      expect(
        mat.pointer.ref.p.cast<ffi.Int64>().asTypedList(4),
        equals([0, 2, 4, 6]),
      );
      expect(
        mat.pointer.ref.i.cast<ffi.Int64>().asTypedList(6),
        equals([0, 2, 0, 1, 1, 2]),
      );
      expect(
        mat.pointer.ref.x.asTypedList(6),
        equals([1.0, 5.0, 2.0, 3.0, 4.0, 6.0]),
      );

      expect(
        () => Matrix.fromDense([
          [1.0, 2.0],
          [3.0],
        ]),
        throwsArgumentError,
      );
    });

    test('fromDense with upperTriangular filters lower elements', () {
      final mat = Matrix.fromDense([
        [4.0, 1.0],
        [1.0, 2.0],
      ], upperTriangular: true);

      expect(mat.rows, equals(2));
      expect(mat.cols, equals(2));
      expect(mat.nnz, equals(3));
      expect(
        mat.pointer.ref.p.cast<ffi.Int64>().asTypedList(3),
        equals([0, 1, 3]),
      );
      expect(
        mat.pointer.ref.i.cast<ffi.Int64>().asTypedList(3),
        equals([0, 0, 1]),
      );
      expect(mat.pointer.ref.x.asTypedList(3), equals([4.0, 1.0, 2.0]));
    });

    test('upperTriangular constructor', () {
      final triu = Matrix.upperTriangular([
        [4.0, 1.0],
        [1.0, 2.0],
      ]);

      expect(triu.rows, equals(2));
      expect(triu.cols, equals(2));
      expect(triu.nnz, equals(3));
      expect(
        triu.pointer.ref.p.cast<ffi.Int64>().asTypedList(3),
        equals([0, 1, 3]),
      );
      expect(
        triu.pointer.ref.i.cast<ffi.Int64>().asTypedList(3),
        equals([0, 0, 1]),
      );
      expect(triu.pointer.ref.x.asTypedList(3), equals([4.0, 1.0, 2.0]));
    });

    test('fromCsc constructor', () {
      final mat = Matrix.fromCsc(
        rows: 3,
        cols: 3,
        colPointers: [0, 2, 4, 6],
        rowIndices: [0, 2, 0, 1, 1, 2],
        values: [1.0, 5.0, 2.0, 3.0, 4.0, 6.0],
      );

      expect(mat.rows, equals(3));
      expect(mat.cols, equals(3));
      expect(mat.nnz, equals(6));
      expect(
        mat.pointer.ref.p.cast<ffi.Int64>().asTypedList(4),
        equals([0, 2, 4, 6]),
      );
      expect(
        mat.pointer.ref.i.cast<ffi.Int64>().asTypedList(6),
        equals([0, 2, 0, 1, 1, 2]),
      );
      expect(
        mat.pointer.ref.x.asTypedList(6),
        equals([1.0, 5.0, 2.0, 3.0, 4.0, 6.0]),
      );

      expect(
        () => Matrix.fromCsc(
          rows: 2,
          cols: 2,
          colPointers: [0, 1], // Wrong length (expected cols + 1 = 3)
          rowIndices: [0],
          values: [1.0],
        ),
        throwsArgumentError,
      );

      expect(
        () => Matrix.fromCsc(
          rows: 2,
          cols: 2,
          colPointers: [0, 1, 2],
          rowIndices: [0],
          values: [1.0, 2.0], // Mismatched length with rowIndices
        ),
        throwsArgumentError,
      );
    });

    test('identity constructor', () {
      final eye = Matrix.identity(3);
      expect(eye.rows, equals(3));
      expect(eye.cols, equals(3));
      expect(eye.nnz, equals(3));
      expect(
        eye.pointer.ref.p.cast<ffi.Int64>().asTypedList(4),
        equals([0, 1, 2, 3]),
      );
      expect(
        eye.pointer.ref.i.cast<ffi.Int64>().asTypedList(3),
        equals([0, 1, 2]),
      );
      expect(eye.pointer.ref.x.asTypedList(3), equals([1.0, 1.0, 1.0]));

      expect(() => Matrix.identity(-1), throwsArgumentError);
    });

    test('zeros constructor', () {
      final zeros = Matrix.zeros(2, 4);
      expect(zeros.rows, equals(2));
      expect(zeros.cols, equals(4));
      expect(zeros.nnz, equals(0));
      expect(
        zeros.pointer.ref.p.cast<ffi.Int64>().asTypedList(5),
        equals([0, 0, 0, 0, 0]),
      );

      expect(() => Matrix.zeros(-1, 2), throwsArgumentError);
      expect(() => Matrix.zeros(2, -1), throwsArgumentError);
    });

    test('diagonalScalar constructor', () {
      final diagScalar = Matrix.diagonalScalar(3, 3, 2.5);
      expect(diagScalar.rows, equals(3));
      expect(diagScalar.cols, equals(3));
      expect(diagScalar.nnz, equals(3));
      expect(diagScalar.pointer.ref.x.asTypedList(3), equals([2.5, 2.5, 2.5]));

      expect(() => Matrix.diagonalScalar(-1, 3, 1.0), throwsArgumentError);
    });

    test('diagonal constructor', () {
      final diag = Matrix.diagonal([2.0, 5.0, 3.0]);
      expect(diag.rows, equals(3));
      expect(diag.cols, equals(3));
      expect(diag.nnz, equals(3));
      expect(diag.pointer.ref.x.asTypedList(3), equals([2.0, 5.0, 3.0]));
    });

    test(
      'fromTriplets constructs correct CSC structure and sorts by col then row',
      () {
        final mat = Matrix.fromTriplets(3, 3, [
          (2, 2, 6.0),
          (0, 0, 1.0),
          (1, 1, 3.0),
          (0, 1, 2.0),
          (2, 0, 5.0),
          (1, 2, 4.0),
        ]);

        expect(mat.rows, equals(3));
        expect(mat.cols, equals(3));
        expect(mat.nnz, equals(6));
        expect(
          mat.pointer.ref.p.cast<ffi.Int64>().asTypedList(4),
          equals([0, 2, 4, 6]),
        );
        expect(
          mat.pointer.ref.i.cast<ffi.Int64>().asTypedList(6),
          equals([0, 2, 0, 1, 1, 2]),
        );
        expect(
          mat.pointer.ref.x.asTypedList(6),
          equals([1.0, 5.0, 2.0, 3.0, 4.0, 6.0]),
        );
      },
    );

    test('fromTriplets throws on duplicate coordinates', () {
      expect(
        () => Matrix.fromTriplets(2, 2, [
          (0, 0, 1.5),
          (0, 0, 2.5),
          (1, 0, 1.0),
          (1, 0, -0.5),
          (0, 1, 3.0),
          (0, 0, -1.0),
        ]),
        throwsArgumentError,
      );
    });

    test('fromTriplets with upperTriangular folds lower entries to upper', () {
      final mat = Matrix.fromTriplets(2, 2, [
        (0, 0, 4.0),
        (1, 0, 1.0),
        (1, 1, 2.0),
      ], upperTriangular: true);

      expect(mat.rows, equals(2));
      expect(mat.cols, equals(2));
      expect(mat.nnz, equals(3));
      expect(
        mat.pointer.ref.p.cast<ffi.Int64>().asTypedList(3),
        equals([0, 1, 3]),
      );
      expect(
        mat.pointer.ref.i.cast<ffi.Int64>().asTypedList(3),
        equals([0, 0, 1]),
      );
      expect(mat.pointer.ref.x.asTypedList(3), equals([4.0, 1.0, 2.0]));

      expect(
        () => Matrix.fromTriplets(2, 2, [
          (0, 0, 4.0),
          (1, 0, 2.0),
          (0, 1, 3.0),
          (1, 1, 1.0),
        ], upperTriangular: true),
        throwsArgumentError,
      );
    });

    test('fromTriplets validates index bounds and dimensions', () {
      expect(() => Matrix.fromTriplets(-1, 2, []), throwsArgumentError);
      expect(() => Matrix.fromTriplets(2, -1, []), throwsArgumentError);

      expect(() => Matrix.fromTriplets(2, 2, [(-1, 0, 1.0)]), throwsRangeError);
      expect(() => Matrix.fromTriplets(2, 2, [(2, 0, 1.0)]), throwsRangeError);
      expect(() => Matrix.fromTriplets(2, 2, [(0, -1, 1.0)]), throwsRangeError);
      expect(() => Matrix.fromTriplets(2, 2, [(0, 2, 1.0)]), throwsRangeError);
      expect(
        () => Matrix.fromTriplets(2, 2, [(2, 1, 1.0)], upperTriangular: true),
        throwsRangeError,
      );
    });

    test('disposal prevents use-after-free and throws StateError', () {
      final mat = Matrix.identity(2);
      expect(mat.isDisposed, isFalse);
      expect(mat.rows, equals(2));
      expect(mat.cols, equals(2));
      expect(mat.nnz, equals(2));
      expect(mat.pointer.address, isNonZero);

      mat.dispose();
      expect(mat.isDisposed, isTrue);

      // Safe to dispose multiple times (idempotent)
      mat.dispose();
      expect(mat.isDisposed, isTrue);

      expect(() => mat.pointer, throwsStateError);
      expect(() => mat.rows, throwsStateError);
      expect(() => mat.cols, throwsStateError);
      expect(() => mat.nnz, throwsStateError);
    });
  });
}
