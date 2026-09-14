import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'post_social_service.dart';

/// Misma lógica que [LivePostsService], colección `community_posts` (sin mezclar con En Vivo).
class CommunityPostsSocialService implements PostSocialService {
  CommunityPostsSocialService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'community_posts';

  @override
  Future<void> togglePostLike(String postId, String uid) async {
    try {
      final postRef = _firestore.collection(_collection).doc(postId);
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
      debugPrint('[CommunityPostsSocialService] togglePostLike: $e');
      rethrow;
    }
  }

  @override
  Stream<bool> isPostLikedStream(String postId, String uid) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  @override
  Stream<int> getPostLikeCountStream(String postId) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['likeCount']));
  }

  @override
  Stream<int> getPostCommentCountStream(String postId) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['commentCount']));
  }

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
      final postRef = _firestore.collection(_collection).doc(postId);
      final commentsRef = postRef.collection('comments');
      final commentRef = commentsRef.doc();

      await _firestore.runTransaction((tx) async {
        tx.set(commentRef, {
          'text': text,
          'authorUid': uid,
          'authorName': authorName,
          'authorUsername': authorUsername,
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
      debugPrint('[CommunityPostsSocialService] addComment: $e');
      rethrow;
    }
  }

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
      final postRef = _firestore.collection(_collection).doc(postId);
      final commentsRef = postRef.collection('comments');
      final commentRef = commentsRef.doc();
      final threadRootId = rootId.trim().isEmpty ? parentCommentId : rootId;
      final threadRootRef = commentsRef.doc(threadRootId);

      await _firestore.runTransaction((tx) async {
        tx.set(commentRef, {
          'text': text,
          'authorUid': uid,
          'authorName': authorName,
          'authorUsername': authorUsername,
          'authorPhoto': authorPhoto,
          'createdAt': FieldValue.serverTimestamp(),
          'likeCount': 0,
          'replyCount': 0,
          'parentId': threadRootId,
          'rootId': threadRootId,
        });

        tx.update(threadRootRef, {'replyCount': FieldValue.increment(1)});
        tx.update(postRef, {'commentCount': FieldValue.increment(1)});
      });

      return commentRef.id;
    } catch (e) {
      debugPrint('[CommunityPostsSocialService] replyToComment: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String uid,
  ) async {
    try {
      final commentRef = _firestore
          .collection(_collection)
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
      debugPrint('[CommunityPostsSocialService] toggleCommentLike: $e');
      rethrow;
    }
  }

  @override
  Stream<bool> isCommentLikedStream(
    String postId,
    String commentId,
    String uid,
  ) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRootCommentsStream(
    String postId,
  ) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRepliesStream(
    String postId,
    String commentId,
  ) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .where('parentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  Stream<bool> hasRepliesStream(String postId, String commentId) {
    return _firestore
        .collection(_collection)
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
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .snapshots()
        .map((snap) => firestoreIntCount(snap.data()?['likeCount']));
  }
}
