// api_key_helper.dart (for non-web platforms)
// Loads API key from a local `.env` file (for development) or from
// compile-time defines. For production, prefer a secure secrets flow.

import 'package:flutter_dotenv/flutter_dotenv.dart';

bool _envLoaded = false;

/// Load the `.env` file. Call this early in `main()` before `runApp()`:
///
/// ```dart
/// await loadEnv();
/// runApp(const MyApp());
/// ```
Future<void> loadEnv() async {
  if (_envLoaded) return;
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Ignore load errors; we'll fall back to dart-define or throw later.
  }
  _envLoaded = true;
}

/// Returns the `GEMINI_API_KEY` value.
///
/// Priority: `.env` (if loaded) -> `--dart-define` compile-time value.
String getApiKey() {
  final fromDotenv = dotenv.env['GEMINI_API_KEY'];
  if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

  const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
  if (fromDefine.isNotEmpty) return fromDefine;

  throw Exception(
      'GEMINI_API_KEY is not set. Call loadEnv() at startup and ensure .env contains GEMINI_API_KEY, or run with --dart-define=GEMINI_API_KEY=YOUR_API_KEY');
}