import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/live_posts_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _service = LivePostsService();
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  String? _rootId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final authorName = _auth.currentUser?.displayName ??
        _auth.currentUser?.email?.split('@').first ??
        uid;
    final authorPhoto = _auth.currentUser?.photoURL;

    try {
      if (_replyingToCommentId != null && _rootId != null) {
        await _service.replyToComment(
          postId: widget.postId,
          uid: uid,
          authorName: authorName,
          text: text,
          parentCommentId: _replyingToCommentId!,
          rootId: _rootId!,
          authorPhoto: authorPhoto,
        );
      } else {
        await _service.addComment(
          postId: widget.postId,
          uid: uid,
          authorName: authorName,
          text: text,
          authorPhoto: authorPhoto,
        );
      }

      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToAuthorName = null;
        _rootId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al comentar: $e')),
        );
      }
    }
  }

  void _startReply(String commentId, String authorName, String? rootId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
      _rootId = rootId ?? commentId;
    });
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
      _rootId = null;
    });
    _commentController.clear();
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'ahora';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    final days = diff.inDays;
    return 'hace $days d';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comentarios',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getRootCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar comentarios: ${snapshot.error}',
                      style: GoogleFonts.inter(),
                    ),
                  );
                }

                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Sé el primero en comentar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(
                      postId: widget.postId,
                      commentId: comment.id,
                      data: comment.data(),
                      service: _service,
                      currentUid: uid ?? '',
                      onReply: _startReply,
                      formatTimeAgo: _formatTimeAgo,
                    );
                  },
                );
              },
            ),
          ),
          // Input de comentario
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToAuthorName != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Respondiendo a $_replyingToAuthorName',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _cancelReply,
                          color: Colors.blue[900],
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Escribe una respuesta...'
                              : 'Escribe un comentario...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatefulWidget {
  final String postId;
  final String commentId;
  final Map<String, dynamic> data;
  final LivePostsService service;
  final String currentUid;
  final Function(String, String, String?) onReply;
  final String Function(DateTime?) formatTimeAgo;

  const _CommentItem({
    required this.postId,
    required this.commentId,
    required this.data,
    required this.service,
    required this.currentUid,
    required this.onReply,
    required this.formatTimeAgo,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _showReplies = false;

  Future<void> _toggleLike() async {
    try {
      await widget.service.toggleCommentLike(
        widget.postId,
        widget.commentId,
        widget.currentUid,
      );
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] ?? '';
    final authorName = widget.data['authorName'] ?? 'Anónimo';
    final authorPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final likeCount = (widget.data['likeCount'] ?? 0) as int;
    final replyCount = (widget.data['replyCount'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comentario principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
                backgroundColor: Colors.deepPurple.withOpacity(0.12),
                child: authorPhoto == null
                    ? Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.formatTimeAgo(createdAt?.toDate()),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => widget.onReply(
                            widget.commentId,
                            authorName,
                            widget.data['rootId'] as String?,
                          ),
                          child: Text(
                            'Responder',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (replyCount > 0) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              setState(() => _showReplies = !_showReplies);
                            },
                            child: Text(
                              _showReplies
                                  ? 'Ocultar'
                                  : 'Ver $replyCount ${replyCount == 1 ? 'respuesta' : 'respuestas'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Like button
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 4),
            child: StreamBuilder<bool>(
              stream: widget.service.isCommentLikedStream(
                widget.postId,
                widget.commentId,
                widget.currentUid,
              ),
              builder: (context, likedSnapshot) {
                final isLiked = likedSnapshot.data ?? false;
                return StreamBuilder<int>(
                  stream: _getLikeCountStream(),
                  builder: (context, countSnapshot) {
                    final count = countSnapshot.data ?? likeCount;
                    return InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Respuestas
          if (_showReplies && replyCount > 0)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.getRepliesStream(widget.postId, widget.commentId),
              builder: (context, repliesSnapshot) {
                if (!repliesSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final replies = repliesSnapshot.data?.docs ?? [];
                return Padding(
                  padding: const EdgeInsets.only(left: 50, top: 12),
                  child: Column(
                    children: replies.map((replyDoc) {
                      final replyData = replyDoc.data();
                      return _ReplyItem(
                        postId: widget.postId,
                        replyId: replyDoc.id,
                        data: replyData,
                        service: widget.service,
                        currentUid: widget.currentUid,
                        onReply: widget.onReply,
                        formatTimeAgo: widget.formatTimeAgo,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Stream<int> _getLikeCountStream() {
    return FirebaseFirestore.instance
        .collection('live_posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .snapshots()
        .map((snap) => (snap.data()?['likeCount'] ?? 0) as int);
  }
}

class _ReplyItem extends StatefulWidget {
  final String postId;
  final String replyId;
  final Map<String, dynamic> data;
  final LivePostsService service;
  final String currentUid;
  final Function(String, String, String?) onReply;
  final String Function(DateTime?) formatTimeAgo;

  const _ReplyItem({
    required this.postId,
    required this.replyId,
    required this.data,
    required this.service,
    required this.currentUid,
    required this.onReply,
    required this.formatTimeAgo,
  });

  @override
  State<_ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<_ReplyItem> {
  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] ?? '';
    final authorName = widget.data['authorName'] ?? 'Anónimo';
    final authorPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
            backgroundColor: Colors.deepPurple.withOpacity(0.12),
            child: authorPhoto == null
                ? Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.formatTimeAgo(createdAt?.toDate()),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => widget.onReply(
                        widget.data['rootId'] as String? ?? widget.replyId,
                        authorName,
                        widget.data['rootId'] as String?,
                      ),
                      child: Text(
                        'Responder',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Like button para reply
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 4),
                  child: StreamBuilder<bool>(
                    stream: widget.service.isCommentLikedStream(
                      widget.postId,
                      widget.replyId,
                      widget.currentUid,
                    ),
                    builder: (context, likedSnapshot) {
                      final isLiked = likedSnapshot.data ?? false;
                      return StreamBuilder<int>(
                        stream: FirebaseFirestore.instance
                            .collection('live_posts')
                            .doc(widget.postId)
                            .collection('comments')
                            .doc(widget.replyId)
                            .snapshots()
                            .map((snap) => (snap.data()?['likeCount'] ?? 0) as int),
                        builder: (context, countSnapshot) {
                          final count = countSnapshot.data ?? 0;
                          return InkWell(
                            onTap: () async {
                              try {
                                await widget.service.toggleCommentLike(
                                  widget.postId,
                                  widget.replyId,
                                  widget.currentUid,
                                );
                              } catch (e) {
                                debugPrint('Error toggling reply like: $e');
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 14,
                                    color: isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$count',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

