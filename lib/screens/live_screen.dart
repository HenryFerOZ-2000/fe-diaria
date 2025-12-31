import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_scaffold.dart';
import '../services/social_service.dart';

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

enum LiveFilter { all, active }

class _LiveScreenState extends State<LiveScreen> {
  LiveFilter _filter = LiveFilter.all;
  final ScrollController _scrollController = ScrollController();
  List<LivePost> _posts = [];
  bool _isPosting = false;
  final Set<String> _likedPosts = {};
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _auth = FirebaseAuth.instance;
  final _social = SocialService();
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
    final base = _firestore.collection('live_posts');
    if (_filter == LiveFilter.active) {
      return base
          .where('status', isEqualTo: 'active')
          .where('liveUntil', isGreaterThan: Timestamp.now())
          .orderBy('liveUntil', descending: true)
          .limit(50);
    }
    return base.orderBy('createdAt', descending: true).limit(50);
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

  Future<void> _toggleLike(LivePost post) async {
    await _ensureAuth();
    final uid = _uid;
    if (uid == null) return;
    final isLikedNow = _likedPosts.contains(post.id);
    setState(() {
      if (isLikedNow) {
        _likedPosts.remove(post.id);
      } else {
        _likedPosts.add(post.id);
      }
    });
    try {
      final postRef = _firestore.collection('live_posts').doc(post.id);
      final likeRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('likes')
          .doc(post.id);
      await _firestore.runTransaction((tx) async {
        tx.update(
          postRef,
          {'likeCount': FieldValue.increment(isLikedNow ? -1 : 1)},
        );
        if (isLikedNow) {
          tx.delete(likeRef);
        } else {
          tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        }
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  void _openComments(LivePost post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
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
              ),
              const SizedBox(height: 12),
              Text(
                'Comentarios',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('live_posts')
                      .doc(post.id)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar comentarios',
                          style: GoogleFonts.inter(),
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Sé el primero en comentar'));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final text = data['text'] as String? ?? '';
                        final author = data['authorName'] as String? ??
                            data['authorUid'] as String? ??
                            'Anónimo';
                        final created = data['createdAt'] as Timestamp?;
                        final timeAgo = _formatTimeAgo(
                          created?.toDate(),
                          DateTime.now(),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                child: Text(
                                  author.isNotEmpty
                                      ? author[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
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
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;
                      await _ensureAuth();
                      final uid = _uid;
                      if (uid == null) return;
                      final authorName = _auth.currentUser?.displayName ??
                          _auth.currentUser?.email?.split('@').first ??
                          uid;
                      try {
                        final postRef =
                            _firestore.collection('live_posts').doc(post.id);
                        final commentsRef = postRef.collection('comments');
                        await _firestore.runTransaction((tx) async {
                          tx.set(commentsRef.doc(), {
                            'text': text,
                            'authorUid': uid,
                            'authorName': authorName,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          tx.update(
                            postRef,
                            {'commentCount': FieldValue.increment(1)},
                          );
                        });
                        commentController.clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comentario agregado'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al comentar: $e'),
                          ),
                        );
                      }
                    },
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filter == LiveFilter.all,
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _filter = LiveFilter.all;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('En vivo'),
                  selected: _filter == LiveFilter.active,
                  onSelected: (v) {
                    if (v) {
                      setState(() {
                        _filter = LiveFilter.active;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedPostTile(
                          post: post,
                          onLike: () => _toggleLike(post),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FeedPostTile extends StatelessWidget {
  final LivePost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onAuthorTap;

  const _FeedPostTile({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onAuthorTap,
  });

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
                  onTap: onAuthorTap,
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepPurple.withOpacity(0.12),
                    backgroundImage:
                        post.authorPhoto != null ? NetworkImage(post.authorPhoto!) : null,
                    child: post.authorPhoto == null
                        ? Text(
                            post.userName.isNotEmpty
                                ? post.userName[0].toUpperCase()
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
                              post.userName,
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
                            '· ${post.timeAgo}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.text,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          height: 1.45,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      if (post.mediaUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              post.mediaUrl!,
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
                              cacheWidth: 800, // Optimize image loading
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ActionButton(
                            icon:
                                post.isLiked ? Icons.favorite : Icons.favorite_border,
                            label: '${post.likes}',
                            color: post.isLiked
                                ? Colors.redAccent
                                : Colors.grey[700]!,
                            onTap: onLike,
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.mode_comment_outlined,
                            label: '${post.comments}',
                            color: Colors.grey[700]!,
                            onTap: onComment,
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.share_outlined,
                            label: 'Compartir',
                            color: Colors.grey[700]!,
                            onTap: onShare,
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

