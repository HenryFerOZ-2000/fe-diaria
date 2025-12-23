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
    // Use the OAuth client ID from google-services.json
    // This helps avoid API Exception 10 errors
    serverClientId: '475052295250-stk492qgav0cj1d5q1jdcfc1a6evsia7.apps.googleusercontent.com',
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
      String errorMessage = 'Error al iniciar sesión con Google';
      
      if (e.code == '10' || e.code == 'DEVELOPER_ERROR') {
        errorMessage = 'Error de configuración: Verifica que el SHA-1 esté registrado en Firebase Console.\n\n'
            'SHA-1 Debug: 0E:EC:99:36:C2:38:CA:D4:6B:49:5E:3B:3F:8D:52:08:6C:52:40:3E\n\n'
            'Ve a Firebase Console > Configuración del proyecto > Tus aplicaciones > Android app\n'
            'y agrega este SHA-1 en "Huellas digitales del certificado SHA"';
      } else if (e.code == '12500') {
        errorMessage = 'Error: La aplicación no está configurada correctamente en Google Cloud Console';
      } else if (e.code == '12501') {
        errorMessage = 'El usuario canceló el inicio de sesión';
      } else {
        errorMessage = 'Error (código ${e.code}): ${e.message ?? "Error desconocido"}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
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
