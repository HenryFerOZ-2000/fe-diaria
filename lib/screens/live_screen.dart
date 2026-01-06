import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_scaffold.dart';
import '../services/social_service.dart';
import '../services/live_posts_service.dart';
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
    bool? isVideo,
    this.joinCount = 0,
    this.likes = 0,
    this.comments = 0,
    bool? isLiked,
    bool? isJoined,
  })  : isJoined = isJoined ?? false,
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
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ScrollController _scrollController = ScrollController();
  List<LivePost> _posts = [];
  bool _isPosting = false;
  final Set<String> _likedPosts = {};
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _auth = FirebaseAuth.instance;
  final _social = SocialService();
  final _livePostsService = LivePostsService();
  String? _uid;

  @override
  void initState() {
    super.initState();
    _ensureAuth().then((_) {
      _syncProfileToFirestore();
      _loadLikes();
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
    _uid = _auth.currentUser?.uid;
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

  Future<void> _loadLikes() async {
    try {
      await _ensureAuth();
      final uid = _uid;
      if (uid == null) return;
      final likesSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('likes')
          .limit(500)
          .get();
      final ids = likesSnap.docs.map((d) => d.id).toSet();
      if (mounted) {
        setState(() {
          _likedPosts
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (e) {
      debugPrint('Error loading likes: $e');
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

  Future<void> _insertPostById(String postId) async {
    try {
      final doc = await _firestore.collection('live_posts').doc(postId).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      if (_posts.any((p) => p.id == doc.id)) return;
      final now = DateTime.now();
      final ts = data['createdAt'] as Timestamp?;
      final post = LivePost(
        id: doc.id,
        authorUid: data['authorUid'] as String? ?? '',
        userName: (data['authorUsername'] as String?) ??
            (data['authorName'] as String?) ??
            (data['authorUid'] as String?) ??
            'Anónimo',
        authorPhoto: data['authorPhoto'] as String?,
        text: data['text'] as String? ?? '',
        timeAgo: _formatTimeAgo(ts?.toDate(), now),
        joinCount: (data['joinCount'] ?? 0) as int,
        likes: (data['likeCount'] ?? 0) as int,
        comments: (data['commentCount'] ?? 0) as int,
        isJoined: false,
      );
      if (mounted) {
        setState(() {
          _posts = [post, ..._posts];
        });
      }
    } catch (e) {
      debugPrint('Error fetching post $postId: $e');
    }
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
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: post.id),
      ),
    );
  }

  void _sharePost(LivePost post) {
    Share.share(
      '${post.text}\n\n- ${post.userName}',
      subject: 'Oración en vivo',
    );
  }

  void _openProfile(String uid) {
    if (uid.isEmpty) return;
    final me = _auth.currentUser?.uid;
    final route = me != null && me == uid ? '/my-profile' : '/public-profile';
    Navigator.of(context).pushNamed(route, arguments: uid);
  }

  Future<void> _submitPost(String text) async {
    final trimmed = text.trim();
    if (trimmed.length < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe al menos 10 caracteres')),
        );
      }
      return;
    }
    if (_isPosting) return;
    if (_auth.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    setState(() {
      _isPosting = true;
    });
    try {
      final callable = _functions.httpsCallable('createLivePost');
      final result = await callable.call<Map<String, dynamic>>({'text': trimmed});
      final postId = result.data['postId'] as String?;
      if (!mounted) return;
      if (postId != null) {
        await _insertPostById(postId);
        // Incrementar contador de publicaciones creadas
        final spiritualStatsService = SpiritualStatsService();
        await spiritualStatsService.incrementPostCreated();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación creada.')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error al publicar')),
      );
      debugPrint('createLivePost error code=${e.code} message=${e.message} details=${e.details}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _createPost() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostModal(
        textController: textController,
        onPost: (text, category) {
          _submitPost(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      titleWidget: Row(
        children: [
          Text(
            'En Vivo',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search-users'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      centerTitle: false,
      showAppBar: true,
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              userName: (data['authorUsername'] as String?) ??
                  (data['authorName'] as String?) ??
                  data['authorUid'] as String? ??
                  'Anónimo',
              authorPhoto: data['authorPhoto'] as String?,
              text: data['text'] as String? ?? '',
              timeAgo: _formatTimeAgo(ts?.toDate(), now),
              joinCount: (data['joinCount'] ?? 0) as int,
              likes: (data['likeCount'] ?? 0) as int,
              comments: (data['commentCount'] ?? 0) as int,
              isLiked: _likedPosts.contains(doc.id),
            );
          }).toList();

          if (posts.isEmpty) {
            return const Center(child: Text('Aún no hay publicaciones'));
          }

          return RefreshIndicator(
            onRefresh: _refreshFeed,
            color: colorScheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
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
                    onAuthorTap: post.authorUid.isNotEmpty
                        ? () => _openProfile(post.authorUid)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
      ),
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
  final VoidCallback? onAuthorTap;

  const _FeedPostTile({
    required this.postId,
    required this.post,
    required this.service,
    required this.currentUid,
    required this.onComment,
    required this.onShare,
    this.onAuthorTap,
  });

  @override
  State<_FeedPostTile> createState() => _FeedPostTileState();
}

class _FeedPostTileState extends State<_FeedPostTile> {
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.onAuthorTap,
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepPurple.withOpacity(0.12),
                    backgroundImage: widget.post.authorPhoto != null
                        ? NetworkImage(widget.post.authorPhoto!)
                        : null,
                    child: widget.post.authorPhoto == null
                        ? Text(
                            widget.post.userName.isNotEmpty
                                ? widget.post.userName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
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
                              widget.post.userName,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F1F1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_outlined,
                                      color: Colors.grey),
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
                          // Like button con StreamBuilder para likeCount real
                          StreamBuilder<int>(
                            stream: widget.service.getPostLikeCountStream(widget.postId),
                            builder: (context, countSnapshot) {
                              // Si no estamos actualizando y tenemos datos del stream, sincronizar
                              if (!_isUpdating && countSnapshot.hasData) {
                                final realCount = countSnapshot.data!;
                                if (_optimisticLikeCount != realCount) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted && !_isUpdating) {
                                      setState(() {
                                        _optimisticLikeCount = realCount;
                                      });
                                    }
                                  });
                                }
                              }
                              
                              final displayCount = _isUpdating 
                                  ? _optimisticLikeCount 
                                  : (countSnapshot.data ?? _optimisticLikeCount);
                              
                              return StreamBuilder<bool>(
                                stream: widget.currentUid.isNotEmpty
                                    ? widget.service.isPostLikedStream(
                                        widget.postId,
                                        widget.currentUid,
                                      )
                                    : Stream.value(false),
                                builder: (context, likedSnapshot) {
                                  // Si no estamos actualizando y tenemos datos del stream, sincronizar
                                  if (!_isUpdating && likedSnapshot.hasData) {
                                    final streamLiked = likedSnapshot.data!;
                                    if (_optimisticLiked != streamLiked) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted && !_isUpdating) {
                                          setState(() {
                                            _optimisticLiked = streamLiked;
                                          });
                                        }
                                      });
                                    }
                                  }
                                  
                                  final isLiked = _isUpdating 
                                      ? _optimisticLiked 
                                      : (likedSnapshot.data ?? _optimisticLiked);
                                  
                                  return _ActionButton(
                                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                                    label: '$displayCount',
                                    color: isLiked ? Colors.redAccent : Colors.grey[700]!,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostModal extends StatefulWidget {
  final TextEditingController textController;
  final Function(String text, String category) onPost;

  const _CreatePostModal({
    required this.textController,
    required this.onPost,
  });

  @override
  State<_CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<_CreatePostModal> {
  String _selectedCategory = 'Salud';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.textController,
              decoration: const InputDecoration(
                labelText: 'Escribe tu petición',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Salud', child: Text('Salud')),
                DropdownMenuItem(value: 'Familia', child: Text('Familia')),
                DropdownMenuItem(
                    value: 'Emergencia', child: Text('Emergencia')),
                DropdownMenuItem(value: 'Gratitud', child: Text('Gratitud')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final text = widget.textController.text.trim();
                if (text.isNotEmpty) {
                  widget.onPost(text, _selectedCategory);
                  Navigator.pop(context);
                }
              },
              child: const Text('Publicar petición'),
            ),
          ],
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

