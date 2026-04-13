class SessionService {
  static Map<String, dynamic>? _session;

  static Map<String, dynamic>? get session => _session;

  static String? get accessToken => _session?['access_token']?.toString();

  static Map<String, dynamic>? get currentUser {
    final user = _session?['user'];
    return user is Map<String, dynamic> ? user : null;
  }

  static bool get isAuthenticated =>
      accessToken != null && accessToken!.isNotEmpty;

  static void setSession(Map<String, dynamic> session) {
    _session = Map<String, dynamic>.from(session);
  }

  static void updateCurrentUserFields(Map<String, dynamic> fields) {
    final currentSession = _session;
    final currentUser = currentSession?['user'];

    if (currentSession == null || currentUser is! Map<String, dynamic>) {
      return;
    }

    _session = {
      ...currentSession,
      'user': {...currentUser, ...fields},
    };
  }

  static void clearSession() {
    _session = null;
  }
}
