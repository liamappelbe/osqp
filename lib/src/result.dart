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

part of 'solver.dart';

/// The result of an OSQP solve operation.
///
/// Provides zero-copy access to solution and diagnostic information backed by
/// the underlying [Solver].
class Result {
  /// The solver instance that produced this result.
  final Solver solver;

  Result._(this.solver);

  void _checkNotDisposed() {
    if (solver.isDisposed) {
      throw StateError('Cannot access result: solver has been disposed');
    }
  }

  /// Primal solution vector.
  Float64List get x {
    _checkNotDisposed();
    return solver.pointer.ref.solution.ref.x.asTypedList(solver.n);
  }

  /// Dual solution vector / Lagrange multipliers.
  Float64List get y {
    _checkNotDisposed();
    if (solver.m == 0) return Float64List(0);
    final yPtr = solver.pointer.ref.solution.ref.y;
    return yPtr == ffi.nullptr ? Float64List(0) : yPtr.asTypedList(solver.m);
  }

  /// Primal infeasibility certificate (null if not available).
  Float64List? get primInfCert {
    _checkNotDisposed();
    if (solver.m == 0) return null;
    final cert = solver.pointer.ref.solution.ref.prim_inf_cert;
    return cert == ffi.nullptr ? null : cert.asTypedList(solver.m);
  }

  /// Dual infeasibility certificate (null if not available).
  Float64List? get dualInfCert {
    _checkNotDisposed();
    final cert = solver.pointer.ref.solution.ref.dual_inf_cert;
    return cert == ffi.nullptr ? null : cert.asTypedList(solver.n);
  }

  /// Solver exit status string, e.g. 'solved'.
  String get status {
    _checkNotDisposed();
    return solver.pointer.ref.info.ref.statusString;
  }

  /// Status string, e.g. 'solved'.
  String get statusString => status;

  /// Solver exit status code.
  int get statusVal {
    _checkNotDisposed();
    return solver.pointer.ref.info.ref.status_val;
  }

  /// Whether the problem was solved to optimality (exact or inaccurate).
  bool get isSolved =>
      statusVal == osqp_status_type.OSQP_SOLVED.value ||
      statusVal == osqp_status_type.OSQP_SOLVED_INACCURATE.value;

  /// Whether the problem was proven infeasible (primal or dual).
  bool get isInfeasible =>
      statusVal == osqp_status_type.OSQP_PRIMAL_INFEASIBLE.value ||
      statusVal == osqp_status_type.OSQP_PRIMAL_INFEASIBLE_INACCURATE.value ||
      statusVal == osqp_status_type.OSQP_DUAL_INFEASIBLE.value ||
      statusVal == osqp_status_type.OSQP_DUAL_INFEASIBLE_INACCURATE.value;

  /// Primal objective value.
  double get objVal {
    _checkNotDisposed();
    return solver.pointer.ref.info.ref.obj_val;
  }

  /// Number of iterations taken.
  int get iter {
    _checkNotDisposed();
    return solver.pointer.ref.info.ref.iter;
  }

  /// Direct access to all 16 C diagnostic fields of the [OSQPInfo] struct.
  OSQPInfo get info {
    _checkNotDisposed();
    return solver.pointer.ref.info.ref;
  }

  /// Direct access to the underlying [OSQPSolution] struct.
  OSQPSolution get solution {
    _checkNotDisposed();
    return solver.pointer.ref.solution.ref;
  }
}
