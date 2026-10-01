import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/live_posts_service.dart';
import '../services/post_social_service.dart';
import '../widgets/top_notice.dart';
import '../widgets/sign_in_prompt.dart';
import 'package:verbum/design_system/design_system.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  /// Si es null se usa [LivePostsService] (En Vivo).
  final PostSocialService? socialService;

  /// Sin [Scaffold] ni AppBar: para incrustar en detalle de comunidad.
  final bool embedded;

  const CommentsScreen({
    super.key,
    required this.postId,
    this.socialService,
    this.embedded = false,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late final PostSocialService _service;
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
    _service = widget.socialService ?? LivePostsService();
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
    if (uid == null) {
      SignInPrompt.ask(context, title: 'Inicia sesión para comentar');
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final authorName =
          ((userData?['displayName'] as String?) ??
                  _auth.currentUser?.displayName ??
                  _auth.currentUser?.email?.split('@').first ??
                  uid)
              .trim();
      final authorUsername = ((userData?['username'] as String?) ?? '')
          .trim()
          .toLowerCase();
      final authorPhoto =
          ((userData?['photoURL'] as String?) ?? _auth.currentUser?.photoURL)
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
      String message = 'Error al comentar.';
      if (e is FirebaseFunctionsException) {
        message = e.message ?? message;
      } else {
        message = 'Error al comentar: $e';
      }
      if (mounted) {
        showTopNotice(context, message: message, isError: true);
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

  Widget _buildThreadBody(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final p = context.palette;
    final type = context.type;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _rootCommentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint('Comments error: ${snapshot.error}');
                return const Center(
                  child: VEmptyState(
                    icon: VerbumIcons.cloudSlash,
                    title: 'No pudimos cargar los comentarios',
                    message: 'Revisa tu conexión e inténtalo de nuevo.',
                  ),
                );
              }

              final comments = snapshot.data?.docs ?? [];
              if (comments.isEmpty) {
                return const Center(
                  child: VEmptyState(
                    icon: VerbumIcons.chatCircle,
                    title: 'Sé el primero en acompañar',
                    message:
                        'Una palabra de ánimo o una oración puede sostener a '
                        'alguien hoy.',
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  8,
                  VerbumSpace.gutter,
                  20,
                ),
                itemCount: comments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
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
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Material(
            color: p.surface,
            elevation: 8,
            shadowColor: p.ink.withValues(alpha: .2),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  10,
                  VerbumSpace.gutter,
                  4,
                ),
                child: uid == null
                    ? const SignInPrompt.bar(
                        title: 'Inicia sesión para comentar',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_replyingToAuthorName != null)
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: p.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  VerbumRadius.control,
                                ),
                              ),
                              child: Row(
                                children: [
                                  VIcon(
                                    VerbumIcons.arrowUpRight,
                                    size: 16,
                                    color: p.rubric,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Respondiendo a $_replyingToAuthorName',
                                      style: type.caption.copyWith(
                                        color: p.rubric,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Cancelar respuesta',
                                    icon: VIcon(
                                      VerbumIcons.close,
                                      size: 16,
                                      color: p.rubric,
                                    ),
                                    onPressed: _cancelReply,
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  minLines: 1,
                                  maxLines: 4,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.send,
                                  scrollPadding: const EdgeInsets.only(
                                    bottom: 120,
                                  ),
                                  onSubmitted: _isSubmittingComment
                                      ? null
                                      : (_) => _submitComment(),
                                  decoration: InputDecoration(
                                    hintText: _replyingToCommentId != null
                                        ? 'Escribe una respuesta…'
                                        : 'Escribe un comentario…',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: p.emphasis,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _isSubmittingComment
                                      ? null
                                      : _submitComment,
                                  child: SizedBox.square(
                                    dimension: 46,
                                    child: Center(
                                      child: _isSubmittingComment
                                          ? SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: p.onEmphasis,
                                              ),
                                            )
                                          : Semantics(
                                              label: 'Enviar',
                                              child: VIcon(
                                                VerbumIcons.paperPlaneRight,
                                                weight: VIconWeight.fill,
                                                size: 20,
                                                color: p.onEmphasis,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildThreadBody(context);
    if (widget.embedded) return body;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const VAppBar(title: Text('Comentarios')),
      body: body,
    );
  }
}

/// Nombre visible: el del perfil, el guardado con el comentario o uno
/// genérico; nunca vacío.
String _displayName(Map<String, dynamic>? profile, String fallback) {
  for (final candidate in [profile?['displayName'] as String?, fallback]) {
    final name = candidate?.trim() ?? '';
    if (name.isNotEmpty && name != 'Anónimo') return name;
  }
  return 'Miembro de Verbum';
}

/// Avatar del autor: foto o inicial sobre lavanda.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photo, this.size = 38});

  final String name;
  final String? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = photo?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .34),
      child: Container(
        width: size,
        height: size,
        color: p.surfaceMuted,
        alignment: Alignment.center,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initial(context),
              )
            : _initial(context),
      ),
    );
  }

  Widget _initial(BuildContext context) => Text(
    name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
    style: context.type.bodyStrong.copyWith(
      color: context.palette.rubric,
      fontSize: size * .38,
    ),
  );
}

/// Burbuja de un comentario o respuesta: autor, "Tú", texto y hora.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.authorName,
    required this.username,
    required this.text,
    required this.time,
    required this.isMine,
    this.compact = false,
  });

  final String authorName;
  final String username;
  final String text;
  final String time;
  final bool isMine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return VSurfaceCard(
      radius: VerbumRadius.tile,
      padding: EdgeInsets.all(compact ? 11 : 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodyStrong.copyWith(
                    fontSize: compact ? 12.5 : 13.5,
                  ),
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: p.butter,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Tú',
                    style: type.caption.copyWith(
                      color: p.onButter,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text('· $time', style: type.caption.copyWith(fontSize: 11)),
            ],
          ),
          if (username.isNotEmpty)
            Text(
              '@$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.caption.copyWith(fontSize: 11),
            ),
          const SizedBox(height: 5),
          Text(
            text,
            style: type.body.copyWith(
              color: p.ink,
              fontSize: compact ? 13.5 : 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Acción pequeña bajo una burbuja ("Responder", "♡ 3").
class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final VerbumIcons? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.rubric : p.inkMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              VIcon(
                icon!,
                size: 15,
                weight: active ? VIconWeight.fill : VIconWeight.regular,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: context.type.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _toggleLikeOrWarn(
  BuildContext context,
  PostSocialService service,
  String postId,
  String commentId,
  String uid,
) async {
  if (uid.isEmpty) {
    SignInPrompt.ask(context, title: 'Inicia sesión para reaccionar');
    return;
  }
  try {
    await service.toggleCommentLike(postId, commentId, uid);
  } catch (e) {
    debugPrint('Error toggling comment like: $e');
  }
}

class _CommentItem extends StatefulWidget {
  final String postId;
  final String commentId;
  final Map<String, dynamic> data;
  final PostSocialService service;
  final String currentUid;
  final void Function(String, String, String?) onReply;
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
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>?
  _authorProfileStream;
  late final Stream<bool> _hasRepliesStream;
  late final Stream<bool> _isLikedStream;
  late final Stream<int> _likeCountStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _repliesStream;

  @override
  void initState() {
    super.initState();
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    _authorProfileStream = authorUid.isNotEmpty
        ? FirebaseFirestore.instance
              .collection('users')
              .doc(authorUid)
              .snapshots()
        : null;
    _hasRepliesStream = widget.service.hasRepliesStream(
      widget.postId,
      widget.commentId,
    );
    _isLikedStream = widget.service.isCommentLikedStream(
      widget.postId,
      widget.commentId,
      widget.currentUid,
    );
    _likeCountStream = widget.service.getCommentLikeCountStream(
      widget.postId,
      widget.commentId,
    );
    _repliesStream = widget.service.getRepliesStream(
      widget.postId,
      widget.commentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = (widget.data['text'] ?? '') as String;
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    final fallbackName = ((widget.data['authorName'] as String?) ?? 'Anónimo')
        .trim();
    final fallbackUsername = ((widget.data['authorUsername'] as String?) ?? '')
        .trim();
    final fallbackPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final likeCount = (widget.data['likeCount'] ?? 0) as int;
    final replyCount = (widget.data['replyCount'] ?? 0) as int;
    final isMine =
        widget.currentUid.isNotEmpty && authorUid == widget.currentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _authorProfileStream,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data();
        final authorName = _displayName(profile, fallbackName);
        final username = ((profile?['username'] as String?) ?? fallbackUsername)
            .trim();
        final photo = (profile?['photoURL'] as String?) ?? fallbackPhoto;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(name: authorName, photo: photo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bubble(
                        authorName: authorName,
                        username: username,
                        text: text,
                        time: widget.formatTimeAgo(createdAt?.toDate()),
                        isMine: isMine,
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StreamBuilder<bool>(
                            stream: _isLikedStream,
                            builder: (context, liked) => StreamBuilder<int>(
                              stream: _likeCountStream,
                              builder: (context, likes) => _TinyAction(
                                icon: VerbumIcons.heart,
                                label: '${likes.data ?? likeCount}',
                                active: liked.data ?? false,
                                onTap: () => _toggleLikeOrWarn(
                                  context,
                                  widget.service,
                                  widget.postId,
                                  widget.commentId,
                                  widget.currentUid,
                                ),
                              ),
                            ),
                          ),
                          _TinyAction(
                            label: 'Responder',
                            onTap: () => widget.onReply(
                              widget.commentId,
                              authorName,
                              widget.data['rootId'] as String?,
                            ),
                          ),
                          StreamBuilder<bool>(
                            stream: _hasRepliesStream,
                            builder: (context, hasRepliesSnapshot) {
                              final hasReplies =
                                  hasRepliesSnapshot.data ?? false;
                              if (!hasReplies && replyCount == 0) {
                                return const SizedBox.shrink();
                              }
                              final n = replyCount > 0 ? replyCount : 1;
                              return _TinyAction(
                                label: _showReplies
                                    ? 'Ocultar respuestas'
                                    : 'Ver $n ${n == 1 ? 'respuesta' : 'respuestas'}',
                                active: true,
                                onTap: () => setState(
                                  () => _showReplies = !_showReplies,
                                ),
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
            if (_showReplies)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repliesStream,
                builder: (context, repliesSnapshot) {
                  final replies = repliesSnapshot.data?.docs ?? [];
                  if (replies.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 48, top: 6),
                    child: Column(
                      children: [
                        for (final reply in replies)
                          _ReplyItem(
                            postId: widget.postId,
                            replyId: reply.id,
                            data: reply.data(),
                            service: widget.service,
                            currentUid: widget.currentUid,
                            formatTimeAgo: widget.formatTimeAgo,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _ReplyItem extends StatefulWidget {
  final String postId;
  final String replyId;
  final Map<String, dynamic> data;
  final PostSocialService service;
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
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  late final Stream<bool> _isLikedStream;
  late final Stream<int> _likeCountStream;

  @override
  void initState() {
    super.initState();
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    _profileStream = authorUid.isNotEmpty
        ? FirebaseFirestore.instance
              .collection('users')
              .doc(authorUid)
              .snapshots()
        : null;
    _isLikedStream = widget.service.isCommentLikedStream(
      widget.postId,
      widget.replyId,
      widget.currentUid,
    );
    _likeCountStream = widget.service.getCommentLikeCountStream(
      widget.postId,
      widget.replyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = (widget.data['text'] ?? '') as String;
    final authorUid = (widget.data['authorUid'] as String? ?? '').trim();
    final fallbackName = ((widget.data['authorName'] as String?) ?? 'Anónimo')
        .trim();
    final fallbackUsername = ((widget.data['authorUsername'] as String?) ?? '')
        .trim();
    final fallbackPhoto = widget.data['authorPhoto'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final isMine =
        widget.currentUid.isNotEmpty && authorUid == widget.currentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data();
        final authorName = _displayName(profile, fallbackName);
        final username = ((profile?['username'] as String?) ?? fallbackUsername)
            .trim();
        final photo = (profile?['photoURL'] as String?) ?? fallbackPhoto;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: authorName, photo: photo, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bubble(
                      authorName: authorName,
                      username: username,
                      text: text,
                      time: widget.formatTimeAgo(createdAt?.toDate()),
                      isMine: isMine,
                      compact: true,
                    ),
                    StreamBuilder<bool>(
                      stream: _isLikedStream,
                      builder: (context, liked) => StreamBuilder<int>(
                        stream: _likeCountStream,
                        builder: (context, likes) => _TinyAction(
                          icon: VerbumIcons.heart,
                          label: '${likes.data ?? 0}',
                          active: liked.data ?? false,
                          onTap: () => _toggleLikeOrWarn(
                            context,
                            widget.service,
                            widget.postId,
                            widget.replyId,
                            widget.currentUid,
                          ),
                        ),
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
