// ignore_for_file: avoid_print

class AppLogger {
  static void d(String tag, String message) {
    print('DEBUG: $tag - $message');
  }

  static void i(String tag, String message) {
    print('INFO: $tag - $message');
  }

  static void w(String tag, String message) {
    print('WARNING: $tag - $message');
  }

  static void e(String tag, String message) {
    print('ERROR: $tag - $message');
  }
}
