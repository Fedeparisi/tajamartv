import 'dart:html' as html;

Future<bool> checkUrlOnline(String url) async {
  try {
    // Web fetch with no-cors to bypass browser CORS blockages for status checks
    final promise = html.window.fetch(url, {'mode': 'no-cors', 'method': 'GET'});
    await promise;
    return true; // if no error, the request reached the server
  } catch (_) {
    return false;
  }
}
