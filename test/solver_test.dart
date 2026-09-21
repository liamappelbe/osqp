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
import 'package:test/test.dart';

void main() {
  group('Solver', () {
    test('solves canonical 2D QP problem', () {
      final p = Matrix.fromDense([
        [4.0, 1.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 1.0],
      ]);
      final l = [1.0, 0.0, 0.0];
      final u = [1.0, 0.7, 0.7];

      final settings = Settings(polishing: true, verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res = solver.solve();
        expect(res, isA<Result>());

        expect(res.status, equals('solved'));
        expect(res.statusVal, equals(osqp_status_type.OSQP_SOLVED.value));
        expect(res.isSolved, isTrue);
        expect(res.isInfeasible, isFalse);
        expect(res.statusString, equals('solved'));
        expect(res.info.statusString, equals('solved'));
        expect(res.objVal, closeTo(1.88, 1e-3));
        expect(res.iter, greaterThan(0));

        expect(res.x[0], closeTo(0.3, 1e-3));
        expect(res.x[1], closeTo(0.7, 1e-3));

        expect(res.y[0], closeTo(-2.9, 1e-3));
        expect(res.y[1], closeTo(0.0, 1e-3));
        expect(res.y[2], closeTo(0.2, 1e-3));

        expect(res.info.status_val, equals(osqp_status_type.OSQP_SOLVED.value));
        expect(res.solution.x.address, isNonZero);

        solver.dispose();
        expect(solver.isDisposed, isTrue);

        // Result throws StateError after solver disposal
        expect(() => res.x, throwsStateError);
        expect(() => res.y, throwsStateError);
        expect(() => res.status, throwsStateError);
        expect(() => res.statusVal, throwsStateError);
        expect(() => res.statusString, throwsStateError);
        expect(() => res.objVal, throwsStateError);
        expect(() => res.iter, throwsStateError);
        expect(() => res.info, throwsStateError);
        expect(() => res.solution, throwsStateError);
        expect(() => res.primInfCert, throwsStateError);
        expect(() => res.dualInfCert, throwsStateError);
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('solves with default settings when settings is omitted', () {
      final p = Matrix.fromDense([
        [4.0, 1.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 1.0],
      ]);
      final l = [1.0, 0.0, 0.0];
      final u = [1.0, 0.7, 0.7];

      final solver = Solver(p: p, q: q, a: a, l: l, u: u);

      try {
        expect(solver.m, equals(3));
        expect(solver.n, equals(2));
        final res = solver.solve();
        expect(res.status, equals('solved'));
        expect(res.isSolved, isTrue);
        expect(res.x[0], closeTo(0.3, 1e-2));
        expect(res.x[1], closeTo(0.7, 1e-2));
      } finally {
        solver.dispose();
      }
    });

    test('solves unconstrained QP problem (m = 0)', () {
      // min  1/2 x' [4 0; 0 2] x + [1 1]' x
      //      = 2 x1^2 + x2^2 + x1 + x2
      //
      // Optimal unconstrained solution:
      //   grad = P x + q = 0  =>  x* = -P^-1 q = [-0.25, -0.5]'
      //   obj* = -0.375
      final p = Matrix.fromDense([
        [4.0, 0.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final settings = Settings(verbose: false);
      final solver = Solver(p: p, q: q, settings: settings);

      try {
        expect(solver.m, equals(0));
        expect(solver.n, equals(2));

        final res = solver.solve();
        expect(res.status, equals('solved'));
        expect(res.statusVal, equals(osqp_status_type.OSQP_SOLVED.value));
        expect(res.isSolved, isTrue);
        expect(res.isInfeasible, isFalse);
        expect(res.statusString, equals('solved'));
        expect(res.info.statusString, equals('solved'));
        expect(res.objVal, closeTo(-0.375, 1e-3));

        expect(res.x[0], closeTo(-0.25, 1e-3));
        expect(res.x[1], closeTo(-0.5, 1e-3));
        expect(res.y, isEmpty);
        expect(res.primInfCert, isNull);
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('detects primal infeasible problem', () {
      // min  1/2 (x1^2 + x2^2)
      // s.t. x1 + x2 <= 0
      //      x1 + x2 >= 1
      // (infeasible combination)
      final p = Matrix.identity(2);
      final q = [0.0, 0.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 1.0],
      ]);
      final l = [-1e20, 1.0];
      final u = [0.0, 1e20];

      final settings = Settings(verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res = solver.solve();
        expect(res.isInfeasible, isTrue);
        expect(res.isSolved, isFalse);
        expect(
          res.statusVal == osqp_status_type.OSQP_PRIMAL_INFEASIBLE.value ||
              res.statusVal ==
                  osqp_status_type.OSQP_PRIMAL_INFEASIBLE_INACCURATE.value,
          isTrue,
        );
        expect(res.status, contains('infeasible'));
        expect(res.primInfCert, isNotNull);
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('vector updates and re-solve', () {
      final p = Matrix.fromDense([
        [4.0, 1.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 1.0],
      ]);
      final l = [1.0, 0.0, 0.0];
      final u = [1.0, 0.7, 0.7];

      final settings = Settings(polishing: true, verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res1 = solver.solve();
        expect(res1.status, equals('solved'));
        expect(res1.isSolved, isTrue);
        final initialObj = res1.objVal;

        // Update linear cost q
        solver.updateVectors(q: [2.0, 2.0]);
        final res2 = solver.solve();
        expect(res2.status, equals('solved'));
        expect(res2.isSolved, isTrue);
        expect(res2.objVal, isNot(closeTo(initialObj, 1e-4)));

        // Update bounds l and u
        solver.updateVectors(l: [0.5, 0.0, 0.0], u: [0.5, 0.7, 0.7]);
        final res3 = solver.solve();
        expect(res3.status, equals('solved'));
        expect(res3.isSolved, isTrue);
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('matrix updates and re-solve', () {
      final p = Matrix.fromDense([
        [4.0, 1.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 1.0],
      ]);
      final l = [1.0, 0.0, 0.0];
      final u = [1.0, 0.7, 0.7];

      final settings = Settings(polishing: true, verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res1 = solver.solve();
        expect(res1.status, equals('solved'));
        expect(res1.isSolved, isTrue);
        final initialObj = res1.objVal;

        // Update entire P matrix values [4.0, 1.0, 2.0] -> [5.0, 1.0, 2.0]
        solver.updateMatrices(pValues: [5.0, 1.0, 2.0]);
        final res2 = solver.solve();
        expect(res2.status, equals('solved'));
        expect(res2.isSolved, isTrue);
        expect(res2.objVal, isNot(closeTo(initialObj, 1e-4)));

        // Update single element using pIndices
        solver.updateMatrices(pValues: [6.0], pIndices: [0]);
        final res3 = solver.solve();
        expect(res3.status, equals('solved'));
        expect(res3.isSolved, isTrue);

        // Update entire A matrix values
        solver.updateMatrices(aValues: [1.2, 1.0, 1.0, 1.0]);
        final res4 = solver.solve();
        expect(res4.status, equals('solved'));
        expect(res4.isSolved, isTrue);

        // Update single element in A using aIndices
        solver.updateMatrices(aValues: [1.5], aIndices: [1]);
        final res5 = solver.solve();
        expect(res5.status, equals('solved'));
        expect(res5.isSolved, isTrue);
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('settings update and rho update', () {
      final p = Matrix.identity(2);
      final q = [1.0, 1.0];
      final a = Matrix.identity(2);
      final l = [0.0, 0.0];
      final u = [1.0, 1.0];

      final settings = Settings(verbose: false, maxIter: 100);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      final updateSettings = Settings(maxIter: 200, verbose: false);
      try {
        solver.updateSettings(updateSettings);
        solver.updateRho(0.2);

        final res = solver.solve();
        expect(res.status, equals('solved'));
        expect(res.isSolved, isTrue);
      } finally {
        solver.dispose();
        settings.dispose();
        updateSettings.dispose();
      }
    });

    test('warm starting reduces iterations', () {
      final p = Matrix.fromDense([
        [4.0, 1.0],
        [0.0, 2.0],
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromDense([
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 1.0],
      ]);
      final l = [1.0, 0.0, 0.0];
      final u = [1.0, 0.7, 0.7];

      final settings = Settings(verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res1 = solver.solve();
        expect(res1.status, equals('solved'));
        expect(res1.isSolved, isTrue);
        final initialIters = res1.iter;

        // Warm start with the optimal solution
        solver.warmStart(x: res1.x, y: res1.y);
        final res2 = solver.solve();
        expect(res2.status, equals('solved'));
        expect(res2.isSolved, isTrue);
        // Solving from the optimal solution should take fewer iterations
        expect(res2.iter, lessThanOrEqualTo(initialIters));
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });

    test('disposal prevents use-after-free and throws StateError', () {
      final p = Matrix.identity(2);
      final q = [1.0, 1.0];
      final a = Matrix.identity(2);
      final l = [0.0, 0.0];
      final u = [1.0, 1.0];

      final settings = Settings(verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      expect(solver.isDisposed, isFalse);
      solver.dispose();
      expect(solver.isDisposed, isTrue);

      // Safe to dispose multiple times
      solver.dispose();

      expect(() => solver.solve(), throwsStateError);
      expect(() => solver.warmStart(x: [0.0, 0.0]), throwsStateError);
      expect(() => solver.updateVectors(q: [0.0, 0.0]), throwsStateError);
      final dummySettings = Settings();
      try {
        expect(() => solver.updateSettings(dummySettings), throwsStateError);
      } finally {
        dummySettings.dispose();
        settings.dispose();
      }
      expect(() => solver.updateRho(0.5), throwsStateError);
      expect(() => solver.pointer, throwsStateError);
    });

    test('validates input dimensions and upper triangular P', () {
      final nonSquareP = Matrix.zeros(2, 3);
      expect(
        () => Solver(
          p: nonSquareP,
          q: [0.0, 0.0, 0.0],
          a: Matrix.zeros(1, 3),
          l: [0.0],
          u: [1.0],
        ),
        throwsA(isA<OsqpException>()),
      );

      final nonUpperP = Matrix.fromDense([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      expect(
        () => Solver(
          p: nonUpperP,
          q: [0.0, 0.0],
          a: Matrix.zeros(1, 2),
          l: [0.0],
          u: [1.0],
        ),
        throwsA(
          isA<OsqpException>().having(
            (e) => e.errorCode,
            'errorCode',
            equals(osqp_error_type.OSQP_DATA_VALIDATION_ERROR.value),
          ),
        ),
      );

      final squareP = Matrix.identity(2);
      // Mismatched q length
      expect(
        () => Solver(
          p: squareP,
          q: [0.0],
          a: Matrix.zeros(1, 2),
          l: [0.0],
          u: [1.0],
        ),
        throwsArgumentError,
      );

      // Mismatched a cols
      expect(
        () => Solver(
          p: squareP,
          q: [0.0, 0.0],
          a: Matrix.zeros(1, 3),
          l: [0.0],
          u: [1.0],
        ),
        throwsA(isA<OsqpException>()),
      );

      // Mismatched l length
      expect(
        () => Solver(
          p: squareP,
          q: [0.0, 0.0],
          a: Matrix.zeros(2, 2),
          l: [0.0],
          u: [1.0, 1.0],
        ),
        throwsArgumentError,
      );

      // Mismatched u length
      expect(
        () => Solver(
          p: squareP,
          q: [0.0, 0.0],
          a: Matrix.zeros(2, 2),
          l: [0.0, 0.0],
          u: [1.0],
        ),
        throwsArgumentError,
      );

      // A omitted but l or u provided
      expect(
        () => Solver(p: squareP, q: [0.0, 0.0], l: [0.0]),
        throwsArgumentError,
      );
      expect(
        () => Solver(p: squareP, q: [0.0, 0.0], u: [0.0]),
        throwsArgumentError,
      );

      // A provided but l or u omitted
      expect(
        () =>
            Solver(p: squareP, q: [0.0, 0.0], a: Matrix.zeros(1, 2), l: [0.0]),
        throwsArgumentError,
      );
      expect(
        () =>
            Solver(p: squareP, q: [0.0, 0.0], a: Matrix.zeros(1, 2), u: [0.0]),
        throwsArgumentError,
      );
    });

    test('solves with double.infinity and -double.infinity bounds', () {
      // min  1/2 x' [4 1; 0 2] x + [1 1]' x
      // s.t. 1 <= x1 + x2 <= 1 (equality)
      //      0 <= x1 <= inf
      //      -inf <= x2 <= 0.7
      // Optimal solution: x* = [0.3, 0.7]
      final p = Matrix.fromTriplets(2, 2, [
        (0, 0, 4.0),
        (0, 1, 1.0),
        (1, 1, 2.0),
      ]);
      final q = [1.0, 1.0];
      final a = Matrix.fromTriplets(3, 2, [
        (0, 0, 1.0),
        (0, 1, 1.0),
        (1, 0, 1.0),
        (2, 1, 1.0),
      ]);
      final l = [1.0, 0.0, -double.infinity];
      final u = [1.0, double.infinity, 0.7];

      final settings = Settings(polishing: true, verbose: false);
      final solver = Solver(p: p, q: q, a: a, l: l, u: u, settings: settings);

      try {
        final res = solver.solve();
        expect(res.status, equals('solved'));
        expect(res.isSolved, isTrue);
        expect(res.isInfeasible, isFalse);
        expect(res.objVal.isNaN, isFalse);
        expect(res.x[0].isNaN, isFalse);
        expect(res.x[1].isNaN, isFalse);
        expect(res.x[0], closeTo(0.3, 1e-3));
        expect(res.x[1], closeTo(0.7, 1e-3));
        expect(res.iter, lessThan(settings.maxIter));
      } finally {
        solver.dispose();
        settings.dispose();
      }
    });
  });
}
