import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LivePostsService {
  final FirebaseFirestore _firestore;

  LivePostsService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Toggle like en un post
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

  /// Verifica si un usuario dio like a un post
  Stream<bool> isPostLikedStream(String postId, String uid) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  /// Obtiene el likeCount de un post
  Stream<int> getPostLikeCountStream(String postId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .snapshots()
        .map((snap) => (snap.data()?['likeCount'] ?? 0) as int);
  }

  /// Agrega un comentario raíz
  Future<String> addComment({
    required String postId,
    required String uid,
    required String authorName,
    required String text,
    String? authorPhoto,
  }) async {
    try {
      final postRef = _firestore.collection('live_posts').doc(postId);
      final commentsRef = postRef.collection('comments');
      final commentRef = commentsRef.doc();

      await _firestore.runTransaction((tx) async {
        tx.set(commentRef, {
          'text': text,
          'authorUid': uid,
          'authorName': authorName,
          'authorPhoto': authorPhoto,
          'createdAt': FieldValue.serverTimestamp(),
          'likeCount': 0,
          'replyCount': 0,
          'parentId': null,
          'rootId': null,
        });
        tx.update(postRef, {'commentCount': FieldValue.increment(1)});
      });

      return commentRef.id;
    } catch (e) {
      debugPrint('[LivePostsService] Error adding comment: $e');
      rethrow;
    }
  }

  /// Responde a un comentario
  Future<String> replyToComment({
    required String postId,
    required String uid,
    required String authorName,
    required String text,
    required String parentCommentId,
    required String rootId,
    String? authorPhoto,
  }) async {
    try {
      final postRef = _firestore.collection('live_posts').doc(postId);
      final commentsRef = postRef.collection('comments');
      final commentRef = commentsRef.doc();
      final parentRef = commentsRef.doc(parentCommentId);
      final rootRef = commentsRef.doc(rootId);

      await _firestore.runTransaction((tx) async {
        // Crear el reply
        tx.set(commentRef, {
          'text': text,
          'authorUid': uid,
          'authorName': authorName,
          'authorPhoto': authorPhoto,
          'createdAt': FieldValue.serverTimestamp(),
          'likeCount': 0,
          'replyCount': 0,
          'parentId': parentCommentId,
          'rootId': rootId,
        });

        // Incrementar replyCount en el comentario padre
        tx.update(parentRef, {'replyCount': FieldValue.increment(1)});

        // Si el padre no es el root, también incrementar en el root
        if (parentCommentId != rootId) {
          tx.update(rootRef, {'replyCount': FieldValue.increment(1)});
        }

        // Incrementar commentCount en el post
        tx.update(postRef, {'commentCount': FieldValue.increment(1)});
      });

      return commentRef.id;
    } catch (e) {
      debugPrint('[LivePostsService] Error replying to comment: $e');
      rethrow;
    }
  }

  /// Toggle like en un comentario
  Future<void> toggleCommentLike(String postId, String commentId, String uid) async {
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
  Stream<bool> isCommentLikedStream(String postId, String commentId, String uid) {
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getRootCommentsStream(String postId) {
    return _firestore
        .collection('live_posts')
        .doc(postId)
        .collection('comments')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Obtiene respuestas de un comentario
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
}

