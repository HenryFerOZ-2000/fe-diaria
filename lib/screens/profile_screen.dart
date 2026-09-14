import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/profile_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'welcome_auth_screen.dart';

class MySocialProfileScreen extends StatefulWidget {
  final int? initialTabIndex;
  const MySocialProfileScreen({super.key, this.initialTabIndex});

  @override
  State<MySocialProfileScreen> createState() => _MySocialProfileScreenState();
}

class _MySocialProfileScreenState extends State<MySocialProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeAuthScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (_) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: VerbumAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(
                title: Text(
                  'Mis publicaciones',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Editar perfil',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/edit-profile'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _profileService.userStream(uid),
                  builder: (context, profileSnapshot) {
                    final profile =
                        profileSnapshot.data?.data() ?? <String, dynamic>{};
                    return _PostsList(
                      uid: uid,
                      profileService: _profileService,
                      displayName:
                          (profile['displayName'] as String?)?.trim() ?? '',
                      username: (profile['username'] as String?)?.trim() ?? '',
                      photoUrl: (profile['photoURL'] as String?)?.trim(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsList extends StatefulWidget {
  final String uid;
  final ProfileService profileService;
  final String displayName;
  final String username;
  final String? photoUrl;

  const _PostsList({
    required this.uid,
    required this.profileService,
    required this.displayName,
    required this.username,
    required this.photoUrl,
  });

  @override
  State<_PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<_PostsList> {
  Future<void> _deletePost(String postId, String postText) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
        title: Text(
          'Eliminar publicación',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta publicación desaparecerá de la comunidad y no podrás recuperarla.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                postText.length > 100
                    ? '${postText.substring(0, 100)}…'
                    : postText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Eliminando publicación…')),
    );
    try {
      await widget.profileService.deletePost(postId);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo eliminar (${error.code})')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la publicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.profileService.userPosts(widget.uid, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos cargar tus publicaciones',
            message: 'Revisa tu conexión e inténtalo nuevamente.',
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (snapshot.connectionState == ConnectionState.waiting &&
            docs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (docs.isEmpty) {
          return const _MessageState(
            icon: Icons.forum_outlined,
            title: 'Tu voz aún tiene espacio',
            message:
                'Cuando compartas una oración o reflexión en Comunidad, aparecerá aquí.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _CollectionIntro(count: docs.length),
              );
            }
            final doc = docs[index - 1];
            final data = doc.data();
            final text = data['text'] as String? ?? '';
            final createdAt = data['createdAt'];
            final created = createdAt is Timestamp
                ? createdAt.toDate().toLocal()
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: .85),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: widget.photoUrl?.isNotEmpty == true
                            ? NetworkImage(widget.photoUrl!)
                            : null,
                        child: widget.photoUrl?.isNotEmpty == true
                            ? null
                            : Text(
                                _initial,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.displayName.isEmpty
                                  ? 'Tú'
                                  : widget.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              created == null
                                  ? 'En Comunidad'
                                  : _formatDate(created),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar publicación',
                        onPressed: () => _deletePost(doc.id, text),
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.55,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Compartida en Comunidad',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String get _initial {
    final source = widget.displayName.isNotEmpty
        ? widget.displayName
        : widget.username;
    return source.isEmpty ? 'V' : source.characters.first.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Hace un momento';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CollectionIntro extends StatelessWidget {
  final int count;
  const _CollectionIntro({required this.count});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'publicación' : 'publicaciones'}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  'Una memoria de lo que has compartido',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(34),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: .7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 31, color: scheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
