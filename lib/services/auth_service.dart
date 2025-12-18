import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      // Add more scopes if needed
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;

  Stream<GoogleSignInAccount?> get onAuthStateChanged => _googleSignIn.onCurrentUserChanged;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return null;

      final auth = await _currentUser!.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      _firebaseUser = result.user;
      return _currentUser;
    } on PlatformException catch (e) {
      // Common Android error: code == 10 (DEVELOPER_ERROR) when SHA-1 or package mismatch
      // Surfacing for easier debugging
      throw Exception('Google Sign-In failed (code: ${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      _firebaseUser = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (_) {
      return null;
    }
  }
}
