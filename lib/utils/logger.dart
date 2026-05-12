import 'package:flutter/foundation.dart';

class AiLogger {
  static void request(String modelName, String text) {
    debugPrint('[AI] model: $modelName');
    debugPrint('[AI] → REQUEST: "$text"');
  }

  static void response(int chunkCount, int charCount, String preview) {
    debugPrint('[AI] ← RESPONSE: $chunkCount chunks, $charCount chars');
    // debugPrint truncates at ~1024 chars, so chunk the output
    const tag = '[AI] ← BODY: ';
    const chunkSize = 800;
    for (int i = 0; i < preview.length; i += chunkSize) {
      debugPrint('$tag${preview.substring(i, (i + chunkSize).clamp(0, preview.length))}');
    }
  }

  static void error(Object e) {
    debugPrint('[AI] ✗ ERROR: $e');
  }

  static void retrying(int attempt, Duration delay) {
    debugPrint('[AI] ⟳ QUOTA hit — retrying in ${delay.inSeconds}s (attempt $attempt)');
  }
}

/// Runs [fn] with exponential backoff when a quota/rate-limit error is thrown.
/// Retries up to [maxAttempts] times, starting with [initialDelay].
Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 10),
}) async {
  Duration delay = initialDelay;
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      final isQuota = e.toString().contains('quota') ||
          e.toString().contains('RESOURCE_EXHAUSTED') ||
          e.toString().contains('429');
      if (!isQuota || attempt == maxAttempts) rethrow;
      AiLogger.retrying(attempt, delay);
      await Future.delayed(delay);
      delay *= 2;
    }
  }
  // unreachable
  throw StateError('withRetry exhausted');
}
