import 'package:flutter/foundation.dart';

class Logger {
  const Logger._();

  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    debugPrint('[WARN] $message');
  }

  static void error(String message) {
    debugPrint('[ERROR] $message');
  }
}
