import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/post_card.dart';

class LivePost {
  String userName;
  String text;
  String timeAgo;
  int joinCount;
  int likes;
  int comments;
  LivePost({
    required this.userName,
    required this.text,
    required this.timeAgo,
    this.joinCount = 0,
    this.likes = 0,
    this.comments = 0,
  });
}

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final List<LivePost> _posts = [
    LivePost(
      userName: 'María',
      text: 'Ayúdenme a orar por la salud de mi mamá.',
      timeAgo: 'hace 2 h',
      joinCount: 12,
      likes: 5,
      comments: 3,
    ),
    LivePost(
      userName: 'Carlos',
      text: 'Demos gracias por un nuevo día y por nuestra familia.',
      timeAgo: 'hace 3 h',
      joinCount: 8,
      likes: 4,
      comments: 1,
    ),
  ];

  void _openComments(LivePost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
            Text(
              'Próximamente: conecta con Firestore para comentarios reales.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createPost() {
    final textController = TextEditingController();
    String selectedCategory = 'Salud';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Escribe tu petición',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Salud', child: Text('Salud')),
                  DropdownMenuItem(value: 'Familia', child: Text('Familia')),
                  DropdownMenuItem(value: 'Emergencia', child: Text('Emergencia')),
                  DropdownMenuItem(value: 'Gratitud', child: Text('Gratitud')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _posts.insert(
                      0,
                      LivePost(
                        userName: 'Tú',
                        text: '${textController.text} [$selectedCategory]',
                        timeAgo: 'ahora',
                        joinCount: 0,
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
                child: const Text('Publicar petición'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titleWidget: Row(
        children: [
          Text(
            'En Vivo',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return PostCard(
                userName: post.userName,
                text: post.text,
                timeAgo: post.timeAgo,
                joinCount: post.joinCount,
                likes: post.likes,
                comments: post.comments,
                onJoin: () {
                  setState(() {
                    post.joinCount += 1;
                  });
                  // TODO: Conectar con backend y misión "Unirse a una oración".
                },
                onLike: () {
                  setState(() {
                    post.likes += 1;
                  });
                },
                onComment: () => _openComments(post),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _createPost,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

