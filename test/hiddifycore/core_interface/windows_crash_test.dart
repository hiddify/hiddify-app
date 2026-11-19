import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/hiddifycore/core_interface/core_process.dart';
import 'package:hiddify/hiddifycore/core_interface/windows_crash.dart';

// An Application Error event as wevtutil prints it (/f:xml), its data unnamed as on Windows 10/11.
String _event({required String pid, String module = 'cronet.dll', String code = 'c0000005'}) => '''
<Event xmlns='http://schemas.microsoft.com/win/2004/08/events/event'><System><Provider Name='Application Error'/><EventID>1000</EventID></System><EventData><Data>HiddifyCore.exe</Data><Data>5.9.8.0</Data><Data>6735f2a1</Data><Data>$module</Data><Data>140.0.7339.0</Data><Data>67359f00</Data><Data>$code</Data><Data>0x00000000012ab3c4</Data><Data>$pid</Data><Data>0x1db38a1c2f0e4a1</Data><Data>C:\\Program Files\\Hiddify\\HiddifyCore.exe</Data><Data>C:\\Program Files\\Hiddify\\cronet.dll</Data><Data>3f2b8d1e</Data><Data></Data><Data></Data></EventData></Event>''';

void main() {
  // a native crash on a thread of a DLL left no Go crash output, only the exit code (#2517)
  test("the crash event of the core's own process is its reason", () {
    final xml = _event(pid: '0x10a4', module: 'wintun.dll') + _event(pid: '0x2b10');
    expect(
      WindowsCrash.applicationErrorFor(xml, 0x2b10),
      'a native crash in cronet.dll (exception 0xc0000005, access violation at offset 0x00000000012ab3c4)',
    );
    expect(WindowsCrash.applicationErrorFor(xml, 0x10a4), contains('wintun.dll'));
    expect(WindowsCrash.applicationErrorFor(xml, 0x999), isNull, reason: "another process's crash is not this one's");
  });

  test('an exit code says what ended the process', () {
    expect(WindowsCrash.describeExitCode(-1073741819), 'ended by Windows: access violation (0xc0000005)');
    expect(WindowsCrash.describeExitCode(-1073740791), contains('fail-fast'));
    expect(WindowsCrash.describeExitCode(1), contains('another program'));
    expect(WindowsCrash.describeExitCode(0), isNull);
  });

  // Go's own report of a Windows exception in C code on a Go thread was not read as a crash
  test("Go's Windows exception report is a crash headline", () {
    expect(
      CoreProcess.crashHeadline('Exception 0xc0000005 0x0 0x7ff8 0x7ff8\nPC=0x7ff812345678\n\nruntime.cgocall(...)'),
      'Exception 0xc0000005 0x0 0x7ff8 0x7ff8',
    );
  });
}
