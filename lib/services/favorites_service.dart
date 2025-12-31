import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService _instance = FavoritesService._();
  factory FavoritesService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Añade un favorito (verso o post). type: "verse" | "post"
  Future<void> addFavorite({
    required String type,
    required String refId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final docId = '${type}_$refId';
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(docId)
        .set({
      'type': type,
      'refId': refId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavorite({
    required String type,
    required String refId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final docId = '${type}_$refId';
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(docId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream({int limit = 100}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}


