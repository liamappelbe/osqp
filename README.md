# package:osqp

Dart FFI bindings for [OSQP](https://github.com/osqp/OSQP) (Operator Splitting
Quadratic Program) solver.

OSQP is a numerical optimization package for solving convex
[quadratic programs](https://en.wikipedia.org/wiki/Quadratic_programming).
Quadratic programming is a superset of linear programming, so this solver can
also handle linear programming problems.

For more information, see the [OSQP documentation](https://osqp.org/).

## Usage

See [example/osqp_example.dart](example/osqp_example.dart) for a complete
working example. To run the example:

```console
dart run example/osqp_example.dart
```

## Building

This package uses Dart build hooks to build the native OSQP C library using
CMake. This should work entirely automatically, as long as you have these tools
installed:

- CMake (version 3.18 or newer)
- A C/C++ compiler toolchain (e.g., GCC, Clang, or MSVC)
