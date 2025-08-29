import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  const AuthUser({
    required this.userId,
    this.displayName,
    this.email,
    this.avatarUrl,
  });
}

class AuthService extends ChangeNotifier {
  static const _keyIsLoggedIn = 'auth_is_logged_in';
  static const _keyUserId = 'auth_user_id';
  static const _keyDisplayName = 'auth_display_name';
  static const _keyEmail = 'auth_email';
  static const _keyAvatarUrl = 'auth_avatar_url';

  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'email',
    'profile',
  ]);

  AuthService() {
    _loadFromStorage();
  }

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;



  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return;
    final userId = prefs.getString(_keyUserId);
    if (userId == null) return;
    _currentUser = AuthUser(
      userId: userId,
      displayName: prefs.getString(_keyDisplayName),
      email: prefs.getString(_keyEmail),
      avatarUrl: prefs.getString(_keyAvatarUrl),
    );
    notifyListeners();
  }

  Future<void> _saveToStorage(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, user.userId);
    await prefs.setString(_keyDisplayName, user.displayName ?? '');
    await prefs.setString(_keyEmail, user.email ?? '');
    await prefs.setString(_keyAvatarUrl, user.avatarUrl ?? '');
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyAvatarUrl);
    _currentUser = null;
    notifyListeners();
  }

  Future<AuthUser?> signInWithGoogle({bool forceAccountPicker = false}) async {
    try {
      // Ensure Firebase is inited
      try { await fb.FirebaseAuth.instance.authStateChanges().first.timeout(const Duration(milliseconds: 1)); } catch (_) {}
      if (forceAccountPicker) {
        // Ensure previous session is cleared to always show account picker
        try { await _googleSignIn.signOut(); } catch (_) {}
        _googleSignIn = GoogleSignIn(scopes: ['email','profile']);
      }
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // cancelled
      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final result = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = result.user;
      final user = AuthUser(
        userId: fbUser?.uid ?? account.id,
        displayName: fbUser?.displayName ?? account.displayName,
        email: fbUser?.email ?? account.email,
        avatarUrl: fbUser?.photoURL ?? account.photoUrl,
      );
      _currentUser = user;
      await _saveToStorage(user);
      notifyListeners();
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in failed: $e');
      }
      return null;
    }
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    try {
      // Sign in with email and password
      final userCredential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Failed to sign in user');
      }

      // Create user object
      final user = AuthUser(
        userId: fbUser.uid, 
        displayName: fbUser.displayName ?? email.split('@').first, 
        email: fbUser.email
      );
      
      _currentUser = user;
      await _saveToStorage(user);
      notifyListeners();
      return user;
      
    } catch (e) {
      if (kDebugMode) {
        print('Sign in failed: $e');
      }
      rethrow;
    }
  }

  Future<AuthUser?> signUpWithEmail(String name, String email, String password) async {
    try {
      // Create user with email and password
      final userCredential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Failed to create user account');
      }

      // Try to update display name with timeout
      try {
        await fbUser.updateDisplayName(name).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Display name update timed out, continuing with signup');
            return;
          },
        );
      } catch (e) {
        print('Failed to update display name: $e');
        // Continue with signup even if display name update fails
      }

      // Create user object
      final user = AuthUser(
        userId: fbUser.uid, 
        displayName: name, 
        email: fbUser.email
      );
      
      _currentUser = user;
      await _saveToStorage(user);
      notifyListeners();
      return user;
      
    } catch (e) {
      if (kDebugMode) {
        print('Signup failed: $e');
      }
      rethrow;
    }
  }

  Future<AuthUser> signInAsGuest() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final guest = AuthUser(
      userId: 'guest-$timestamp',
      displayName: 'Guest',
      email: null,
      avatarUrl: null,
    );
    _currentUser = guest;
    await _saveToStorage(guest);
    notifyListeners();
    return guest;
  }
}


