import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

import '../services/community_posts_social_service.dart';
import '../services/post_social_service.dart';
import '../widgets/community_post_interaction_row.dart';
import 'comments_screen.dart';

/// Detalle de una publicación de [community_posts]: texto, likes y hilo de comentarios.
class CommunityPostDetailScreen extends StatelessWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  static String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'ahora';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final social = CommunityPostsSocialService();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final p = context.palette;
    final t = context.type;

    return Scaffold(
      appBar: VAppBar(title: Text('Publicación', style: t.heading)),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            flex: 4,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(postId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: VEmptyState(title: 'Cargando', loading: true),
                  );
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(
                    child: VEmptyState(
                      icon: VerbumIcons.chatCircleText,
                      title: 'Publicación no disponible',
                      message: 'Puede que se haya eliminado.',
                    ),
                  );
                }
                final d = snap.data!.data() ?? {};
                final authorName = ((d['authorName'] as String?) ?? 'Miembro')
                    .trim();
                final authorPhotoUrl = (d['authorPhotoUrl'] as String?)?.trim();
                final text = ((d['text'] as String?) ?? '').trim();
                final ts = d['createdAt'] as Timestamp?;
                final likes = firestoreIntCount(d['likeCount']);
                final comments = firestoreIntCount(d['commentCount']);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    VerbumSpace.gutter,
                    4,
                    VerbumSpace.gutter,
                    8,
                  ),
                  child: VSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(
                              name: authorName,
                              photo: authorPhotoUrl,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName.isNotEmpty
                                        ? authorName
                                        : 'Miembro',
                                    style: t.bodyStrong.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimeAgo(ts?.toDate()),
                                    style: t.caption.copyWith(
                                      color: p.inkSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          text,
                          style: t.body.copyWith(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        CommunityPostInteractionRow(
                          postId: postId,
                          currentUid: uid,
                          service: social,
                          seedLikeCount: likes,
                          seedCommentCount: comments,
                          onOpenComments: () {
                            // El hilo ya está debajo; opcional: enfocar campo de comentario.
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter + 2,
              8,
              VerbumSpace.gutter,
              6,
            ),
            child: Text('Comentarios', style: t.heading.copyWith(fontSize: 17)),
          ),
          Expanded(
            flex: 6,
            child: CommentsScreen(
              postId: postId,
              socialService: social,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar: foto o inicial sobre lavanda.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photo, this.size = 40});

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
