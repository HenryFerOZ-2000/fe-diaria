import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authStateSubscription;

  GoogleSignInAccount? _user;
  User? _firebaseUser;
  GoogleSignInAccount? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isSignedIn => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Escuchar cambios de Firebase Auth (más confiable)
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _firebaseUser = user;
      // Si hay usuario de Firebase pero no de Google Sign In, intentar obtenerlo
      if (user != null && _user == null) {
        _authService.signInSilently().then((account) {
          _user = account;
          notifyListeners();
        });
      } else if (user == null) {
        _user = null;
      }
      notifyListeners();
    });
    
    // Intentar sign-in silencioso
    _user = await _authService.signInSilently();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      _user = await _authService.signIn();
      _firebaseUser = FirebaseAuth.instance.currentUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = result.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = result.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _firebaseUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
