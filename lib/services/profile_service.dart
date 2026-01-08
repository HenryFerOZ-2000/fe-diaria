import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;

  final _firestore = FirebaseFirestore.instance;

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
    await _firestore.collection('live_posts').doc(postId).delete();
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


