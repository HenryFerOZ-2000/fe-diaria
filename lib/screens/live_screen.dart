import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/top_notice.dart';
import '../widgets/sign_in_prompt.dart';
import '../widgets/verbum_header_actions.dart';
import '../services/social_service.dart';
import '../services/live_posts_service.dart';
import '../services/profile_service.dart';
import '../services/spiritual_stats_service.dart';
import 'comments_screen.dart';
import 'package:verbum/design_system/design_system.dart';

class LivePost {
  final String id;
  final String authorUid;
  String userName;
  String? authorPhoto;
  String text;
  String timeAgo;
  String? mediaUrl;
  final String category;
  String status;
  bool isVideo;
  int joinCount;
  int likes;
  int comments;
  bool isJoined;
  bool isLiked;

  LivePost({
    required this.id,
    required this.authorUid,
    required this.userName,
    required this.text,
    required this.timeAgo,
    this.authorPhoto,
    this.mediaUrl,
    this.category = 'Fortaleza',
    this.status = 'active',
    bool? isVideo,
    this.joinCount = 0,
    this.likes = 0,
    this.comments = 0,
    bool? isLiked,
    bool? isJoined,
  }) : isJoined = isJoined ?? false,
       isLiked = isLiked ?? false,
       isVideo = isVideo ?? false;

  bool get isJoinedValue => isJoined;
}

class LiveComment {
  final String id;
  final String userName;
  final String text;
  final String timeAgo;

  LiveComment({
    required this.id,
    required this.userName,
    required this.text,
    required this.timeAgo,
  });
}

class LiveScreen extends StatefulWidget {
  final bool showAppBar;

  /// Portada a sangre (Comunidad) con el número de intenciones de la
  /// semana. Si se da, la pantalla se muestra sin su propia barra.
  final Widget Function(int weeklyCount)? coverBuilder;

  const LiveScreen({super.key, this.showAppBar = true, this.coverBuilder});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPosting = false;
  DateTime? _nextPostAllowedAt;
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _auth = FirebaseAuth.instance;
  final _social = SocialService();
  final _livePostsService = LivePostsService();
  final _profileService = ProfileService();
  String? _uid;
  String _selectedFeedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    _ensureAuth().then((_) {
      _syncProfileToFirestore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureAuth() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final resolvedUid = _auth.currentUser?.uid;
    if (mounted && _uid != resolvedUid) {
      setState(() => _uid = resolvedUid);
    } else {
      _uid = resolvedUid;
    }
  }

  Future<void> _syncProfileToFirestore() async {
    await _ensureAuth();
    final uid = _uid;
    if (uid == null) return;
    final user = _auth.currentUser;
    try {
      await _social.syncCurrentUserProfile(
        displayName: user?.displayName,
        photoURL: user?.photoURL,
      );
    } catch (e) {
      debugPrint('Error syncing profile: $e');
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    // Persistent feed: all posts ordered by creation date (newest first)
    // No expiration filters - posts remain visible indefinitely
    return _firestore
        .collection('live_posts')
        .orderBy('createdAt', descending: true)
        .limit(50);
  }

  String _formatTimeAgo(DateTime? time, DateTime now) {
    if (time == null) return 'ahora';
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    final days = diff.inDays;
    return 'hace $days d';
  }

  Future<void> _refreshFeed() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _openComments(LivePost post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CommentsScreen(postId: post.id)),
    );
  }

  void _sharePost(LivePost post) {
    SharePlus.instance.share(
      ShareParams(
        text: '${post.text}\n\n- ${post.userName}',
        subject: 'Oración en vivo',
      ),
    );
  }

  Future<void> _deletePostFromLive(LivePost post) async {
    final uid = _uid;
    if (uid == null || post.authorUid != uid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
          '¿Quieres eliminar esta publicación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    showTopNotice(context, message: 'Eliminando publicación...');
    try {
      await _profileService.deletePost(post.id);
      if (!mounted) return;
      showTopNotice(context, message: 'Publicación eliminada.');
    } catch (e) {
      if (!mounted) return;
      showTopNotice(context, message: 'Error al eliminar: $e', isError: true);
    }
  }

  Future<bool> _submitPost(
    String text, {
    required String category,
    BuildContext? feedbackContext,
  }) async {
    final messageContext = feedbackContext ?? context;
    final trimmed = text.trim();
    if (trimmed.length < 10) {
      if (mounted) {
        showTopNotice(
          messageContext,
          message: 'Escribe al menos 10 caracteres',
          isError: true,
        );
      }
      return false;
    }

    final now = DateTime.now();
    final nextAllowedAt = _nextPostAllowedAt;
    if (nextAllowedAt != null && nextAllowedAt.isAfter(now)) {
      final remaining = nextAllowedAt.difference(now).inSeconds;
      if (mounted) {
        showTopNotice(
          messageContext,
          message:
              'Espera ${remaining > 0 ? remaining : 1}s para volver a publicar',
          isError: true,
        );
      }
      return false;
    }

    if (_isPosting) return false;
    if (_auth.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    setState(() {
      _isPosting = true;
    });
    try {
      final callable = _functions.httpsCallable('createLivePost');
      final result = await callable.call<Map<String, dynamic>>({
        'text': trimmed,
        'category': category,
      });
      final postId = result.data['postId'] as String?;
      if (!mounted) return false;
      if (postId != null) {
        // Compatibilidad con funciones desplegadas antes de incorporar categorías.
        try {
          await _firestore.collection('live_posts').doc(postId).update({
            'category': category,
          });
        } catch (error) {
          debugPrint('Could not persist live post category: $error');
        }
        // Incrementar contador de publicaciones creadas
        final spiritualStatsService = SpiritualStatsService();
        await spiritualStatsService.incrementPostCreated();
      }
      _nextPostAllowedAt = DateTime.now().add(const Duration(seconds: 10));
      if (!mounted) return false;
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (!mounted || !messageContext.mounted) return false;
      showTopNotice(
        messageContext,
        message: e.message ?? 'Error al publicar',
        isError: true,
      );
      debugPrint(
        'createLivePost error code=${e.code} message=${e.message} details=${e.details}',
      );
      return false;
    } catch (e) {
      if (!mounted || !messageContext.mounted) return false;
      showTopNotice(
        messageContext,
        message: 'Error al publicar: $e',
        isError: true,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (_auth.currentUser == null) {
      await SignInPrompt.ask(
        context,
        title: 'Inicia sesión para pedir oración',
      );
      return;
    }
    final didPublish = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _CreatePostModal(
        onPost: (text, category) async {
          return _submitPost(
            text,
            category: category,
            feedbackContext: modalContext,
          );
        },
      ),
    );

    if (!mounted || didPublish != true) return;
    showTopNotice(context, message: 'Publicación creada.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final feed = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LiveFeedSkeleton(
            onCompose: _createPost,
            cover: widget.coverBuilder?.call(0),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar publicaciones: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final posts = docs.map((doc) {
          final data = doc.data();
          final ts = data['createdAt'] as Timestamp?;
          return LivePost(
            id: doc.id,
            authorUid: data['authorUid'] as String? ?? '',
            userName:
                (data['authorUsername'] as String?) ??
                (data['authorName'] as String?) ??
                data['authorUid'] as String? ??
                'Anónimo',
            authorPhoto: data['authorPhoto'] as String?,
            text: data['text'] as String? ?? '',
            category: (data['category'] as String?) ?? 'Fortaleza',
            status: (data['prayerStatus'] as String?) ?? 'active',
            timeAgo: _formatTimeAgo(ts?.toDate(), now),
            joinCount: (data['joinCount'] ?? 0) as int,
            likes: (data['likeCount'] ?? 0) as int,
            comments: (data['commentCount'] ?? 0) as int,
            isLiked: false,
          );
        }).toList();

        final weekAgo = now.subtract(const Duration(days: 7));
        final weeklyCount = docs.where((doc) {
          final ts = doc.data()['createdAt'] as Timestamp?;
          return ts != null && ts.toDate().isAfter(weekAgo);
        }).length;
        final cover = widget.coverBuilder?.call(weeklyCount);
        const gutter = EdgeInsets.symmetric(horizontal: VerbumSpace.gutter);

        final visiblePosts = _selectedFeedCategory == 'Todas'
            ? posts
            : posts
                  .where((post) => post.category == _selectedFeedCategory)
                  .toList();

        return RefreshIndicator(
          onRefresh: _refreshFeed,
          color: colorScheme.primary,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: cover == null ? 10 : 0,
              bottom: 28 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: visiblePosts.isEmpty ? 2 : visiblePosts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?cover,
                    Padding(
                      padding: gutter,
                      child: _LiveFeedHeader(
                        selectedCategory: _selectedFeedCategory,
                        onCategorySelected: (category) {
                          setState(() => _selectedFeedCategory = category);
                        },
                        onCompose: _createPost,
                      ),
                    ),
                  ],
                );
              }
              if (visiblePosts.isEmpty) {
                return Padding(
                  padding: gutter,
                  child: _LiveEmptyState(
                    filtered: _selectedFeedCategory != 'Todas',
                    onCompose: _createPost,
                  ),
                );
              }
              final post = visiblePosts[index - 1];
              return Padding(
                key: ValueKey(post.id),
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  0,
                  VerbumSpace.gutter,
                  12,
                ),
                child: _FeedPostTile(
                  postId: post.id,
                  post: post,
                  service: _livePostsService,
                  currentUid: _uid ?? '',
                  onComment: () => _openComments(post),
                  onShare: () => _sharePost(post),
                  onDelete: () => _deletePostFromLive(post),
                  onAuthorTap: null, // Los perfiles ya no son públicos
                ),
              );
            },
          ),
        );
      },
    );
    if (widget.coverBuilder != null) return feed;
    return AppScaffold(
      showBanner: false,
      showAppBar: widget.showAppBar,
      titleWidget: Text(
        'En Vivo',
        style: VerbumFonts.serif(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      actions: const [VerbumHeaderActions()],
      centerTitle: false,
      resizeToAvoidBottomInset: true,
      body: feed,
    );
  }
}

class _LiveFeedHeader extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCompose;

  const _LiveFeedHeader({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onCompose,
  });

  static const categories = [
    'Todas',
    'Salud',
    'Familia',
    'Fortaleza',
    'Gratitud',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSurfaceCard(
            onTap: onCompose,
            radius: VerbumRadius.card,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            semanticLabel: 'Compartir una intención',
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(VerbumRadius.control),
                  ),
                  child: VIcon(VerbumIcons.handHeart, color: p.rubric),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Por quién quieres orar?',
                        style: type.bodyStrong.copyWith(fontSize: 15),
                      ),
                      Text('Comparte una intención', style: type.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.butter,
                    borderRadius: BorderRadius.circular(VerbumRadius.control),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(VerbumIcons.plus, size: 15, color: p.onButter),
                      const SizedBox(width: 5),
                      Text(
                        'Pedir',
                        style: type.bodyStrong.copyWith(
                          color: p.onButter,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category == selectedCategory;
                final icon = categoryIconFor(category);
                return Semantics(
                  button: true,
                  selected: selected,
                  child: Material(
                    color: selected ? p.emphasis : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(99),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => onCategorySelected(category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              VIcon(
                                icon,
                                size: 14,
                                color: selected ? p.onEmphasis : p.rubric,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              category,
                              style: type.bodyStrong.copyWith(
                                fontSize: 13,
                                color: selected ? p.onEmphasis : p.rubric,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono de cada categoría de intención ("Todas" no lleva).
VerbumIcons? categoryIconFor(String category) => switch (category) {
  'Salud' => VerbumIcons.firstAid,
  'Familia' => VerbumIcons.houseLine,
  'Fortaleza' => VerbumIcons.mountains,
  'Gratitud' => VerbumIcons.sparkle,
  'Todas' => null,
  _ => VerbumIcons.handHeart,
};

class _LiveEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onCompose;

  const _LiveEmptyState({required this.filtered, required this.onCompose});

  @override
  Widget build(BuildContext context) {
    return VSurfaceCard(
      radius: VerbumRadius.card,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: VEmptyState(
        icon: VerbumIcons.chatsCircle,
        title: filtered ? 'Aún no hay intenciones aquí' : 'Sé la primera voz',
        message:
            'Comparte algo que hoy quieras poner en manos de la comunidad.',
        actionLabel: 'Compartir una intención',
        onAction: onCompose,
      ),
    );
  }
}

class _LiveFeedSkeleton extends StatelessWidget {
  final VoidCallback onCompose;
  final Widget? cover;

  const _LiveFeedSkeleton({required this.onCompose, this.cover});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: EdgeInsets.only(top: cover == null ? 10 : 0, bottom: 28),
      children: [
        ?cover,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
          child: Column(
            children: [
              _LiveFeedHeader(
                selectedCategory: 'Todas',
                onCategorySelected: (_) {},
                onCompose: onCompose,
              ),
              for (var i = 0; i < 3; i++)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(VerbumRadius.card),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedPostTile extends StatefulWidget {
  final String postId;
  final LivePost post;
  final LivePostsService service;
  final String currentUid;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onAuthorTap;

  const _FeedPostTile({
    required this.postId,
    required this.post,
    required this.service,
    required this.currentUid,
    required this.onComment,
    required this.onShare,
    this.onDelete,
    this.onAuthorTap,
  });

  @override
  State<_FeedPostTile> createState() => _ModernFeedPostTileState();
}

class _ModernFeedPostTileState extends State<_FeedPostTile> {
  late int _joinCount;
  bool _joined = false;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _joinCount = widget.post.likes;
  }

  @override
  void didUpdateWidget(covariant _FeedPostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_updating && oldWidget.post.likes != widget.post.likes) {
      _joinCount = widget.post.likes;
    }
  }

  Future<void> _toggleJoin() async {
    if (widget.currentUid.isEmpty) {
      SignInPrompt.ask(
        context,
        title: 'Inicia sesión para orar con la comunidad',
      );
      return;
    }
    if (_updating) return;
    final previousJoined = _joined;
    final previousCount = _joinCount;
    setState(() {
      _updating = true;
      _joined = !_joined;
      _joinCount = (_joinCount + (_joined ? 1 : -1)).clamp(0, 999999);
    });
    HapticFeedback.selectionClick();
    try {
      await widget.service.togglePrayerJoin(widget.postId, widget.currentUid);
    } catch (error) {
      if (mounted) {
        setState(() {
          _joined = previousJoined;
          _joinCount = previousCount;
        });
      }
      debugPrint('Error joining prayer: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    final previous = widget.post.status;
    setState(() => widget.post.status = status);
    try {
      await widget.service.updatePrayerStatus(
        widget.postId,
        widget.currentUid,
        status,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => widget.post.status = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar la intención.')),
      );
    }
  }

  String _authorLabel(bool isMine) {
    if (isMine) return 'Tú';
    final raw = widget.post.userName.trim();
    if (raw.isEmpty || raw == widget.post.authorUid || raw.length > 32) {
      return 'Miembro de Verbum';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final isMine =
        widget.currentUid.isNotEmpty &&
        widget.post.authorUid == widget.currentUid;
    final authorName = _authorLabel(isMine);
    final photo = widget.post.authorPhoto?.trim();
    final status = widget.post.status;
    final categoryIcon = categoryIconFor(widget.post.category);

    return StreamBuilder<bool>(
      stream: widget.service.isPrayerJoinedStream(
        widget.postId,
        widget.currentUid,
      ),
      builder: (context, snapshot) {
        if (!_updating && snapshot.hasData && snapshot.data != _joined) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_updating) {
              setState(() => _joined = snapshot.data ?? false);
            }
          });
        }

        return VSurfaceCard(
          radius: VerbumRadius.card,
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: p.surfaceMuted,
                      alignment: Alignment.center,
                      child: photo != null && photo.isNotEmpty
                          ? Image.network(
                              photo,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(),
                            )
                          : Text(
                              authorName.characters.first.toUpperCase(),
                              style: type.bodyStrong.copyWith(color: p.rubric),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.bodyStrong,
                        ),
                        Text(widget.post.timeAgo, style: type.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (categoryIcon != null) ...[
                          VIcon(categoryIcon, size: 13, color: p.rubric),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          widget.post.category,
                          style: type.caption.copyWith(
                            color: p.rubric,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMine && widget.onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      icon: VIcon(VerbumIcons.dotsThree, color: p.inkMuted),
                      onSelected: (value) {
                        if (value == 'delete') {
                          widget.onDelete?.call();
                        } else {
                          _updateStatus(value);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'active',
                          child: Text('Seguimos orando'),
                        ),
                        PopupMenuItem(
                          value: 'answered',
                          child: Text('Marcar como respondida'),
                        ),
                        PopupMenuItem(
                          value: 'gratitude',
                          child: Text('Convertir en agradecimiento'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar publicación'),
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 6),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 6),
                child: Text(
                  widget.post.text,
                  style: VerbumFonts.serif(
                    color: p.ink,
                    fontSize: 19,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (status == 'answered' || status == 'gratitude')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'answered' ? p.sageSoft : p.goldSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VIcon(
                          status == 'answered'
                              ? VerbumIcons.sealCheck
                              : VerbumIcons.sparkle,
                          weight: VIconWeight.fill,
                          size: 13,
                          color: status == 'answered' ? p.sage : p.onButter,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status == 'answered'
                              ? 'Oración respondida'
                              : 'Agradecimiento',
                          style: type.caption.copyWith(
                            color: status == 'answered'
                                ? p.sageInk
                                : p.onButter,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.post.mediaUrl != null &&
                  widget.post.mediaUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(VerbumRadius.tile),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.post.mediaUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: p.surfaceMuted,
                        child: Center(
                          child: VIcon(
                            VerbumIcons.imageBroken,
                            color: p.inkSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: p.lineSoft),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PrayerJoinButton(
                    joined: _joined,
                    count: _joinCount,
                    answered: status != 'active',
                    onTap: _toggleJoin,
                  ),
                  const Spacer(),
                  _ModernPostAction(
                    icon: VerbumIcons.chatCircle,
                    label: '${widget.post.comments}',
                    tooltip: 'Comentarios',
                    onTap: widget.onComment,
                  ),
                  _ModernPostAction(
                    icon: VerbumIcons.shareNetwork,
                    tooltip: 'Compartir',
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Orar · 12": el gesto principal. Al unirse se ilumina en mantequilla.
class _PrayerJoinButton extends StatelessWidget {
  final bool joined;
  final int count;

  /// Respondida o de agradecimiento: se celebra en lugar de pedir.
  final bool answered;
  final VoidCallback onTap;

  const _PrayerJoinButton({
    required this.joined,
    required this.count,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = answered
        ? 'Gracias a Dios · $count'
        : joined
        ? 'Orando · $count'
        : 'Orar · $count';
    return Semantics(
      button: true,
      selected: joined,
      label: joined
          ? 'Dejar de acompañar, $count'
          : 'Acompañar en oración, $count',
      excludeSemantics: true,
      child: Material(
        color: joined ? p.butter : p.surfaceMuted,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(
                  VerbumIcons.handsPraying,
                  size: 16,
                  weight: joined ? VIconWeight.fill : VIconWeight.regular,
                  color: joined ? p.onButter : p.rubric,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.type.bodyStrong.copyWith(
                    fontSize: 13,
                    color: joined ? p.onButter : p.rubric,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernPostAction extends StatelessWidget {
  final VerbumIcons icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  const _ModernPostAction({
    required this.icon,
    this.label,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.palette.inkMuted;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                VIcon(icon, color: color, size: 19),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: context.type.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja para pedir oración a la comunidad.
class _CreatePostModal extends StatefulWidget {
  final Future<bool> Function(String text, String category) onPost;

  const _CreatePostModal({required this.onPost});

  @override
  State<_CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<_CreatePostModal> {
  String _selectedCategory = 'Salud';
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _charCount = 0;
  bool _isSubmitting = false;
  late VoidCallback _textListener;

  @override
  void initState() {
    super.initState();
    _charCount = _textController.text.length;
    _textListener = () {
      if (mounted) {
        setState(() {
          _charCount = _textController.text.length;
        });
      }
    };
    _textController.addListener(_textListener);
  }

  @override
  void dispose() {
    _textController.removeListener(_textListener);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static const _categories = ['Salud', 'Familia', 'Fortaleza', 'Gratitud'];
  static const _minChars = 10;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final didPublish = await widget.onPost(
      _textController.text.trim(),
      _selectedCategory,
    );
    if (!mounted) return;
    if (didPublish) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final ready = _textController.text.trim().length >= _minChars;
    final canPost = ready && !_isSubmitting;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(VerbumRadius.sheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              10,
              VerbumSpace.gutter,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.butter,
                        borderRadius: BorderRadius.circular(
                          VerbumRadius.control,
                        ),
                      ),
                      child: VIcon(
                        VerbumIcons.handsPraying,
                        weight: VIconWeight.fill,
                        color: p.onButter,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Pide oración',
                              style: type.title.copyWith(fontSize: 22),
                            ),
                          ),
                          Text(
                            'La comunidad orará contigo.',
                            style: type.body.copyWith(color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context, false),
                      icon: VIcon(VerbumIcons.close, color: p.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('¿Por qué oramos?', style: type.bodyStrong),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in _categories)
                      _CategoryChip(
                        label: category,
                        icon: categoryIconFor(category)!,
                        selected: category == _selectedCategory,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                VSurfaceCard(
                  radius: VerbumRadius.card,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        style: VerbumFonts.serif(
                          color: p.ink,
                          fontSize: 19,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Por la salud de mi mamá, por un trabajo, '
                              'por paz en mi familia…',
                          hintStyle: VerbumFonts.serif(
                            color: p.inkSubtle,
                            fontSize: 18,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          counterText: '',
                        ),
                      ),
                      Divider(height: 1, color: p.lineSoft),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VIcon(
                            ready ? VerbumIcons.checkCircle : VerbumIcons.info,
                            size: 15,
                            weight: ready
                                ? VIconWeight.fill
                                : VIconWeight.regular,
                            color: ready ? p.sage : p.inkSubtle,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ready
                                  ? 'Lista para compartir'
                                  : 'Escribe al menos $_minChars caracteres',
                              style: type.caption.copyWith(
                                color: ready ? p.sageInk : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text('$_charCount/500', style: type.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    VIcon(
                      VerbumIcons.shieldCheck,
                      size: 15,
                      color: p.inkSubtle,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Se publica con tu nombre. Evita datos privados de otras personas.',
                        style: type.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                VButton(
                  label: 'Pedir oración',
                  icon: VerbumIcons.paperPlaneRight,
                  expanded: true,
                  loading: _isSubmitting,
                  onPressed: canPost ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final VerbumIcons icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onEmphasis : p.rubric;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.emphasis : p.surfaceMuted,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.type.bodyStrong.copyWith(
                    color: fg,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
