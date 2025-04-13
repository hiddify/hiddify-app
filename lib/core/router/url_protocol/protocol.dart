abstract class ProtocolHandler {
  void register(String scheme, {String? executable, List<String>? arguments});

  void unregister(String scheme);

  List<String> getArguments(List<String>? arguments) {
    if (arguments == null) return ['%s'];

    if (arguments.isEmpty && !arguments.any((e) => e.contains('%s'))) {
      throw ArgumentError('arguments must contain at least 1 instance of "%s"');
    }

    return arguments;
  }
}
