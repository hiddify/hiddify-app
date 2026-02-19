import 'package:hiddify/core/router/deep_linking/url_protocol/windows_protocol.dart'
    if (dart.library.js_interop) 'web_url_protocol.dart';

/// Registers a protocol by [scheme] to allow for links in the form `<scheme>://...`
/// to be processed by this application. By default, opening a link will open
/// the executable that was used to register the scheme with the URL as the first
/// argument passed to the executable.
///
/// If a protocol is already registered for the given scheme, this function will
/// attempt to overwrite the previous handler with the current executable information.
/// However, note that depending on process permissions, this operation may be
/// disallowed by the underlying platform.
///
/// You may pass an [executable] to override the path to the executable to run
/// when accessing the URL.
///
/// [arguments] is a list of arguments to be used when running the executable.
/// If passed, the list must contain at least one element, and at least one of
/// those elements must contain the literal value `%s` to denote the URL to open.
/// Quoting arguments is not necessary, as this will be handled for you.
/// Escaping the `%s` as an unprocessed literal is currently unsupported.
void registerProtocolHandler(String scheme, {String? executable, List<String>? arguments}) {
  WindowsProtocolHandler().register(scheme, executable: executable, arguments: arguments);
}

/// Unregisters the protocol handler with the underlying platform. The provided
/// [scheme] will no longer be used in links.
///
/// Note that this will unregister a protocol by scheme regardless of which process
/// had registered it. Unregistering a scheme that was not registered by this
/// application is undefined and depends on platform-specific restrictions.
void unregisterProtocolHandler(String scheme) {
  WindowsProtocolHandler().unregister(scheme);
}
