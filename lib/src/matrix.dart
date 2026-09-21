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

import 'package:ffi/ffi.dart';

import 'osqp_bindings.g.dart';

/// Compressed-Column-Sparse (CSC) matrix natively backed by [OSQPCscMatrix].
class Matrix implements Finalizable {
  static final _finalizer = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<OSQPCscMatrix>)>>(
      OSQPCscMatrix_free,
    ).cast(),
  );

  Pointer<OSQPCscMatrix> _ptr;
  bool _disposed = false;

  Matrix._(this._ptr) {
    assert(_ptr != nullptr);
    _finalizer.attach(this, _ptr.cast(), detach: this);
  }

  /// Whether this matrix has been disposed.
  bool get isDisposed => _disposed;

  /// Pointer to the underlying native [OSQPCscMatrix].
  ///
  /// Throws [StateError] if this matrix has been disposed.
  Pointer<OSQPCscMatrix> get pointer {
    if (_disposed) {
      throw StateError('Cannot use Matrix after it has been disposed.');
    }
    return _ptr;
  }

  /// Number of rows.
  int get rows => pointer.ref.m;

  /// Number of columns.
  int get cols => pointer.ref.n;

  /// Number of non-zero entries.
  int get nnz => pointer.ref.nzmax;

  /// Creates an identity matrix of size [n] x [n].
  factory Matrix.identity(int n) {
    if (n < 0) {
      throw ArgumentError('Dimensions must be non-negative.');
    }
    return Matrix._(OSQPCscMatrix_identity(n));
  }

  /// Creates a zero matrix of size [rows] x [cols].
  factory Matrix.zeros(int rows, int cols) {
    if (rows < 0 || cols < 0) {
      throw ArgumentError('Dimensions must be non-negative.');
    }
    return Matrix._(OSQPCscMatrix_zeros(rows, cols));
  }

  /// Creates a diagonal matrix of size [rows] x [cols] with [scalar] along the
  /// diagonal.
  factory Matrix.diagonalScalar(int rows, int cols, double scalar) {
    if (rows < 0 || cols < 0) {
      throw ArgumentError('Dimensions must be non-negative.');
    }
    return Matrix._(OSQPCscMatrix_diag_scalar(rows, cols, scalar));
  }

  /// Creates a diagonal matrix with [values] along the diagonal.
  factory Matrix.diagonal(List<double> values) {
    return using((arena) {
      final count = values.isEmpty ? 1 : values.length;
      final valsPtr = arena<OSQPFloat>(count);
      for (var i = 0; i < values.length; i++) {
        valsPtr[i] = values[i];
      }
      return Matrix._(
        OSQPCscMatrix_diag_vec(values.length, values.length, valsPtr),
      );
    });
  }

  /// Creates a [Matrix] directly from CSC components.
  factory Matrix.fromCsc({
    required int rows,
    required int cols,
    required List<int> colPointers,
    required List<int> rowIndices,
    required List<double> values,
  }) {
    if (colPointers.length != cols + 1) {
      throw ArgumentError.value(
        colPointers.length,
        'colPointers',
        'Length must be cols + 1 (${cols + 1}).',
      );
    }
    if (rowIndices.length != values.length) {
      throw ArgumentError('rowIndices and values must have the same length.');
    }
    final nnz = values.length;
    final pP = calloc<OSQPInt>(cols + 1);
    final pI = calloc<OSQPInt>(nnz);
    final pX = calloc<OSQPFloat>(nnz);

    for (var k = 0; k <= cols; k++) {
      pP[k] = colPointers[k];
    }
    for (var k = 0; k < nnz; k++) {
      pI[k] = rowIndices[k];
      pX[k] = values[k];
    }

    final mat = OSQPCscMatrix_new(rows, cols, nnz, pX, pI, pP)..ref.owned = 1;
    return Matrix._(mat);
  }

  /// Creates a [Matrix] from a dense 2D list `matrix[row][col]`.
  ///
  /// If [upperTriangular] is `true`, only elements with `row <= col` are
  /// included.
  factory Matrix.fromDense(
    List<List<double>> matrix, {
    bool upperTriangular = false,
  }) {
    final rows = matrix.length;
    final cols = rows == 0 ? 0 : matrix[0].length;
    for (var r = 1; r < rows; r++) {
      if (matrix[r].length != cols) {
        throw ArgumentError(
          'All rows in dense matrix must have the same length.',
        );
      }
    }

    final colPointers = <int>[];
    final rowIndicesList = <int>[];
    final valuesList = <double>[];

    for (var c = 0; c < cols; c++) {
      colPointers.add(rowIndicesList.length);
      final maxR = upperTriangular ? (c < rows ? c : rows - 1) : rows - 1;
      for (var r = 0; r <= maxR; r++) {
        final val = matrix[r][c];
        if (val != 0.0) {
          rowIndicesList.add(r);
          valuesList.add(val);
        }
      }
    }
    colPointers.add(rowIndicesList.length);

    return Matrix.fromCsc(
      rows: rows,
      cols: cols,
      colPointers: colPointers,
      rowIndices: rowIndicesList,
      values: valuesList,
    );
  }

  /// Extracts the upper triangular part of [matrix].
  factory Matrix.upperTriangular(List<List<double>> matrix) =>
      Matrix.fromDense(matrix, upperTriangular: true);

  /// Creates a [Matrix] from sparse triplet entries `(row, col, value)`.
  ///
  /// If [upperTriangular] is `true`, entries `(r, c, v)` are folded into
  /// `(min(r, c), max(r, c), v)`.
  ///
  /// Throws [ArgumentError] if [rows] or [cols] are negative.
  /// Throws [RangeError] if any triplet coordinates are out of bounds.
  factory Matrix.fromTriplets(
    int rows,
    int cols,
    Iterable<(int row, int col, double value)> triplets, {
    bool upperTriangular = false,
  }) {
    if (rows < 0 || cols < 0) {
      throw ArgumentError('Dimensions must be non-negative.');
    }

    final list = <({int row, int col, double value})>[];
    for (final (row, col, value) in triplets) {
      if (row < 0 || row >= rows || col < 0 || col >= cols) {
        throw RangeError(
          'Index ($row, $col) out of bounds for matrix of size $rows x $cols.',
        );
      }
      var r = row;
      var c = col;
      if (upperTriangular && r > c) {
        final tmp = r;
        r = c;
        c = tmp;
        if (r >= rows || c >= cols) {
          throw RangeError(
            'Folded index ($r, $c) out of bounds for matrix of size '
            '$rows x $cols.',
          );
        }
      }
      list.add((row: r, col: c, value: value));
    }

    list.sort((a, b) {
      final colComp = a.col.compareTo(b.col);
      if (colComp != 0) return colComp;
      return a.row.compareTo(b.row);
    });

    final merged = <({int row, int col, double value})>[];
    for (final entry in list) {
      if (merged.isNotEmpty &&
          merged.last.row == entry.row &&
          merged.last.col == entry.col) {
        throw ArgumentError(
          'Duplicate entries at (${entry.row}, ${entry.col})',
        );
      }
      merged.add(entry);
    }

    final nnz = merged.length;
    final pP = calloc<OSQPInt>(cols + 1);
    final pI = calloc<OSQPInt>(nnz);
    final pX = calloc<OSQPFloat>(nnz);

    for (var k = 0; k < nnz; k++) {
      pI[k] = merged[k].row;
      pX[k] = merged[k].value;
    }

    var currentIdx = 0;
    for (var c = 0; c < cols; c++) {
      pP[c] = currentIdx;
      while (currentIdx < nnz && merged[currentIdx].col == c) {
        currentIdx++;
      }
    }
    pP[cols] = nnz;

    final mat = OSQPCscMatrix_new(rows, cols, nnz, pX, pI, pP)..ref.owned = 1;
    return Matrix._(mat);
  }

  /// Cleans up native matrix resources.
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    OSQPCscMatrix_free(_ptr);
    _ptr = nullptr;
  }
}
