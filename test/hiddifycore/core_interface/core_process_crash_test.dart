import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/hiddifycore/core_interface/core_process.dart';

void main() {
  group('CoreProcess.crashHeadline', () {
    test('finds the panic line of a Go crash (hiddify-app#2517)', () {
      const output = '''
hiddify core: something before
panic: runtime error: invalid memory address or nil pointer dereference
[signal 0xc0000005 code=0x0 addr=0x0 pc=0x7ff6]

goroutine 42 [running]:
github.com/sagernet/sing-box/route.(*Router).Start(...)
''';
      expect(
        CoreProcess.crashHeadline(output),
        'panic: runtime error: invalid memory address or nil pointer dereference',
      );
    });

    test('finds a fatal error', () {
      expect(
        CoreProcess.crashHeadline('fatal error: concurrent map writes\n\ngoroutine 1 [running]:'),
        'fatal error: concurrent map writes',
      );
    });

    test('falls back to the signal line', () {
      expect(CoreProcess.crashHeadline('SIGSEGV: segmentation violation\nPC=0x0'), 'SIGSEGV: segmentation violation');
    });

    test('is null without a crash', () {
      expect(CoreProcess.crashHeadline(''), isNull);
      expect(CoreProcess.crashHeadline('hiddify core: stopping (signal interrupt)'), isNull);
    });

    test('shortens a long line', () {
      final headline = CoreProcess.crashHeadline('panic: ${'x' * 1000}')!;
      expect(headline.length, lessThan(310));
      expect(headline, endsWith('…'));
    });
  });
}
