import 'dart:async';
import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/utils/utils.dart';

/// استراتژی retry هوشمند با exponential backoff و jitter
/// برای جلوگیری از thundering herd problem
class ConnectionRetryStrategy with InfraLogger {
  static const int maxRetries = 5;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(minutes: 5);
  
  final _random = Random();

  /// اجرای یک action با retry logic
  /// 
  /// در صورت شکست، با exponential backoff و jitter دوباره تلاش می‌کند
  /// maxRetries بار تلاش می‌کند و در صورت شکست نهایی، آخرین error را برمی‌گرداند
  Future<Either<L, R>> executeWithRetry<L, R>(
    Future<Either<L, R>> Function() action, {
    int maxRetries = maxRetries,
    Duration baseDelay = baseDelay,
    bool Function(L)? shouldRetry,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      loggy.debug('Connection attempt ${attempt + 1}/$maxRetries');
      
      final result = await action();
      
      if (result.isRight()) {
        if (attempt > 0) {
          loggy.info('Connection succeeded on attempt ${attempt + 1}');
        }
        return result;
      }
      
      // بررسی اینکه آیا باید retry کنیم
      if (shouldRetry != null) {
        final error = result.getLeft().toNullable();
        if (error != null && !shouldRetry(error)) {
          loggy.warning('Error is not retryable, aborting: $error');
          return result;
        }
      }
      
      attempt++;
      
      if (attempt >= maxRetries) {
        loggy.error('All $maxRetries connection attempts failed');
        return result;
      }
      
      final delay = _calculateDelay(attempt, baseDelay);
      loggy.debug('Waiting ${delay.inMilliseconds}ms before next attempt');
      await Future.delayed(delay);
    }
    
    // این خط هرگز نباید اجرا شود، اما برای type safety لازم است
    throw StateError('Unreachable code in executeWithRetry');
  }
  
  /// محاسبه delay با exponential backoff و jitter
  Duration _calculateDelay(int attempt, Duration baseDelay) {
    // Exponential backoff: baseDelay * 2^attempt
    final exponentialDelay = baseDelay * (1 << attempt);
    
    // اضافه کردن jitter برای جلوگیری از thundering herd
    // jitter between 0 to 1000ms
    final jitter = Duration(milliseconds: _random.nextInt(1000));
    
    final totalDelay = exponentialDelay + jitter;
    
    // محدود کردن به maxDelay
    return totalDelay > maxDelay ? maxDelay : totalDelay;
  }
  
  /// بررسی اینکه آیا باید auto-reconnect انجام شود
  /// بر اساس تاریخچه اتصال و disconnect های اخیر
  bool shouldAutoReconnect(List<ConnectionEvent> recentEvents) {
    if (recentEvents.isEmpty) return true;
    
    final now = DateTime.now();
    final last30Minutes = now.subtract(const Duration(minutes: 30));
    
    // تعداد disconnect های اخیر
    final recentDisconnects = recentEvents
        .where((e) => e.type == ConnectionEventType.disconnected)
        .where((e) => e.timestamp.isAfter(last30Minutes))
        .length;
    
    // اگر در 30 دقیقه گذشته بیش از 5 بار disconnect شده، auto-reconnect نکن
    if (recentDisconnects > 5) {
      loggy.warning('Too many disconnects ($recentDisconnects in 30 min), disabling auto-reconnect');
      return false;
    }
    
    return true;
  }
}

/// رویداد اتصال برای نگهداری تاریخچه
class ConnectionEvent {
  final ConnectionEventType type;
  final DateTime timestamp;
  final String? reason;
  
  ConnectionEvent(this.type, this.timestamp, [this.reason]);
  
  @override
  String toString() => 'ConnectionEvent($type at $timestamp${reason != null ? ": $reason" : ""})';
}

enum ConnectionEventType {
  connected,
  disconnected,
  connecting,
  error,
}
