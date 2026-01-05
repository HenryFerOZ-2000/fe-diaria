import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PrivacySecurityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PrivacySecurityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Obtiene configuración de privacidad del usuario
  Future<Map<String, dynamic>> getSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {'isPublic': true, 'showActivity': true};
      }
      final data = doc.data() ?? {};
      return {
        'isPublic': data['isPublic'] ?? true,
        'showActivity': data['showActivity'] ?? true,
      };
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error getting settings: $e');
      return {'isPublic': true, 'showActivity': true};
    }
  }

  /// Actualiza si el perfil es público
  Future<void> updateProfilePublic(String uid, bool isPublic) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {'isPublic': isPublic, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error updating profile public: $e');
      rethrow;
    }
  }

  /// Actualiza si se muestra actividad
  Future<void> updateShowActivity(String uid, bool showActivity) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {'showActivity': showActivity, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error updating show activity: $e');
      rethrow;
    }
  }

  /// Obtiene lista de usuarios bloqueados
  Future<List<Map<String, dynamic>>> getBlockedUsers(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blockedUsers')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error getting blocked users: $e');
      return [];
    }
  }

  /// Bloquea un usuario
  Future<void> blockUser(String uid, String blockedUid, {String? displayName, String? photoUrl}) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('blockedUsers')
          .doc(blockedUid)
          .set({
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error blocking user: $e');
      rethrow;
    }
  }

  /// Desbloquea un usuario
  Future<void> unblockUser(String uid, String blockedUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('blockedUsers')
          .doc(blockedUid)
          .delete();
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error unblocking user: $e');
      rethrow;
    }
  }

  /// Envía un reporte
  Future<void> submitReport({
    required String reporterUid,
    required String type,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterUid': reporterUid,
        'type': type,
        'targetId': targetId,
        'reason': reason,
        'description': description ?? '',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error submitting report: $e');
      rethrow;
    }
  }

  /// Solicita eliminación de cuenta
  Future<void> requestAccountDeletion(String uid, String email) async {
    try {
      await _firestore.collection('accountDeletionRequests').add({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error requesting account deletion: $e');
      rethrow;
    }
  }

  /// Verifica si el usuario actual usa email/password
  bool isEmailPasswordUser() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Envía email de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('[PrivacySecurityService] Error sending password reset: $e');
      rethrow;
    }
  }
}

