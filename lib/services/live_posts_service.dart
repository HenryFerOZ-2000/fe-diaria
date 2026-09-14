import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'post_social_service.dart';

class LivePostsService implements PostSocialService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  LivePostsService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> togglePrayerJoin(String postId, String uid) async {
    await togglePostLike(postId, uid);
  }

  Stream<bool> isPrayerJoinedStream(String postId, String uid) {
    if (uid.isEmpty) return Stream.value(false);
    return isPostLikedStream(postId, uid);
  }

  Future<void> updatePrayerStatus(
    String postId,
    String uid,
    String status,
  ) async {
    const allowed = {'active', 'answered', 'gratitude'};
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    final postRef = _firestore.collection('live_posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final authorUid = snapshot.data()?['authorUid'] as String? ?? '';
      if (authorUid != uid) {
        throw StateError('Solo el autor puede cambiar el estado.');
      }
      transaction.update(postRef, {
        'prayerStatus': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> togglePostLike(String postId, String uid) async {
    try {
      final postRef = _firestore.collection('live_posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(uid);

      await _firestore.runTransaction((tx) async {
        final likeSnap = await tx.get(likeRef);
        final isLiked = likeSnap.exists;

        if (isLiked) {
          tx.delete(likeRef);
          tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likeCount': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      debugPrint('[LivePostsService] Error toggling post like: $e');
      rethrow;
    }
  }

  @override
  Stream<bool> isPostLikedStream(String postId, String uid) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  @override
  Stream<int> getPostLikeCountStream(String postId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['likeCount']));
  }

  @override
  Stream<int> getPostCommentCountStream(String postId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['commentCount']));
  }

  /// Agrega un comentario raíz
  @override
  Future<String> addComment({
    required String postId,
    required String uid,
    required String authorName,
    String? authorUsername,
    required String text,
    String? authorPhoto,
  }) async {
    try {
      final callable = _functions.httpsCallable('createLiveComment');
      final result = await callable.call<Map<String, dynamic>>({
        'postId': postId,
        'text': text,
      });
      final commentId = (result.data['commentId'] as String?)?.trim() ?? '';
      if (commentId.isEmpty) {
        throw Exception('No se pudo crear el comentario.');
      }
      return commentId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[LivePostsService] createLiveComment failed: ${e.code} ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[LivePostsService] Error adding comment: $e');
      rethrow;
    }
  }

  /// Responde a un comentario
  @override
  Future<String> replyToComment({
    required String postId,
    required String uid,
    required String authorName,
    String? authorUsername,
    required String text,
    required String parentCommentId,
    required String rootId,
    String? authorPhoto,
  }) async {
    try {
      final callable = _functions.httpsCallable('replyLiveComment');
      final result = await callable.call<Map<String, dynamic>>({
        'postId': postId,
        'text': text,
        'parentCommentId': parentCommentId,
        'rootId': rootId,
      });
      final commentId = (result.data['commentId'] as String?)?.trim() ?? '';
      if (commentId.isEmpty) {
        throw Exception('No se pudo crear la respuesta.');
      }
      return commentId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[LivePostsService] replyLiveComment failed: ${e.code} ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[LivePostsService] Error replying to comment: $e');
      rethrow;
    }
  }

  /// Toggle like en un comentario
  @override
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String uid,
  ) async {
    try {
      final commentRef = _firestore
          .collection('live_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      final likeRef = commentRef.collection('likes').doc(uid);

      await _firestore.runTransaction((tx) async {
        final likeSnap = await tx.get(likeRef);
        final isLiked = likeSnap.exists;

        if (isLiked) {
          tx.delete(likeRef);
          tx.update(commentRef, {'likeCount': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
          tx.update(commentRef, {'likeCount': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      debugPrint('[LivePostsService] Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Verifica si un usuario dio like a un comentario
  @override
  Stream<bool> isCommentLikedStream(
    String postId,
    String commentId,
    String uid,
  ) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  /// Obtiene comentarios raíz de un post
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRootCommentsStream(
    String postId,
  ) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Obtiene respuestas de un comentario
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRepliesStream(
    String postId,
    String commentId,
  ) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .where('parentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Verifica si un comentario raíz tiene al menos una respuesta
  @override
  Stream<bool> hasRepliesStream(String postId, String commentId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .where('parentId', isEqualTo: commentId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  @override
  Stream<int> getCommentLikeCountStream(String postId, String commentId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['likeCount']));
  }
}
