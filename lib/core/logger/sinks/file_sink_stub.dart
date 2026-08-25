/// web build — there is no file system, so every call does nothing
void openLogFile(String path) {}

void writeLogLine(String line) {}

bool get isLogFileOpen => false;

Future<void> closeLogFile() async {}

Future<void> flushLogFile() async {}

Future<void> writeLinesToFile(String path, Iterable<String> lines) async {}
