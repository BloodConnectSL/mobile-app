import 'dart:async';

/// In-memory bearer token. Persisted credentials are handled by SessionService.
class AuthStore {
  static String? token;
  static final expired = StreamController<void>.broadcast();
  static void expire() {
    if (token == null) return;
    token = null;
    expired.add(null);
  }
}
