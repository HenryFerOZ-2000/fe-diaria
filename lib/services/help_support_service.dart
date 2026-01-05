import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class HelpSupportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HelpSupportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Obtiene FAQ desde Firestore o retorna null si no existe
  Future<List<Map<String, dynamic>>?> getFaqFromFirestore() async {
    try {
      final doc = await _firestore.collection('app_config').doc('faq').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[HelpSupportService] Error getting FAQ from Firestore: $e');
      return null;
    }
  }

  /// Envía un ticket de soporte
  Future<void> submitSupportTicket({
    required String category,
    required String description,
    String? screenshotUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('support_tickets').add({
        'uid': user?.uid,
        'email': user?.email,
        'category': category,
        'description': description,
        'screenshotUrl': screenshotUrl,
        'appVersion': '0.1.1', // TODO: obtener de package_info_plus
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[HelpSupportService] Error submitting ticket: $e');
      rethrow;
    }
  }
}

