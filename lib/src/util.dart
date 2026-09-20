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

import 'osqp_bindings.g.dart';

/// Returns the OSQP library version string.
String get osqpVersion => osqp_version().cast<Utf8>().toDartString();

/// Returns an integer representing the OSQP library capabilities.
int get osqpCapabilities => osqp_capabilities();

/// Utility extensions on [OSQPInfo].
extension OsqpInfoExtensions on OSQPInfo {
  /// Exit status string representation.
  String get statusString {
    final codeUnits = <int>[];
    for (var i = 0; i < 32; i++) {
      final c = status[i];
      if (c == 0) break;
      codeUnits.add(c);
    }
    return String.fromCharCodes(codeUnits);
  }
}

/// Exception thrown when an OSQP API call fails.
class OsqpException implements Exception {
  /// OSQP numeric error code.
  final int errorCode;

  /// Descriptive error message.
  final String message;

  OsqpException(this.errorCode, [String? message])
    : message = message ?? _lookupMessage(errorCode);

  static String _lookupMessage(int code) {
    if (code == 0) return 'No error';
    if (code < 0 || code >= osqp_error_type.OSQP_LAST_ERROR_PLACE.value) {
      return 'Unknown OSQP error ($code)';
    }
    try {
      final ptr = osqp_error_message(code);
      if (ptr != ffi.nullptr) {
        return ptr.cast<Utf8>().toDartString();
      }
    } catch (_) {}
    return 'Unknown OSQP error ($code)';
  }

  @override
  String toString() => 'OsqpException: $message (code $errorCode)';
}

/// Allocates and copies a [List<double>] to native [OSQPFloat] array memory using [allocator].
ffi.Pointer<OSQPFloat> copyFloatList(
  ffi.Allocator allocator,
  List<double>? list,
) {
  if (list == null) return ffi.nullptr;
  final ptr = allocator<OSQPFloat>(list.length);
  for (var i = 0; i < list.length; i++) {
    ptr[i] = list[i];
  }
  return ptr;
}

/// Allocates and copies a [List<int>] to native [OSQPInt] array memory using [allocator].
ffi.Pointer<OSQPInt> copyIntList(ffi.Allocator allocator, List<int>? list) {
  if (list == null) return ffi.nullptr;
  final ptr = allocator<OSQPInt>(list.length);
  for (var i = 0; i < list.length; i++) {
    ptr[i] = list[i];
  }
  return ptr;
}
