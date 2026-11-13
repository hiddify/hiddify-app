import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/crash_report/widget/crash_report_dialog.dart';

void main() {
  const crash = (
    headline: 'panic: runtime error: index out of range [3] with length 3',
    text: 'panic: runtime error: index out of range [3] with length 3\n\ngoroutine 7 [running]:\nmain.f()',
  );

  test('a crash fills the title, the problem and the log field from the exception', () {
    final url = githubIssueUrl(
      description: '',
      crash: crash,
      version: '5.9.1 (59100) general',
      platform: 'Android',
      os: 'Android 16',
    );
    final query = url.queryParameters;
    expect(url.path, '/hiddify/hiddify-app/issues/new');
    expect(query['template'], 'bug_report.yaml');
    expect(query['title'], '[Crash]: panic: runtime error: index out of range [3] with length 3');
    expect(query['problem'], 'Hiddify crashed: ${crash.headline}');
    expect(query['logs'], crash.text);
    expect(query['platform'], 'Android');
    expect(query['os'], 'Android 16');
    expect(query['version'], '5.9.1 (59100) general');
    // well under the 8 KB GitHub takes in a link
    expect(url.toString().length, lessThan(8000));
  });

  test("the user's words come first, the crash still goes in the log field", () {
    final query = githubIssueUrl(
      description: 'It closed when I connected\nto the second server',
      crash: crash,
      version: null,
      platform: null,
      os: 'macOS 26',
    ).queryParameters;
    expect(query['title'], '[Crash]: It closed when I connected');
    expect(query['problem'], 'It closed when I connected\nto the second server');
    expect(query['logs'], crash.text);
    expect(query.containsKey('platform'), isFalse);
  });

  test('a problem without a crash has no log field', () {
    final query = githubIssueUrl(
      description: 'slow',
      crash: null,
      version: null,
      platform: 'iOS',
      os: 'iOS 26',
    ).queryParameters;
    expect(query['title'], '[Bug]: slow');
    expect(query.containsKey('logs'), isFalse);
  });
}
