import 'package:cloud_firestore/cloud_firestore.dart';

int firestoreIntCount(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

/// Contrato compartido entre [LivePostsService] y [CommunityPostsSocialService]
/// para reutilizar la misma UI de comentarios sin mezclar colecciones.
abstract class PostSocialService {
  Future<void> togglePostLike(String postId, String uid);

  Stream<bool> isPostLikedStream(String postId, String uid);

  Stream<int> getPostLikeCountStream(String postId);

  Stream<int> getPostCommentCountStream(String postId);

  Future<String> addComment({
    required String postId,
    required String uid,
    required String authorName,
    String? authorUsername,
    required String text,
    String? authorPhoto,
  });

  Future<String> replyToComment({
    required String postId,
    required String uid,
    required String authorName,
    String? authorUsername,
    required String text,
    required String parentCommentId,
    required String rootId,
    String? authorPhoto,
  });

  Future<void> toggleCommentLike(String postId, String commentId, String uid);

  Stream<bool> isCommentLikedStream(
    String postId,
    String commentId,
    String uid,
  );

  Stream<QuerySnapshot<Map<String, dynamic>>> getRootCommentsStream(
    String postId,
  );

  Stream<QuerySnapshot<Map<String, dynamic>>> getRepliesStream(
    String postId,
    String commentId,
  );

  Stream<bool> hasRepliesStream(String postId, String commentId);

  Stream<int> getCommentLikeCountStream(String postId, String commentId);
}
