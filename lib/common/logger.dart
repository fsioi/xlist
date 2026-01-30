import 'package:flutter/foundation.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical
}

/// 日志工具类
class Logger {
  /// 是否启用调试日志
  static bool _debugEnabled = kDebugMode;

  /// 设置是否启用调试日志
  static void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }

  /// 调试日志
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_debugEnabled) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  /// 信息日志
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// 警告日志
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// 错误日志
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// 严重错误日志
  static void c(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  /// 实际日志输出
  static void _log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelString = _levelToString(level);
    
    String logMessage = '[${timestamp}] [${levelString}] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStackTrace: $stackTrace';
    }
    
    // 根据日志级别选择输出方式
    switch (level) {
      case LogLevel.debug:
        debugPrint(logMessage);
        break;
      case LogLevel.info:
        if (kDebugMode) {
          print(logMessage);
        }
        break;
      case LogLevel.warning:
      case LogLevel.error:
      case LogLevel.critical:
        // 错误级别的日志在生产环境也需要输出
        print(logMessage);
        // 这里可以添加其他错误处理逻辑，比如上报到错误跟踪服务
        break;
    }
  }

  /// 将日志级别转换为字符串
  static String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
      default:
        return 'UNKNOWN';
    }
  }
}

/// 错误处理工具类
class ErrorHandler {
  /// 处理异常
  /// [context] 错误上下文
  /// [e] 异常对象
  /// [s] 堆栈跟踪
  /// [showToast] 是否显示 Toast 提示
  static void handleError(String context, dynamic e, [StackTrace? s, bool showToast = true]) {
    Logger.e('$context: $e', e, s);
    
    // 这里可以添加更多错误处理逻辑，比如：
    // 1. 根据错误类型显示不同的提示信息
    // 2. 上报错误到监控服务
    // 3. 记录错误到本地存储
    
    if (showToast) {
      // 这里可以集成 SmartDialog 或其他 Toast 库
      // SmartDialog.showToast('操作失败: $e');
    }
  }

  /// 处理 WebDAV 错误
  static String handleWebDAVError(dynamic error) {
    if (error is Map && error.containsKey('message')) {
      return error['message'];
    }
    return error.toString();
  }

  /// 处理网络错误
  static String handleNetworkError(dynamic error) {
    // 这里可以根据不同的网络错误类型返回不同的错误信息
    return '网络连接失败: $error';
  }

  /// 处理数据库错误
  static String handleDatabaseError(dynamic error) {
    return '数据库操作失败: $error';
  }
}
