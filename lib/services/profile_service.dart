import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userPosts(String uid, {int limit = 30}) {
    return _firestore
        .collection('live_posts')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Elimina un post del usuario
  Future<void> deletePost(String postId) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No hay usuario autenticado para eliminar el post.');
    }

    final callable = _functions.httpsCallable('deleteLivePost');
    try {
      await callable
          .call<Map<String, dynamic>>({'postId': postId})
          .timeout(const Duration(seconds: 15));
      return;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'deleteLivePost callable failed '
        'code=${e.code} message=${e.message} details=${e.details}. '
        'Trying Firestore fallback...',
      );
    } catch (e) {
      debugPrint('deleteLivePost callable unexpected error: $e. Trying Firestore fallback...');
    }

    await _firestore.collection('live_posts').doc(postId).delete();
    await _firestore.collection('users').doc(uid).set({
      'postsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> followers(String uid, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> following(String uid, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }
}


