# package:osqp

[![pub package](https://img.shields.io/pub/v/osqp.svg)](https://pub.dev/packages/osqp)
[![Build Status](https://github.com/liamappelbe/osqp/workflows/CI/badge.svg)](https://github.com/liamappelbe/osqp/actions?query=workflow%3ACI+branch%3Amain)

Dart bindings for the [OSQP](https://osqp.org/) (Operator Splitting Quadratic
Program) solver.

OSQP is a numerical optimization package for solving convex
[quadratic programs](https://en.wikipedia.org/wiki/Quadratic_programming).
Quadratic programming is a superset of linear programming, so this solver can
also handle linear programming problems.

Loads of real world optimisation problems can be formulated as linear or
quadratic programming problems. For example, I wrote this package so that I
could use OSQP to optimise my home solar panel and battery.

## Features

- **High-level Dart API**: Idiomatic wrappers around OSQP's C API. For example,
  the C `OSQPSolver` is wrapped by the Dart `Solver`, and `OSQPCscMatrix` is
  wrapped by `Matrix`.
- **Automatic Memory Management**: Memory is freed automatically via
  `NativeFinalizer`s.
- **Cross-Platform Build Hooks**: Automated native compilation using Dart build
  hooks on Linux, MacOS, and Windows (probably works on iOS and Android too,
  but I haven't tested it).
- **Raw FFI Access**: You can also use the FFI bindings directly if you need
  low level access.

## Usage

See [example/osqp_example.dart](example/osqp_example.dart) for a complete
working example. For more information, check out the [OSQP](https://osqp.org/)
documentation.

## Building

This package uses Dart build hooks to build the native OSQP C library using
CMake. This works automatically, provided you have installed:

- CMake (version 3.18 or newer)
- A C/C++ compiler toolchain (e.g., GCC, Clang, or MSVC)
