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

import 'osqp_bindings.g.dart';

/// Solver configuration settings for OSQP.
///
/// Wraps a native [OSQPSettings] pointer. Native memory is automatically freed
/// via [ffi.NativeFinalizer] when garbage-collected, or explicitly via [dispose].
class Settings implements ffi.Finalizable {
  static final _finalizer = ffi.NativeFinalizer(
    ffi.Native.addressOf<
          ffi.NativeFunction<ffi.Void Function(ffi.Pointer<OSQPSettings>)>
        >(OSQPSettings_free)
        .cast(),
  );

  ffi.Pointer<OSQPSettings> _ptr;

  /// Creates a new [Settings] object initialized with OSQP defaults.
  ///
  /// Any passed optional named parameters override the corresponding default values.
  Settings({
    int? device,
    osqp_linsys_solver_type? linsysSolver,
    bool? allocateSolution,
    bool? verbose,
    int? profilerLevel,
    bool? warmStarting,
    int? scaling,
    bool? polishing,
    double? rho,
    bool? rhoIsVec,
    double? sigma,
    double? alpha,
    int? cgMaxIter,
    int? cgTolReduction,
    double? cgTolFraction,
    osqp_precond_type? cgPrecond,
    int? adaptiveRho,
    int? adaptiveRhoInterval,
    double? adaptiveRhoFraction,
    double? adaptiveRhoTolerance,
    int? maxIter,
    double? epsAbs,
    double? epsRel,
    double? epsPrimInf,
    double? epsDualInf,
    bool? scaledTermination,
    int? checkTermination,
    bool? checkDualgap,
    double? timeLimit,
    double? delta,
    int? polishRefineIter,
  }) : _ptr = OSQPSettings_new() {
    assert(_ptr != ffi.nullptr);
    _finalizer.attach(this, _ptr.cast(), detach: this);

    if (device != null) _ptr.ref.device = device;
    if (linsysSolver != null) _ptr.ref.linsys_solver = linsysSolver;
    if (allocateSolution != null) {
      _ptr.ref.allocate_solution = allocateSolution ? 1 : 0;
    }
    if (verbose != null) _ptr.ref.verbose = verbose ? 1 : 0;
    if (profilerLevel != null) _ptr.ref.profiler_level = profilerLevel;
    if (warmStarting != null) _ptr.ref.warm_starting = warmStarting ? 1 : 0;
    if (scaling != null) _ptr.ref.scaling = scaling;
    if (polishing != null) _ptr.ref.polishing = polishing ? 1 : 0;
    if (rho != null) _ptr.ref.rho = rho;
    if (rhoIsVec != null) _ptr.ref.rho_is_vec = rhoIsVec ? 1 : 0;
    if (sigma != null) _ptr.ref.sigma = sigma;
    if (alpha != null) _ptr.ref.alpha = alpha;
    if (cgMaxIter != null) _ptr.ref.cg_max_iter = cgMaxIter;
    if (cgTolReduction != null) _ptr.ref.cg_tol_reduction = cgTolReduction;
    if (cgTolFraction != null) _ptr.ref.cg_tol_fraction = cgTolFraction;
    if (cgPrecond != null) _ptr.ref.cg_precond = cgPrecond;
    if (adaptiveRho != null) _ptr.ref.adaptive_rho = adaptiveRho;
    if (adaptiveRhoInterval != null) {
      _ptr.ref.adaptive_rho_interval = adaptiveRhoInterval;
    }
    if (adaptiveRhoFraction != null) {
      _ptr.ref.adaptive_rho_fraction = adaptiveRhoFraction;
    }
    if (adaptiveRhoTolerance != null) {
      _ptr.ref.adaptive_rho_tolerance = adaptiveRhoTolerance;
    }
    if (maxIter != null) _ptr.ref.max_iter = maxIter;
    if (epsAbs != null) _ptr.ref.eps_abs = epsAbs;
    if (epsRel != null) _ptr.ref.eps_rel = epsRel;
    if (epsPrimInf != null) _ptr.ref.eps_prim_inf = epsPrimInf;
    if (epsDualInf != null) _ptr.ref.eps_dual_inf = epsDualInf;
    if (scaledTermination != null) {
      _ptr.ref.scaled_termination = scaledTermination ? 1 : 0;
    }
    if (checkTermination != null) _ptr.ref.check_termination = checkTermination;
    if (checkDualgap != null) _ptr.ref.check_dualgap = checkDualgap ? 1 : 0;
    if (timeLimit != null) _ptr.ref.time_limit = timeLimit;
    if (delta != null) _ptr.ref.delta = delta;
    if (polishRefineIter != null) {
      _ptr.ref.polish_refine_iter = polishRefineIter;
    }
  }

  /// Whether this settings instance has been disposed.
  bool get isDisposed => _ptr == ffi.nullptr;

  /// The underlying native [OSQPSettings] pointer.
  ///
  /// Throws [StateError] if this settings object has been disposed.
  ffi.Pointer<OSQPSettings> get pointer {
    if (isDisposed) {
      throw StateError('Cannot access Settings after disposal.');
    }
    return _ptr;
  }

  /// Direct access to all fields of the underlying native [OSQPSettings] struct.
  ///
  /// Throws [StateError] if this settings object has been disposed.
  OSQPSettings get ref => pointer.ref;

  /// Print solver progress to stdout.
  bool get verbose => ref.verbose != 0;
  set verbose(bool value) => ref.verbose = value ? 1 : 0;

  /// Maximum number of iterations.
  int get maxIter => ref.max_iter;
  set maxIter(int value) => ref.max_iter = value;

  /// Absolute solution tolerance.
  double get epsAbs => ref.eps_abs;
  set epsAbs(double value) => ref.eps_abs = value;

  /// Relative solution tolerance.
  double get epsRel => ref.eps_rel;
  set epsRel(double value) => ref.eps_rel = value;

  /// Polish ADMM solution.
  bool get polishing => ref.polishing != 0;
  set polishing(bool value) => ref.polishing = value ? 1 : 0;

  /// ADMM penalty parameter.
  double get rho => ref.rho;
  set rho(double value) => ref.rho = value;

  /// Warm start primal and dual variables.
  bool get warmStarting => ref.warm_starting != 0;
  set warmStarting(bool value) => ref.warm_starting = value ? 1 : 0;

  /// Number of data scaling iterations; if 0, then disabled.
  int get scaling => ref.scaling;
  set scaling(int value) => ref.scaling = value;

  /// ADMM penalty parameter.
  double get sigma => ref.sigma;
  set sigma(double value) => ref.sigma = value;

  /// ADMM relaxation parameter.
  double get alpha => ref.alpha;
  set alpha(double value) => ref.alpha = value;

  /// Primal infeasibility tolerance.
  double get epsPrimInf => ref.eps_prim_inf;
  set epsPrimInf(double value) => ref.eps_prim_inf = value;

  /// Dual infeasibility tolerance.
  double get epsDualInf => ref.eps_dual_inf;
  set epsDualInf(double value) => ref.eps_dual_inf = value;

  /// Maximum time to solve the problem in seconds.
  double get timeLimit => ref.time_limit;
  set timeLimit(double value) => ref.time_limit = value;

  /// Cleans up native settings resources.
  ///
  /// Safe to call multiple times.
  void dispose() {
    if (_ptr == ffi.nullptr) return;
    _finalizer.detach(this);
    OSQPSettings_free(_ptr);
    _ptr = ffi.nullptr;
  }
}
