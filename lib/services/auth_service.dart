import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.verified,
  });

  final String uid;
  final String email;
  final String name;
  final bool verified;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// One interface, two implementations:
///  * [FirebaseAuthService]  real accounts + real verification e-mails
///  * [DemoAuthService]      on-device simulation so the app runs instantly
abstract class AuthService {
  /// true  = user types a code (demo). false = user taps a link in an e-mail.
  bool get usesCodeEntry;

  /// Demo mode only: the code that a real e-mail would have contained.
  String? get demoCode;

  Future<AuthUser?> currentUser();
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthUser> signIn({required String email, required String password});
  Future<void> sendVerification();
  Future<bool> checkVerified();
  Future<bool> submitCode(String code);
  Future<void> sendPasswordReset(String email);

  /// Removes an unverified account so the person can start over
  /// (for example after mistyping their e-mail).
  Future<void> discardUnverified();
  Future<void> signOut();
}

// ───────────────────────── Firebase (real) ─────────────────────────

class FirebaseAuthService implements AuthService {
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  @override
  bool get usesCodeEntry => false;

  @override
  String? get demoCode => null;

  AuthUser? _map(fb.User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: (u.email ?? '').toLowerCase(),
          name: u.displayName ?? '',
          verified: u.emailVerified,
        );

  @override
  Future<AuthUser?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    try {
      await u.reload();
    } on fb.FirebaseAuthException catch (e) {
      // Account deleted or disabled elsewhere: drop the stale session.
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'user-token-expired') {
        await _auth.signOut();
        return null;
      }
      // Offline etc.: keep the cached session.
    } catch (_) {}
    return _map(_auth.currentUser);
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);
      await user.sendEmailVerification();
      await user.reload();
      return _map(_auth.currentUser)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _map(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> sendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<bool> checkVerified() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<bool> submitCode(String code) async => false;

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      // Do not reveal whether an account exists.
      if (e.code == 'user-not-found') return;
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> discardUnverified() async {
    final u = _auth.currentUser;
    try {
      if (u != null && !u.emailVerified) {
        await u.delete();
        return;
      }
    } catch (_) {
      // requires-recent-login etc. Fall through to a plain sign-out.
    }
    await _auth.signOut();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _message(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'invalid-email':
        return "That doesn't look like a valid email address.";
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Contact IT Support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled in Firebase yet (see README).';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }
}

// ───────────────────────── Demo (on-device) ─────────────────────────

/// Simulates accounts on the phone. NO real e-mail is sent and passwords are
/// only lightly hashed: this exists so you can try the whole flow instantly.
class DemoAuthService implements AuthService {
  DemoAuthService(this._prefs);

  final SharedPreferences _prefs;
  static const _kUsers = 'demo_users';
  static const _kSession = 'demo_session';

  String? _code;

  @override
  bool get usesCodeEntry => true;

  @override
  String? get demoCode => _code;

  Map<String, dynamic> _users() {
    final raw = _prefs.getString(_kUsers);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveUsers(Map<String, dynamic> users) =>
      _prefs.setString(_kUsers, jsonEncode(users));

  String _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  AuthUser _toUser(String email, Map<String, dynamic> u) => AuthUser(
        uid: email,
        email: email,
        name: (u['name'] as String?) ?? '',
        verified: (u['verified'] as bool?) ?? false,
      );

  void _newCode() => _code = (Random.secure().nextInt(900000) + 100000).toString();

  @override
  Future<AuthUser?> currentUser() async {
    final email = _prefs.getString(_kSession);
    if (email == null) return null;
    final u = _users()[email];
    if (u == null) return null;
    return _toUser(email, Map<String, dynamic>.from(u as Map));
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final users = _users();
    if (users.containsKey(email)) {
      throw AuthException(
          'An account with this email already exists. Try signing in.');
    }
    users[email] = {'name': name, 'pass': _hash(password), 'verified': false};
    await _saveUsers(users);
    await _prefs.setString(_kSession, email);
    _newCode();
    return _toUser(email, Map<String, dynamic>.from(users[email] as Map));
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final raw = _users()[email];
    if (raw == null) throw AuthException('Incorrect email or password.');
    final u = Map<String, dynamic>.from(raw as Map);
    if (u['pass'] != _hash(password)) {
      throw AuthException('Incorrect email or password.');
    }
    await _prefs.setString(_kSession, email);
    final user = _toUser(email, u);
    if (!user.verified) _newCode();
    return user;
  }

  @override
  Future<void> sendVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _newCode();
  }

  @override
  Future<bool> checkVerified() async {
    final u = await currentUser();
    return u?.verified ?? false;
  }

  @override
  Future<bool> submitCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final email = _prefs.getString(_kSession);
    if (email == null || _code == null || code.trim() != _code) return false;
    final users = _users();
    final u = Map<String, dynamic>.from(users[email] as Map);
    u['verified'] = true;
    users[email] = u;
    await _saveUsers(users);
    _code = null;
    return true;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> discardUnverified() async {
    final email = _prefs.getString(_kSession);
    if (email != null) {
      final users = _users();
      final u = users[email];
      if (u is Map && u['verified'] != true) {
        users.remove(email);
        await _saveUsers(users);
      }
    }
    await signOut();
  }

  @override
  Future<void> signOut() async {
    _code = null;
    await _prefs.remove(_kSession);
  }
}
