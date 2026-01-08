import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SocialService {
  SocialService._();
  static final SocialService _instance = SocialService._();
  factory SocialService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Sincroniza datos básicos del usuario autenticado con Firestore.
  /// No sobrescribe bio/plan/contadores; el username debe gestionarse vía setUsername callable.
  Future<void> syncCurrentUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final effectiveDisplayName =
        (displayName ?? user.displayName ?? user.email?.split('@').first ?? uid).trim();

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': user.email,
      'displayName': effectiveDisplayName,
      'photoURL': photoURL ?? user.photoURL,
      'plan': FieldValue.delete(),
      'isPublic': FieldValue.delete(),
      'followersCount': FieldValue.delete(),
      'followingCount': FieldValue.delete(),
      'postCount': FieldValue.delete(),
      'streakCurrent': FieldValue.delete(),
      'streakBest': FieldValue.delete(),
      'lastStreakDate': FieldValue.delete(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Genera un username automático basado en email o displayName
  String generateAutoUsername(String? email, String? displayName) {
    String base = '';
    
    // Priorizar displayName si está disponible
    if (displayName != null && displayName.trim().isNotEmpty) {
      base = displayName.trim().toLowerCase();
    } else if (email != null && email.isNotEmpty) {
      // Usar la parte antes del @ del email
      base = email.split('@').first.toLowerCase();
    } else {
      // Fallback: usar timestamp
      base = 'user${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    
    // Limpiar y normalizar: solo letras, números, punto y guión bajo
    base = base.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    
    // Asegurar longitud mínima de 3
    if (base.length < 3) {
      base = '${base}${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
    }
    
    // Limitar a 20 caracteres
    if (base.length > 20) {
      base = base.substring(0, 20);
    }
    
    // Si termina con punto o guión bajo, agregar número
    if (base.endsWith('.') || base.endsWith('_')) {
      base = '${base}1';
    }
    
    return base;
  }

  Future<void> setUsername(String username) async {
    final callable = _functions.httpsCallable('setUsername');
    await callable.call({'username': username});
  }
  
  /// Verifica si el usuario tiene un username configurado
  Future<bool> hasUsername() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snap = await getUser(user.uid);
    final data = snap.data();
    final username = data?['username'] as String?;
    return username != null && username.isNotEmpty && username != user.uid;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }


  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    bool? isPublic,
    String? photoURL,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (displayName != null) data['displayName'] = displayName.trim();
    if (bio != null) data['bio'] = bio;
    if (isPublic != null) data['isPublic'] = isPublic;
    if (photoURL != null) data['photoURL'] = photoURL;
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

}

