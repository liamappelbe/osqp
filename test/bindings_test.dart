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
  group('OSQP bindings', () {
    test('library version and capabilities', () {
      final version = osqp_version().cast<Utf8>().toDartString();
      expect(version, isNotEmpty);
      expect(version, startsWith('1.'));

      final cap = osqp_capabilities();
      expect(cap, isNonZero);
      expect(
        cap & osqp_capabilities_type.OSQP_CAPABILITY_DIRECT_SOLVER.value,
        isNonZero,
      );
    });

    test('solves canonical QP problem with raw pointers', () {
      // Port of third_party/osqp/examples/osqp_simple_demo.c and
      // third_party/osqp/tests/demo/test_demo.cpp:
      //
      // min  1/2 x' [4 1; 1 2] x + [1 1]' x
      // s.t. [1; 0; 0] <= [1 1; 1 0; 0 1] x <= [1; 0.7; 0.7]
      //
      // Expected:
      //   status: solved (1)
      //   x* = [0.3, 0.7]'
      //   y* = [-2.9, 0.0, 0.2]'
      //   obj* = 1.88
      const n = 2;
      const m = 3;

      const pNnz = 3;
      final pX = calloc<OSQPFloat>(pNnz);
      pX[0] = 4.0;
      pX[1] = 1.0;
      pX[2] = 2.0;

      final pI = calloc<OSQPInt>(pNnz);
      pI[0] = 0;
      pI[1] = 0;
      pI[2] = 1;

      final pP = calloc<OSQPInt>(n + 1);
      pP[0] = 0;
      pP[1] = 1;
      pP[2] = 3;

      final q = calloc<OSQPFloat>(n);
      q[0] = 1.0;
      q[1] = 1.0;

      const aNnz = 4;
      final aX = calloc<OSQPFloat>(aNnz);
      aX[0] = 1.0;
      aX[1] = 1.0;
      aX[2] = 1.0;
      aX[3] = 1.0;

      final aI = calloc<OSQPInt>(aNnz);
      aI[0] = 0;
      aI[1] = 1;
      aI[2] = 0;
      aI[3] = 2;

      final aP = calloc<OSQPInt>(n + 1);
      aP[0] = 0;
      aP[1] = 2;
      aP[2] = 4;

      final l = calloc<OSQPFloat>(m);
      l[0] = 1.0;
      l[1] = 0.0;
      l[2] = 0.0;

      final u = calloc<OSQPFloat>(m);
      u[0] = 1.0;
      u[1] = 0.7;
      u[2] = 0.7;

      final pMat = OSQPCscMatrix_new(n, n, pNnz, pX, pI, pP);
      final aMat = OSQPCscMatrix_new(m, n, aNnz, aX, aI, aP);
      final settings = OSQPSettings_new();

      expect(pMat.address, isNonZero);
      expect(aMat.address, isNonZero);
      expect(settings.address, isNonZero);

      settings.ref.verbose = 0;
      settings.ref.polishing = 1;

      final solverPtr = calloc<ffi.Pointer<OSQPSolver>>();

      try {
        final exitflag = osqp_setup(
          solverPtr,
          pMat,
          q,
          aMat,
          l,
          u,
          m,
          n,
          settings,
        );
        expect(exitflag, equals(0));

        final solver = solverPtr.value;
        expect(solver.address, isNonZero);

        final solveStatus = osqp_solve(solver);
        expect(solveStatus, equals(0));

        final info = solver.ref.info.ref;
        final solution = solver.ref.solution.ref;
        final statusStr = solver.ref.info.cast<Utf8>().toDartString();

        expect(info.status_val, equals(osqp_status_type.OSQP_SOLVED.value));
        expect(statusStr, equals('solved'));
        expect(info.statusString, equals('solved'));
        expect(info.iter, greaterThan(0));
        expect(info.obj_val, closeTo(1.88, 1e-3));

        expect(solution.x[0], closeTo(0.3, 1e-3));
        expect(solution.x[1], closeTo(0.7, 1e-3));

        expect(solution.y[0], closeTo(-2.9, 1e-3));
        expect(solution.y[1], closeTo(0.0, 1e-3));
        expect(solution.y[2], closeTo(0.2, 1e-3));

        osqp_cleanup(solver);
      } finally {
        OSQPCscMatrix_free(aMat);
        OSQPCscMatrix_free(pMat);
        OSQPSettings_free(settings);

        calloc.free(solverPtr);
        calloc.free(u);
        calloc.free(l);
        calloc.free(aP);
        calloc.free(aI);
        calloc.free(aX);
        calloc.free(q);
        calloc.free(pP);
        calloc.free(pI);
        calloc.free(pX);
      }
    });

    test('solves canonical QP problem with arena allocator', () {
      using((arena) {
        const n = 2;
        const m = 3;

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

        final q = arena<OSQPFloat>(n);
        q[0] = 1.0;
        q[1] = 1.0;

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

        settings.ref.verbose = 0;
        settings.ref.polishing = 1;

        final solverPtr = arena<ffi.Pointer<OSQPSolver>>();

        try {
          final exitflag = osqp_setup(
            solverPtr,
            pMat,
            q,
            aMat,
            l,
            u,
            m,
            n,
            settings,
          );
          expect(exitflag, equals(0));

          final solver = solverPtr.value;
          final solveStatus = osqp_solve(solver);
          expect(solveStatus, equals(0));

          final info = solver.ref.info.ref;
          final solution = solver.ref.solution.ref;

          expect(info.status_val, equals(osqp_status_type.OSQP_SOLVED.value));
          expect(info.obj_val, closeTo(1.88, 1e-3));
          expect(solution.x[0], closeTo(0.3, 1e-3));
          expect(solution.x[1], closeTo(0.7, 1e-3));

          osqp_cleanup(solver);
        } finally {
          OSQPCscMatrix_free(aMat);
          OSQPCscMatrix_free(pMat);
          OSQPSettings_free(settings);
        }
      });
    });
  });
}
