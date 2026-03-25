import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/backend_config.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class UserCredential {
  const UserCredential({required this.user});

  final AuthUser? user;
}

class BackendSession {
  const BackendSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class FirebaseAuthService {
  FirebaseAuthService(this._ref) {
    unawaited(_restoreSession());
  }

  static const _tokenKey = 'backend_auth_token';
  static const _userKey = 'backend_auth_user';

  final Ref _ref;
  final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();

  bool _googleInitialized = false;
  BackendSession? _currentSession;
  bool _restored = false;

  Stream<AuthUser?> authStateChanges() async* {
    if (!_restored) {
      await _restoreSession();
    }
    yield _currentSession?.user;
    yield* _authController.stream;
  }

  AuthUser? get currentUser => _currentSession?.user;
  String? get currentSessionToken => _currentSession?.token;

  Future<void> _restoreSession() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (token == null || rawUser == null) {
      _authController.add(null);
      return;
    }
    try {
      final map = jsonDecode(rawUser) as Map<String, dynamic>;
      _currentSession = BackendSession(
        token: token,
        user: AuthUser(
          uid: map['uid'] as String? ?? '',
          email: map['email'] as String? ?? '',
        ),
      );
      _authController.add(_currentSession!.user);
    } catch (_) {
      await signOut();
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google token alinamadi.');
    }
    final session = await _sendAuthRequest(
      '/auth/google',
      body: {'idToken': idToken},
    );
    return UserCredential(user: session.user);
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final session = await _sendAuthRequest(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return UserCredential(user: session.user);
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final session = await _sendAuthRequest(
      '/auth/register',
      body: {'email': email, 'password': password},
    );
    return UserCredential(user: session.user);
  }

  Future<void> signOut() async {
    _currentSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
    _authController.add(null);
  }

  Future<BackendSession> _sendAuthRequest(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final config = _ref.read(backendConfigProvider);
    final response = await http.post(
      Uri.parse('${config.baseUrl}$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Future<BackendSession>.error(
          StateError(decoded['error'] as String? ?? 'Auth istegi basarisiz.'),
        );
      } catch (_) {
        throw StateError('Auth istegi basarisiz.');
      }
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['token'] as String? ?? '';
    final userMap = decoded['user'] as Map<String, dynamic>? ?? const {};
    final session = BackendSession(
      token: token,
      user: AuthUser(
        uid: userMap['id'] as String? ?? '',
        email: userMap['email'] as String? ?? '',
      ),
    );
    _currentSession = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(
      _userKey,
      jsonEncode({'uid': session.user.uid, 'email': session.user.email}),
    );
    _authController.add(session.user);
    return session;
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(ref),
);

final firebaseAuthUserProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges();
});

final currentFirebaseUserProvider = Provider<AuthUser?>((ref) {
  final authUser = ref.watch(firebaseAuthUserProvider);
  return authUser.value ?? ref.watch(firebaseAuthServiceProvider).currentUser;
});
