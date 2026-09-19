import 'dart:ffi';

import 'package:ffi/ffi.dart';

export 'src/osqp_base.dart';

@Native<Pointer<Utf8> Function()>(symbol: 'osqp_version')
external Pointer<Utf8> _osqpVersion();

/// Returns the OSQP library version string.
String osqpVersion() => _osqpVersion().toDartString();
