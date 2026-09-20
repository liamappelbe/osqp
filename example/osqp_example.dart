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

import 'package:osqp/osqp.dart';

void main() {
  print('OSQP version: $osqpVersion');

  final cap = osqpCapabilities;
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

  // P matrix (upper triangular)
  final p = Matrix.fromDense([
    [4.0, 1.0],
    [0.0, 2.0],
  ]);

  // Linear objective vector q
  final q = [1.0, 1.0];

  // Linear constraints matrix A
  final a = Matrix.fromDense([
    [1.0, 1.0],
    [1.0, 0.0],
    [0.0, 1.0],
  ]);

  // Constraint bounds l and u
  final l = [1.0, 0.0, 0.0];
  final u = [1.0, 0.7, 0.7];

  final settings = Settings(polishing: true, verbose: false);

  final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

  try {
    final result = solver.solve();

    print('Solver status: ${result.status} (${result.statusVal})');
    print('Objective value: ${result.objVal.toStringAsFixed(4)}');
    print('Iterations: ${result.iter}');
    print('Optimal solution x:');
    for (var i = 0; i < result.x.length; i++) {
      print('  x[$i] = ${result.x[i].toStringAsFixed(4)}');
    }
    print('Dual solution y:');
    for (var i = 0; i < result.y.length; i++) {
      print('  y[$i] = ${result.y[i].toStringAsFixed(4)}');
    }
  } finally {
    solver.dispose();
    settings.dispose();
  }
}
