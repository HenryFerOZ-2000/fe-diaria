import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Attempt silent sign-in
    _user = await _authService.signInSilently();
    // Listen to changes
    _authService.onAuthStateChanged.listen((account) {
      _user = account;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      _user = await _authService.signIn();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
