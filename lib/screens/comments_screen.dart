import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/live_posts_service.dart';
import '../widgets/top_notice.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _service = LivePostsService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _rootCommentsStream;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  String? _rootId;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _rootCommentsStream = _service.getRootCommentsStream(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (_isSubmittingComment) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmittingComment = true);

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final authorName = ((userData?['displayName'] as String?) ??
          _auth.currentUser?.displayName ??
          _auth.currentUser?.email?.split('@').first ??
          uid)
        .trim();
      final authorUsername =
        ((userData?['username'] as String?) ?? '').trim().toLowerCase();
      final authorPhoto = ((userData?['photoURL'] as String?) ??
          _auth.currentUser?.photoURL)
        ?.trim();

      final isReply = _replyingToCommentId != null && _rootId != null;

      if (_replyingToCommentId != null && _rootId != null) {
        await _service.replyToComment(
          postId: widget.postId,
          uid: uid,
          authorName: authorName,
        authorUsername: authorUsername,
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
          authorUsername: authorUsername,
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

      if (mounted) {
        showTopNotice(
          context,
          message: isReply ? 'Respuesta publicada.' : 'Comentario publicado.',
        );
      }
    } catch (e) {
      if (mounted) {
        showTopNotice(context, message: 'Error al comentar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
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
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              stream: _rootCommentsStream,
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
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
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
                            scrollPadding: const EdgeInsets.only(bottom: 120),
                            onSubmitted:
                                _isSubmittingComment ? null : (_) => _submitComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSubmittingComment ? null : _submitComment,
                          icon: _isSubmittingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
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
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _authorProfileStream;
  late final Stream<bool> _hasRepliesStream;
  late final Stream<bool> _isLikedStream;
  late final Stream<int> _likeCountStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _repliesStream;

  @override
  void initState() {
    super.initState();
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    _authorProfileStream = authorUid.isNotEmpty
        ? FirebaseFirestore.instance.collection('users').doc(authorUid).snapshots()
        : null;
    _hasRepliesStream = widget.service.hasRepliesStream(widget.postId, widget.commentId);
    _isLikedStream = widget.service.isCommentLikedStream(
      widget.postId,
      widget.commentId,
      widget.currentUid,
    );
    _likeCountStream = _getLikeCountStream();
    _repliesStream = widget.service.getRepliesStream(widget.postId, widget.commentId);
  }

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
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    final fallbackDisplayName =
        ((widget.data['authorName'] as String?) ?? 'Anónimo').trim();
    final fallbackUsername =
        ((widget.data['authorUsername'] as String?) ?? '').trim();
    final fallbackPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final likeCount = (widget.data['likeCount'] ?? 0) as int;
    final replyCount = (widget.data['replyCount'] ?? 0) as int;
    final isMine =
        widget.currentUid.isNotEmpty && authorUid == widget.currentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _authorProfileStream,
      builder: (context, profileSnapshot) {
        final profileData = profileSnapshot.data?.data();
        final authorName =
            ((profileData?['displayName'] as String?) ?? fallbackDisplayName).trim();
        final username =
            ((profileData?['username'] as String?) ?? fallbackUsername).trim();
        final authorPhoto =
            (profileData?['photoURL'] as String?) ?? fallbackPhoto;

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
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      authorName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Tú',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${username.isNotEmpty ? username : 'sin-username'}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                        StreamBuilder<bool>(
                          stream: _hasRepliesStream,
                          builder: (context, hasRepliesSnapshot) {
                            final hasReplies = hasRepliesSnapshot.data ?? false;
                            final shouldShowToggle = hasReplies || replyCount > 0;

                            if (!shouldShowToggle) {
                              return const SizedBox.shrink();
                            }

                            final displayReplyCount = hasReplies
                                ? (replyCount > 0 ? replyCount : 1)
                                : replyCount;

                            return Row(
                              children: [
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    setState(() => _showReplies = !_showReplies);
                                  },
                                  child: Text(
                                    _showReplies
                                        ? 'Ocultar'
                                        : 'Ver $displayReplyCount ${displayReplyCount == 1 ? 'respuesta' : 'respuestas'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
                  stream: _isLikedStream,
                  builder: (context, likedSnapshot) {
                    final isLiked = likedSnapshot.data ?? false;
                    return StreamBuilder<int>(
                      stream: _likeCountStream,
                      builder: (context, countSnapshot) {
                        final count = countSnapshot.data ?? likeCount;
                        return InkWell(
                          onTap: _toggleLike,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
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
              if (_showReplies)
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _repliesStream,
                  builder: (context, repliesSnapshot) {
                    if (!repliesSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final replies = repliesSnapshot.data?.docs ?? [];
                    if (replies.isEmpty) {
                      return const SizedBox.shrink();
                    }
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
      },
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
  final String Function(DateTime?) formatTimeAgo;

  const _ReplyItem({
    required this.postId,
    required this.replyId,
    required this.data,
    required this.service,
    required this.currentUid,
    required this.formatTimeAgo,
  });

  @override
  State<_ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<_ReplyItem> {
  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] ?? '';
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    final fallbackDisplayName =
        ((widget.data['authorName'] as String?) ?? 'Anónimo').trim();
    final fallbackUsername =
        ((widget.data['authorUsername'] as String?) ?? '').trim();
    final fallbackPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final isMine =
        widget.currentUid.isNotEmpty && authorUid == widget.currentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: authorUid.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(authorUid)
              .snapshots()
          : null,
      builder: (context, profileSnapshot) {
        final profileData = profileSnapshot.data?.data();
        final authorName =
            ((profileData?['displayName'] as String?) ?? fallbackDisplayName).trim();
        final username =
            ((profileData?['username'] as String?) ?? fallbackUsername).trim();
        final authorPhoto =
            (profileData?['photoURL'] as String?) ?? fallbackPhoto;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
                backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMine) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Tú',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${username.isNotEmpty ? username : 'sin-username'}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
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
      },
    );
  }
}

