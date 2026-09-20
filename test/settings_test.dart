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
  group('Settings', () {
    test('default settings match OSQP defaults', () {
      final s = Settings();
      try {
        expect(s.verbose, isTrue);
        expect(s.warmStarting, isTrue);
        expect(s.polishing, isFalse);
        expect(s.maxIter, equals(4000));
        expect(s.epsAbs, equals(1e-3));
        expect(s.epsRel, equals(1e-3));
        expect(s.rho, equals(0.1));
        expect(s.alpha, equals(1.6));
      } finally {
        s.dispose();
      }
    });

    test('constructor applies custom settings', () {
      final s = Settings(
        maxIter: 500,
        verbose: false,
        polishing: true,
        rho: 0.5,
      );
      try {
        expect(s.maxIter, equals(500));
        expect(s.verbose, isFalse);
        expect(s.polishing, isTrue);
        expect(s.rho, equals(0.5));
        expect(s.ref.max_iter, equals(500));
        expect(s.ref.verbose, equals(0));
        expect(s.ref.polishing, equals(1));
        expect(s.ref.rho, equals(0.5));
      } finally {
        s.dispose();
      }
    });

    test('getters, setters and ref mutation', () {
      final s = Settings();
      try {
        s.maxIter = 1000;
        expect(s.maxIter, equals(1000));
        expect(s.ref.max_iter, equals(1000));

        s.verbose = false;
        expect(s.verbose, isFalse);
        expect(s.ref.verbose, equals(0));

        s.polishing = true;
        expect(s.polishing, isTrue);
        expect(s.ref.polishing, equals(1));

        s.epsAbs = 1e-4;
        expect(s.epsAbs, equals(1e-4));
        expect(s.ref.eps_abs, equals(1e-4));

        s.epsRel = 1e-5;
        expect(s.epsRel, equals(1e-5));
        expect(s.ref.eps_rel, equals(1e-5));

        s.rho = 0.2;
        expect(s.rho, equals(0.2));
        expect(s.ref.rho, equals(0.2));

        // Direct ref mutation
        s.ref.max_iter = 2000;
        expect(s.maxIter, equals(2000));
      } finally {
        s.dispose();
      }
    });

    test('disposal prevents use-after-free and throws StateError', () {
      final s = Settings();
      expect(s.isDisposed, isFalse);
      expect(s.pointer.address, isNonZero);

      s.dispose();
      expect(s.isDisposed, isTrue);

      // Safe to dispose multiple times (idempotent)
      s.dispose();
      expect(s.isDisposed, isTrue);

      expect(() => s.pointer, throwsStateError);
      expect(() => s.ref, throwsStateError);
      expect(() => s.verbose, throwsStateError);
      expect(() => s.verbose = true, throwsStateError);
      expect(() => s.maxIter, throwsStateError);
      expect(() => s.maxIter = 100, throwsStateError);
    });
  });
}
