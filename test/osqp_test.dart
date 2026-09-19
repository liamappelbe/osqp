import 'package:osqp/osqp.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });

    test('OSQP native library is loaded and returns version', () {
      final version = osqpVersion();
      expect(version, isNotEmpty);
      expect(version, startsWith('1.'));
    });
  });
}
