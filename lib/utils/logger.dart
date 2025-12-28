import 'package:flutter/foundation.dart';

/// Enhanced logging utility that only prints in debug mode
///
/// This prevents logs from showing in production builds while
/// keeping them in development for debugging purposes.
/// Enhanced to better handle object serialization and special characters.
class Logger {
  static const String _tag = '[MedEquip]';

  /// Log info level message
  static void info(String message) {
    _log('INFO', message);
  }

  /// Log debug level message with optional object for inspection
  static void debug(String message, [Object? data]) {
    _log('DEBUG', message);
    if (data != null) {
      _logData('DEBUG', data);
    }
  }

  /// Log warning level message
  static void warn(String message, [Object? data]) {
    _log('WARN', message);
    if (data != null) {
      _logData('WARN', data);
    }
  }

  /// Log error level message with optional exception and stack trace
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      _logData('ERROR', {
        'exception': error.toString(),
        'type': error.runtimeType.toString(),
      });
    }
    if (stackTrace != null && kDebugMode) {
      // ignore: avoid_print
      print('$_tag [ERROR] Stack trace: $stackTrace');
    }
  }

  /// Internal logging method for messages
  static void _log(String level, String message) {
    // Only print in debug mode
    if (kDebugMode) {
      // ignore: avoid_print
      print('$_tag [$level] ${_safeString(message)}');
    }
  }

  /// Internal logging method for structured data
  static void _logData(String level, Object? data) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('$_tag [$level] DATA: ${_safeString(data.toString())}');
    }
  }

  /// Makes string safer for logging by escaping special characters
  static String _safeString(String text) {
    // Ensure we show control characters and whitespace clearly
    return text
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
