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

// This header only exists to satisfy the `#include "osqp_configure.h"`
// directive in OSQP headers during FFIgen code generation, and is not used
// during CMake builds (since CMake generates its own configuration header in
// the build directory).

#ifndef OSQP_CONFIGURE_H
#define OSQP_CONFIGURE_H

#ifndef FFIGEN
#error "osqp_configure.h should only be included during FFIgen code generation"
#endif

/* OSQP_USE_LONG */
#define OSQP_USE_LONG

#endif /* ifndef OSQP_CONFIGURE_H */
