import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_scaffold.dart';

class LivePost {
  final String id;
  String userName;
  String text;
  String timeAgo;
  String? mediaUrl;
  bool isVideo;
  int joinCount;
  int likes;
  int comments;
  bool isJoined;

  LivePost({
    required this.id,
    required this.userName,
    required this.text,
    required this.timeAgo,
    this.mediaUrl,
    bool? isVideo,
    this.joinCount = 0,
    this.likes = 0,
    this.comments = 0,
    bool? isJoined,
  })  : isJoined = isJoined ?? false,
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
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  void _loadInitialPosts() {
    setState(() {
      _posts = [
        LivePost(
          id: '1',
          userName: 'María',
          text: 'Ayúdenme a orar por la salud de mi mamá. Ella está pasando por un momento difícil y necesitamos la fuerza de Dios.',
          timeAgo: 'hace 2 h',
          mediaUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=80',
          joinCount: 12,
          likes: 5,
          comments: 3,
          isJoined: false,
        ),
        LivePost(
          id: '2',
          userName: 'Carlos',
          text: 'Demos gracias por un nuevo día y por nuestra familia. Que Dios bendiga cada momento de este día.',
          timeAgo: 'hace 3 h',
          mediaUrl:
              'https://images.unsplash.com/photo-1520854221050-0f4caff449fb?auto=format&fit=crop&w=1200&q=80',
          joinCount: 8,
          likes: 4,
          comments: 1,
          isJoined: false,
        ),
        LivePost(
          id: '3',
          userName: 'Ana',
          text: 'Pido oración por mi trabajo. Necesito sabiduría y dirección en las decisiones que debo tomar esta semana.',
          timeAgo: 'hace 5 h',
          mediaUrl:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
          isVideo: true,
          joinCount: 15,
          likes: 7,
          comments: 2,
          isJoined: false,
        ),
        LivePost(
          id: '4',
          userName: 'Pedro',
          text: 'Oremos juntos por la paz en el mundo. Que el amor de Cristo llene cada corazón y traiga reconciliación.',
          timeAgo: 'hace 6 h',
          mediaUrl:
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=1200&q=80',
          joinCount: 22,
          likes: 10,
          comments: 5,
          isJoined: false,
        ),
        LivePost(
          id: '5',
          userName: 'Laura',
          text: 'Gracias a Dios por las bendiciones recibidas. Quiero compartir mi gratitud con todos ustedes.',
          timeAgo: 'hace 8 h',
          mediaUrl:
              'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1200&q=80',
          joinCount: 18,
          likes: 9,
          comments: 4,
          isJoined: false,
        ),
      ];
    });
  }

  void _loadMorePosts() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    // Simular carga asíncrona
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final newPosts = [
        LivePost(
          id: '${_posts.length + 1}',
          userName: 'Usuario ${_posts.length + 1}',
          text: 'Oración de ejemplo ${_posts.length + 1}. Que Dios bendiga a todos los que están aquí orando juntos.',
          timeAgo: 'hace ${_posts.length + 1} h',
          mediaUrl:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
          isVideo: (_posts.length % 2 == 0),
          joinCount: _posts.length * 2,
          likes: _posts.length,
          comments: _posts.length ~/ 2,
          isJoined: false,
        ),
        LivePost(
          id: '${_posts.length + 2}',
          userName: 'Usuario ${_posts.length + 2}',
          text: 'Petición de oración ${_posts.length + 2}. Necesitamos la guía del Señor en este momento.',
          timeAgo: 'hace ${_posts.length + 2} h',
          mediaUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=80',
          joinCount: (_posts.length + 1) * 2,
          likes: _posts.length + 1,
          comments: (_posts.length + 1) ~/ 2,
          isJoined: false,
        ),
      ];
      setState(() {
        _posts.addAll(newPosts);
        _isLoadingMore = false;
      });
    });
  }

  void _toggleJoin(LivePost post) {
    setState(() {
      if (post.isJoined) {
        post.isJoined = false;
        post.joinCount = (post.joinCount - 1).clamp(0, double.infinity).toInt();
      } else {
        post.isJoined = true;
        post.joinCount += 1;
      }
    });
  }

  void _openComments(LivePost post) {
    // Comentarios mock
    final mockComments = [
      LiveComment(
        id: 'c1',
        userName: 'Juan',
        text: 'Estoy orando contigo. Que Dios te bendiga.',
        timeAgo: 'hace 1 h',
      ),
      LiveComment(
        id: 'c2',
        userName: 'Sofía',
        text: 'Unámonos en oración. El Señor escucha nuestras peticiones.',
        timeAgo: 'hace 30 min',
      ),
      LiveComment(
        id: 'c3',
        userName: 'Miguel',
        text: 'Dios está contigo. Confía en Él.',
        timeAgo: 'hace 15 min',
      ),
    ];

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
                'Comentarios (${post.comments})',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mockComments.length,
                  itemBuilder: (context, index) {
                    final comment = mockComments[index];
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
                              comment.userName.isNotEmpty
                                  ? comment.userName[0].toUpperCase()
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
                                  comment.userName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.timeAgo,
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
                    onPressed: () {
                      final text = commentController.text.trim();
                      if (text.isNotEmpty) {
                        // Aquí se agregaría el comentario (mock por ahora)
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comentario agregado (mock)'),
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

  void _createPost() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostModal(
        textController: textController,
        onPost: (text, category) {
          setState(() {
            _posts.insert(
              0,
              LivePost(
                id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                userName: 'Tú',
                text: '$text [$category]',
                timeAgo: 'ahora',
                joinCount: 0,
                isJoined: false,
              ),
            );
          });
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
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      centerTitle: false,
      showAppBar: true,
      resizeToAvoidBottomInset: true,
      body: _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeedPostTile(
                    post: post,
                    onJoin: () => _toggleJoin(post),
                    onComment: () => _openComments(post),
                    onShare: () => _sharePost(post),
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

class _FeedPostTile extends StatelessWidget {
  final LivePost post;
  final VoidCallback onJoin;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _FeedPostTile({
    required this.post,
    required this.onJoin,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isJoined = post.isJoinedValue;
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepPurple.withOpacity(0.12),
                  child: Text(
                    post.userName.isNotEmpty
                        ? post.userName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
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
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_outlined,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ActionButton(
                            icon: isJoined
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: '${post.joinCount}',
                            color:
                                isJoined ? Colors.redAccent : Colors.grey[700]!,
                            onTap: onJoin,
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
