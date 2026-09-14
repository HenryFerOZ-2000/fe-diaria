import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/top_notice.dart';
import '../widgets/verbum_header_actions.dart';
import '../services/social_service.dart';
import '../services/live_posts_service.dart';
import '../services/profile_service.dart';
import '../services/spiritual_stats_service.dart';
import 'comments_screen.dart';

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

  const LiveScreen({super.key, this.showAppBar = true});

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
    Share.share(
      '${post.text}\n\n- ${post.userName}',
      subject: 'Oración en vivo',
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

    return AppScaffold(
      showBanner: false,
      showAppBar: widget.showAppBar,
      titleWidget: Text(
        'En Vivo',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      actions: const [VerbumHeaderActions()],
      centerTitle: false,
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LiveFeedSkeleton(onCompose: _createPost);
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              itemCount: visiblePosts.isEmpty ? 2 : visiblePosts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _LiveFeedHeader(
                    selectedCategory: _selectedFeedCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedFeedCategory = category);
                    },
                    onCompose: _createPost,
                  );
                }
                if (visiblePosts.isEmpty) {
                  return _LiveEmptyState(
                    filtered: _selectedFeedCategory != 'Todas',
                    onCompose: _createPost,
                  );
                }
                final post = visiblePosts[index - 1];
                return Padding(
                  key: ValueKey(post.id),
                  padding: const EdgeInsets.only(bottom: 12),
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
      ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTENCIONES COMPARTIDAS',
            style: GoogleFonts.inter(
              color: scheme.secondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Acompañarnos también es orar',
            style: GoogleFonts.playfairDisplay(
              color: scheme.onSurface,
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escucha, comparte esperanza y hazle saber a alguien que no está solo.',
            style: GoogleFonts.inter(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onCompose,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF292431)
                      : const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: .15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .12 : .045),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: .10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volunteer_activism_outlined,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Por quién quieres orar hoy?',
                            style: GoogleFonts.inter(
                              color: scheme.onSurface,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Compartir una intención',
                            style: GoogleFonts.inter(
                              color: scheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.primary,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category == selectedCategory;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => onCategorySelected(category),
                  label: Text(category),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  side: BorderSide(
                    color: selected
                        ? scheme.primary.withValues(alpha: .28)
                        : scheme.outline.withValues(alpha: .16),
                  ),
                  backgroundColor: dark
                      ? const Color(0xFF292431)
                      : const Color(0xFFFFFCF7),
                  selectedColor: scheme.primary.withValues(alpha: .12),
                  labelStyle: GoogleFonts.inter(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _LiveEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onCompose;

  const _LiveEmptyState({required this.filtered, required this.onCompose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, color: scheme.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            filtered ? 'Aún no hay intenciones aquí' : 'Sé la primera voz',
            style: GoogleFonts.playfairDisplay(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Comparte algo que hoy quieras poner en manos de la comunidad.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCompose,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Compartir una intención'),
          ),
        ],
      ),
    );
  }
}

class _LiveFeedSkeleton extends StatelessWidget {
  final VoidCallback onCompose;

  const _LiveFeedSkeleton({required this.onCompose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _LiveFeedHeader(
          selectedCategory: 'Todas',
          onCategorySelected: (_) {},
          onCompose: onCompose,
        ),
        ...List.generate(
          3,
          (index) => Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: scheme.outline.withValues(alpha: .10)),
            ),
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
    if (_updating || widget.currentUid.isEmpty) return;
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

  String get _statusLabel {
    switch (widget.post.status) {
      case 'answered':
        return 'ORACIÓN RESPONDIDA';
      case 'gratitude':
        return 'AGRADECIMIENTO';
      default:
        return 'SEGUIMOS ORANDO';
    }
  }

  IconData get _statusIcon {
    switch (widget.post.status) {
      case 'answered':
        return Icons.check_circle_outline_rounded;
      case 'gratitude':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.favorite_outline_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Salud':
        return const Color(0xFF5F8178);
      case 'Familia':
        return const Color(0xFF77649A);
      case 'Gratitud':
        return const Color(0xFFB5813E);
      default:
        return const Color(0xFF8A645D);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Salud':
        return Icons.healing_outlined;
      case 'Familia':
        return Icons.family_restroom_rounded;
      case 'Gratitud':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.shield_outlined;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isMine =
        widget.currentUid.isNotEmpty &&
        widget.post.authorUid == widget.currentUid;
    final authorName = _authorLabel(isMine);
    final photo = widget.post.authorPhoto?.trim();
    final accent = _categoryColor(widget.post.category);

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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF292431) : const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: _joined
                  ? accent.withValues(alpha: .42)
                  : scheme.outline.withValues(alpha: .14),
              width: _joined ? 1.35 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _joined
                    ? accent.withValues(alpha: .10)
                    : Colors.black.withValues(alpha: dark ? .12 : .045),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 18,
                bottom: 18,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: accent.withValues(alpha: .12),
                          backgroundImage: photo != null && photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null || photo.isEmpty
                              ? Text(
                                  authorName.characters.first.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
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
                                      style: GoogleFonts.inter(
                                        color: scheme.onSurface,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '· ${widget.post.timeAgo}',
                                    style: GoogleFonts.inter(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 10.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    _categoryIcon(widget.post.category),
                                    color: accent,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.post.category.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: accent,
                                      fontSize: 8.8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isMine && widget.onDelete != null)
                          PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
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
                          ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 12, color: accent),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel,
                            style: GoogleFonts.inter(
                              color: accent,
                              fontSize: 8,
                              letterSpacing: .7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      widget.post.text,
                      style: GoogleFonts.inter(
                        color: scheme.onSurface.withValues(alpha: .92),
                        fontSize: 14.2,
                        height: 1.5,
                      ),
                    ),
                    if (widget.post.mediaUrl != null &&
                        widget.post.mediaUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            widget.post.mediaUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 900,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
                    Divider(
                      height: 1,
                      color: scheme.outline.withValues(alpha: .11),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _PrayerJoinButton(
                            joined: _joined,
                            count: _joinCount,
                            color: accent,
                            onTap: _toggleJoin,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _ModernPostAction(
                          icon: Icons.mode_comment_outlined,
                          label: '${widget.post.comments}',
                          onTap: widget.onComment,
                        ),
                        _ModernPostAction(
                          icon: Icons.ios_share_outlined,
                          tooltip: 'Compartir',
                          onTap: widget.onShare,
                        ),
                      ],
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

class _PrayerJoinButton extends StatelessWidget {
  final bool joined;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _PrayerJoinButton({
    required this.joined,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: joined ? color.withValues(alpha: .13) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              joined
                  ? Icons.volunteer_activism
                  : Icons.volunteer_activism_outlined,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                joined ? 'Acompañando · $count' : 'Me uno · $count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernPostAction extends StatelessWidget {
  final IconData icon;
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
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 39,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 11,
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

// TODO: retirar tras verificar la migración visual en todos los dispositivos.
// ignore: unused_element
class _LegacyFeedPostTileState extends State<_FeedPostTile> {
  bool _optimisticLiked = false;
  int _optimisticLikeCount = 0;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _optimisticLiked = widget.post.isLiked;
    _optimisticLikeCount = widget.post.likes;
  }

  @override
  void didUpdateWidget(_FeedPostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar si el post cambió y no estamos en medio de una actualización
    if (!_isUpdating && oldWidget.postId != widget.postId) {
      _optimisticLiked = widget.post.isLiked;
      _optimisticLikeCount = widget.post.likes;
    }
  }

  Future<void> _handleLike() async {
    if (_isUpdating || widget.currentUid.isEmpty) return;

    final wasLiked = _optimisticLiked;
    final oldCount = _optimisticLikeCount;

    setState(() {
      _isUpdating = true;
      _optimisticLiked = !_optimisticLiked;
      // Si estaba liked, ahora no lo está, entonces restamos 1
      // Si no estaba liked, ahora lo está, entonces sumamos 1
      _optimisticLikeCount = _optimisticLiked ? oldCount + 1 : oldCount - 1;
    });

    try {
      await widget.service.togglePostLike(widget.postId, widget.currentUid);
    } catch (e) {
      // Revertir en caso de error
      if (mounted) {
        setState(() {
          _optimisticLiked = wasLiked;
          _optimisticLikeCount = oldCount;
        });
      }
      debugPrint('Error toggling like: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black12.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: widget.post.authorUid.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.post.authorUid)
                              .snapshots()
                        : null,
                    builder: (context, profileSnapshot) {
                      final profileData = profileSnapshot.data?.data();
                      final displayName =
                          ((profileData?['displayName'] as String?) ??
                                  widget.post.userName)
                              .trim();
                      final username =
                          ((profileData?['username'] as String?) ?? '').trim();
                      final authorPhoto =
                          (profileData?['photoURL'] as String?) ??
                          widget.post.authorPhoto;
                      final isMine =
                          widget.currentUid.isNotEmpty &&
                          widget.post.authorUid == widget.currentUid;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.deepPurple.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage: authorPhoto != null
                                ? NetworkImage(authorPhoto)
                                : null,
                            child: authorPhoto == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName
                                            : 'Anónimo',
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1F1F1F),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMine) ...[
                                      const SizedBox(width: 6),
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
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Tú',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                    Text(
                                      '· ${widget.post.timeAgo}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${username.isNotEmpty ? username : 'sin-username'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.post.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    color: const Color(0xFF1F1F1F),
                                  ),
                                ),
                                if (widget.post.mediaUrl != null) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.network(
                                        widget.post.mediaUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        cacheWidth: 800,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    StreamBuilder<int>(
                                      stream: widget.service
                                          .getPostLikeCountStream(
                                            widget.postId,
                                          ),
                                      builder: (context, countSnapshot) {
                                        if (!_isUpdating &&
                                            countSnapshot.hasData) {
                                          final realCount = countSnapshot.data!;
                                          if (_optimisticLikeCount !=
                                              realCount) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted && !_isUpdating) {
                                                    setState(() {
                                                      _optimisticLikeCount =
                                                          realCount;
                                                    });
                                                  }
                                                });
                                          }
                                        }

                                        final displayCount = _isUpdating
                                            ? _optimisticLikeCount
                                            : (countSnapshot.data ??
                                                  _optimisticLikeCount);

                                        return StreamBuilder<bool>(
                                          stream: widget.currentUid.isNotEmpty
                                              ? widget.service
                                                    .isPostLikedStream(
                                                      widget.postId,
                                                      widget.currentUid,
                                                    )
                                              : Stream.value(false),
                                          builder: (context, likedSnapshot) {
                                            if (!_isUpdating &&
                                                likedSnapshot.hasData) {
                                              final streamLiked =
                                                  likedSnapshot.data!;
                                              if (_optimisticLiked !=
                                                  streamLiked) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      if (mounted &&
                                                          !_isUpdating) {
                                                        setState(() {
                                                          _optimisticLiked =
                                                              streamLiked;
                                                        });
                                                      }
                                                    });
                                              }
                                            }

                                            final isLiked = _isUpdating
                                                ? _optimisticLiked
                                                : (likedSnapshot.data ??
                                                      _optimisticLiked);

                                            return _ActionButton(
                                              icon: isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              label: '$displayCount',
                                              color: isLiked
                                                  ? Colors.redAccent
                                                  : Colors.grey[700]!,
                                              onTap: _handleLike,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.mode_comment_outlined,
                                      label: '${widget.post.comments}',
                                      color: Colors.grey[700]!,
                                      onTap: widget.onComment,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.share_outlined,
                                      label: 'Compartir',
                                      color: Colors.grey[700]!,
                                      onTap: widget.onShare,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isMine && widget.onDelete != null)
                            PopupMenuButton<String>(
                              tooltip: 'Opciones',
                              onSelected: (value) {
                                if (value == 'delete') {
                                  widget.onDelete?.call();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Eliminar publicación'),
                                ),
                              ],
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafeArea = mediaQuery.viewPadding.bottom;
    final modalBottomPadding = bottomInset > 0
        ? bottomInset + 8
        : bottomSafeArea + 8;
    final text = _textController.text.trim();
    final canPost = text.length >= 10 && !_isSubmitting;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: modalBottomPadding),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva oración',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Comparte tu petición con la comunidad',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.2),
                          width: _focusNode.hasFocus ? 2 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu petición aquí...',
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 5,
                        minLines: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Character counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$_charCount / 10 caracteres mínimos',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: canPost
                                ? Colors.green[600]
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Category selector
                    Text(
                      'Categoría',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.primary,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Salud',
                            child: Row(
                              children: [
                                Text('🏥'),
                                SizedBox(width: 12),
                                Text('Salud'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Familia',
                            child: Row(
                              children: [
                                Text('👨‍👩‍👧‍👦'),
                                SizedBox(width: 12),
                                Text('Familia'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Fortaleza',
                            child: Row(
                              children: [
                                Text('🚨'),
                                SizedBox(width: 12),
                                Text('Fortaleza'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Gratitud',
                            child: Row(
                              children: [
                                Text('🙏'),
                                SizedBox(width: 12),
                                Text('Gratitud'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: canPost
                            ? () async {
                                setState(() => _isSubmitting = true);
                                final didPublish = await widget.onPost(
                                  text,
                                  _selectedCategory,
                                );
                                if (!context.mounted) return;
                                if (didPublish) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerHighest,
                          disabledForegroundColor: colorScheme.onSurface
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: canPost ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSubmitting)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            else ...[
                              Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: canPost
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _isSubmitting ? 'Publicando...' : 'Publicar',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
