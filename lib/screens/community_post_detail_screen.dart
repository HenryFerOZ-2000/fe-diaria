import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Publicación',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Publicación no disponible.',
                        style: GoogleFonts.inter(),
                        textAlign: TextAlign.center,
                      ),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage:
                                authorPhotoUrl != null &&
                                    authorPhotoUrl.isNotEmpty
                                ? NetworkImage(authorPhotoUrl)
                                : null,
                            child:
                                authorPhotoUrl == null || authorPhotoUrl.isEmpty
                                ? Text(
                                    authorName.isNotEmpty
                                        ? authorName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : null,
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
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(ts?.toDate()),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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
                      const SizedBox(height: 14),
                      Text(
                        text,
                        style: GoogleFonts.inter(fontSize: 15, height: 1.45),
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(
              'Comentarios',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
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
