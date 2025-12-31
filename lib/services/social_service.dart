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

  Future<void> setUsername(String username) async {
    final callable = _functions.httpsCallable('setUsername');
    await callable.call({'username': username});
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<bool> isFollowingStream(String targetUid) {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      return const Stream<bool>.empty();
    }
    return _firestore
        .collection('users')
        .doc(me)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> follow(String targetUid) async {
    final callable = _functions.httpsCallable('followUser');
    await callable.call({'targetUid': targetUid});
  }

  Future<void> unfollow(String targetUid) async {
    final callable = _functions.httpsCallable('unfollowUser');
    await callable.call({'targetUid': targetUid});
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

  Stream<QuerySnapshot<Map<String, dynamic>>> searchUsers(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    final end = '$lower\uf8ff';
    return _firestore
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: lower)
        .where('usernameLower', isLessThan: end)
        .where('isPublic', isEqualTo: true)
        .orderBy('usernameLower')
        .limit(30)
        .snapshots();
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

