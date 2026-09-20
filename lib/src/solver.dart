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
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'matrix.dart';
import 'osqp_bindings.g.dart';
import 'settings.dart';
import 'util.dart';

part 'result.dart';

/// High-level OSQP quadratic program solver.
///
/// Solves convex quadratic programs of the form:
/// ```text
/// minimize    1/2 x' P x + q' x
/// subject to  l <= A x <= u
/// ```
/// where:
/// - `P` is an `n x n` symmetric positive semi-definite matrix (given in upper triangular CSC format).
/// - `q` is an `n`-dimensional linear cost vector.
/// - `A` is an `m x n` linear constraint matrix in CSC format.
/// - `l` is an `m`-dimensional lower bound vector.
/// - `u` is an `m`-dimensional upper bound vector.
class Solver implements ffi.Finalizable {
  static final ffi.NativeFinalizer _finalizer = ffi.NativeFinalizer(
    ffi.Native.addressOf<
          ffi.NativeFunction<OSQPInt Function(ffi.Pointer<OSQPSolver>)>
        >(osqp_cleanup)
        .cast(),
  );

  ffi.Pointer<OSQPSolver> _solver;
  bool _disposed = false;

  final int _m;
  final int _n;

  /// Number of constraints (`m`).
  int get m => _m;

  /// Number of variables (`n`).
  int get n => _n;

  /// Initializes an OSQP solver instance.
  ///
  /// For unconstrained quadratic programs, omit [a], [l], and [u].
  Solver({
    required Matrix p,
    required List<double> q,
    Matrix? a,
    List<double>? l,
    List<double>? u,
    Settings? settings,
  }) : _m = a?.rows ?? 0,
       _n = p.cols,
       _solver = ffi.nullptr {
    if (q.length != _n) {
      throw ArgumentError.value(
        q,
        'q',
        'Length of q (${q.length}) must match number of variables ($_n).',
      );
    }
    if (a == null) {
      if (l != null || u != null) {
        throw ArgumentError('When A is omitted, l and u must also be null.');
      }
    } else {
      if (l == null || u == null) {
        throw ArgumentError(
          'When A is provided, l and u must also be provided.',
        );
      }
      if (l.length != _m) {
        throw ArgumentError.value(
          l,
          'l',
          'Length of l (${l.length}) must match number of constraints ($_m).',
        );
      }
      if (u.length != _m) {
        throw ArgumentError.value(
          u,
          'u',
          'Length of u (${u.length}) must match number of constraints ($_m).',
        );
      }
    }

    final defaultSettings = settings == null ? Settings() : null;
    final zeroA = a == null ? Matrix.zeros(0, _n) : null;
    try {
      final settingsPtr = settings?.pointer ?? defaultSettings!.pointer;
      final solverPtr = using((arena) {
        final qPtr = copyFloatList(arena, q);
        final lPtr = copyFloatList(arena, l);
        final uPtr = copyFloatList(arena, u);
        final aMat = a?.pointer ?? zeroA!.pointer;
        final outSolver = arena<ffi.Pointer<OSQPSolver>>();

        final exitflag = osqp_setup(
          outSolver,
          p.pointer,
          qPtr,
          aMat,
          lPtr,
          uPtr,
          _m,
          _n,
          settingsPtr,
        );

        if (exitflag != 0) {
          throw OsqpException(exitflag);
        }
        return outSolver.value;
      });

      _solver = solverPtr;
      assert(_solver != ffi.nullptr);
      _finalizer.attach(this, _solver.cast(), detach: this);
    } finally {
      defaultSettings?.dispose();
      zeroA?.dispose();
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Cannot use Solver after it has been disposed.');
    }
  }

  /// Whether this solver has been disposed.
  bool get isDisposed => _disposed;

  /// The underlying native [OSQPSolver] pointer.
  ffi.Pointer<OSQPSolver> get pointer {
    _checkNotDisposed();
    return _solver;
  }

  /// Solves the quadratic program.
  Result solve() {
    _checkNotDisposed();
    final status = osqp_solve(_solver);
    if (status != 0) {
      throw OsqpException(status);
    }
    return Result._(this);
  }

  /// Warm starts the primal [x] and/or dual [y] variables.
  void warmStart({List<double>? x, List<double>? y}) {
    _checkNotDisposed();
    if (x == null && y == null) return;
    if (x != null && x.length != _n) {
      throw ArgumentError.value(
        x,
        'x',
        'Length of x (${x.length}) must match number of variables ($_n).',
      );
    }
    if (y != null && y.length != _m) {
      throw ArgumentError.value(
        y,
        'y',
        'Length of y (${y.length}) must match number of constraints ($_m).',
      );
    }

    using((arena) {
      final xPtr = copyFloatList(arena, x);
      final yPtr = copyFloatList(arena, y);

      final status = osqp_warm_start(_solver, xPtr, yPtr);
      if (status != 0) {
        throw OsqpException(status);
      }
    });
  }

  /// Updates problem data vectors [q], [l], and/or [u].
  void updateVectors({List<double>? q, List<double>? l, List<double>? u}) {
    _checkNotDisposed();
    if (q == null && l == null && u == null) return;
    if (q != null && q.length != _n) {
      throw ArgumentError.value(
        q,
        'q',
        'Length of q (${q.length}) must match number of variables ($_n).',
      );
    }
    if (l != null && l.length != _m) {
      throw ArgumentError.value(
        l,
        'l',
        'Length of l (${l.length}) must match number of constraints ($_m).',
      );
    }
    if (u != null && u.length != _m) {
      throw ArgumentError.value(
        u,
        'u',
        'Length of u (${u.length}) must match number of constraints ($_m).',
      );
    }

    using((arena) {
      final qPtr = copyFloatList(arena, q);
      final lPtr = copyFloatList(arena, l);
      final uPtr = copyFloatList(arena, u);

      final status = osqp_update_data_vec(_solver, qPtr, lPtr, uPtr);
      if (status != 0) {
        throw OsqpException(status);
      }
    });
  }

  /// Updates problem matrix elements in P and/or A preserving sparsity patterns.
  void updateMatrices({
    List<double>? pValues,
    List<int>? pIndices,
    List<double>? aValues,
    List<int>? aIndices,
  }) {
    _checkNotDisposed();
    if (pValues == null && aValues == null) return;
    if (pIndices != null && pValues == null) {
      throw ArgumentError('pValues cannot be null when pIndices is provided.');
    }
    if (pIndices != null && pIndices.length != pValues!.length) {
      throw ArgumentError('pIndices and pValues must have the same length.');
    }
    if (aIndices != null && aValues == null) {
      throw ArgumentError('aValues cannot be null when aIndices is provided.');
    }
    if (aIndices != null && aIndices.length != aValues!.length) {
      throw ArgumentError('aIndices and aValues must have the same length.');
    }

    using((arena) {
      final pX = copyFloatList(arena, pValues);
      final pI = copyIntList(arena, pIndices);
      final aX = copyFloatList(arena, aValues);
      final aI = copyIntList(arena, aIndices);

      final status = osqp_update_data_mat(
        _solver,
        pX,
        pI,
        pValues?.length ?? 0,
        aX,
        aI,
        aValues?.length ?? 0,
      );
      if (status != 0) {
        throw OsqpException(status);
      }
    });
  }

  /// Updates solver settings.
  void updateSettings(Settings settings) {
    _checkNotDisposed();
    final status = osqp_update_settings(pointer, settings.pointer);
    if (status != 0) {
      throw OsqpException(status);
    }
  }

  /// Updates the ADMM penalty parameter [rho].
  void updateRho(double rho) {
    _checkNotDisposed();
    final status = osqp_update_rho(_solver, rho);
    if (status != 0) {
      throw OsqpException(status);
    }
  }

  /// Cleans up native solver resources.
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    osqp_cleanup(_solver);
    _solver = ffi.nullptr;
  }
}
