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

void main() {
  print('OSQP version: ${osqp_version().cast<Utf8>().toDartString()}');

  final cap = osqp_capabilities();
  print('Capabilities:');
  if (cap & osqp_capabilities_type.OSQP_CAPABILITY_DIRECT_SOLVER.value != 0) {
    print('  - Direct linear algebra solver');
  }
  if (cap & osqp_capabilities_type.OSQP_CAPABILITY_INDIRECT_SOLVER.value != 0) {
    print('  - Indirect linear algebra solver');
  }
  if (cap & osqp_capabilities_type.OSQP_CAPABILITY_CODEGEN.value != 0) {
    print('  - Code generation');
  }
  if (cap & osqp_capabilities_type.OSQP_CAPABILITY_DERIVATIVES.value != 0) {
    print('  - Derivatives calculation');
  }
  print('');

  // Port of examples/osqp_simple_demo.c:
  //
  // Minimize:
  //   1/2 x' P x + q' x = 2 x_1^2 + x_1 x_2 + x_2^2 + x_1 + x_2
  //
  // Subject to:
  //   l <= A x <= u
  //   [1.0] <= [1.0  1.0] [x_1] <= [1.0]
  //   [0.0] <= [1.0  0.0] [x_2] <= [0.7]
  //   [0.0] <= [0.0  1.0]       <= [0.7]
  //
  // Optimal solution:
  //   x* = [0.3, 0.7]'
  //   obj* = 1.88

  using((arena) {
    const n = 2;
    const m = 3;

    // P matrix in CSC format (upper triangular)
    const pNnz = 3;
    final pX = arena<OSQPFloat>(pNnz);
    pX[0] = 4.0;
    pX[1] = 1.0;
    pX[2] = 2.0;

    final pI = arena<OSQPInt>(pNnz);
    pI[0] = 0;
    pI[1] = 0;
    pI[2] = 1;

    final pP = arena<OSQPInt>(n + 1);
    pP[0] = 0;
    pP[1] = 1;
    pP[2] = 3;

    // Linear objective vector q
    final q = arena<OSQPFloat>(n);
    q[0] = 1.0;
    q[1] = 1.0;

    // A matrix in CSC format
    const aNnz = 4;
    final aX = arena<OSQPFloat>(aNnz);
    aX[0] = 1.0;
    aX[1] = 1.0;
    aX[2] = 1.0;
    aX[3] = 1.0;

    final aI = arena<OSQPInt>(aNnz);
    aI[0] = 0;
    aI[1] = 1;
    aI[2] = 0;
    aI[3] = 2;

    final aP = arena<OSQPInt>(n + 1);
    aP[0] = 0;
    aP[1] = 2;
    aP[2] = 4;

    // Constraint bounds l and u
    final l = arena<OSQPFloat>(m);
    l[0] = 1.0;
    l[1] = 0.0;
    l[2] = 0.0;

    final u = arena<OSQPFloat>(m);
    u[0] = 1.0;
    u[1] = 0.7;
    u[2] = 0.7;

    final pMat = OSQPCscMatrix_new(n, n, pNnz, pX, pI, pP);
    final aMat = OSQPCscMatrix_new(m, n, aNnz, aX, aI, aP);
    final settings = OSQPSettings_new();

    if (settings != ffi.nullptr) {
      settings.ref.polishing = 1;
    }

    final solverPtr = arena<ffi.Pointer<OSQPSolver>>();
    final exitflag = osqp_setup(solverPtr, pMat, q, aMat, l, u, m, n, settings);

    if (exitflag != 0) {
      print('osqp_setup failed with error code $exitflag');
      OSQPCscMatrix_free(aMat);
      OSQPCscMatrix_free(pMat);
      if (settings != ffi.nullptr) OSQPSettings_free(settings);
      return;
    }

    final solver = solverPtr.value;
    try {
      final solveStatus = osqp_solve(solver);
      if (solveStatus != 0) {
        print('osqp_solve failed with error code $solveStatus');
        return;
      }

      final info = solver.ref.info.ref;
      final solution = solver.ref.solution.ref;
      final statusStr = solver.ref.info.cast<Utf8>().toDartString();

      print('Solver status: $statusStr (${info.status_val})');
      print('Objective value: ${info.obj_val.toStringAsFixed(4)}');
      print('Iterations: ${info.iter}');
      print('Optimal solution x:');
      for (var i = 0; i < n; i++) {
        print('  x[$i] = ${solution.x[i].toStringAsFixed(4)}');
      }
      print('Dual solution y:');
      for (var i = 0; i < m; i++) {
        print('  y[$i] = ${solution.y[i].toStringAsFixed(4)}');
      }
    } finally {
      osqp_cleanup(solver);
      OSQPCscMatrix_free(aMat);
      OSQPCscMatrix_free(pMat);
      if (settings != ffi.nullptr) OSQPSettings_free(settings);
    }
  });
}
