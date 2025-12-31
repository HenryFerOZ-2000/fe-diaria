import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/profile_service.dart';
import '../services/social_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String? uid;
  const PublicProfileScreen({super.key, this.uid});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();
  final _social = SocialService();
  late final TabController _tabController;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _uid = widget.uid ?? ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openFollowers(String uid) {
    Navigator.of(context).pushNamed('/followers', arguments: uid);
  }

  void _openFollowing(String uid) {
    Navigator.of(context).pushNamed('/following', arguments: uid);
  }

  void _goToPostsTab() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final targetUid = _uid;
    final me = _auth.currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Perfil no encontrado')));
    }
    if (me != null && me == targetUid) {
      // Si soy yo, enviar a mi perfil social.
      Future.microtask(() => Navigator.of(context).pushReplacementNamed('/my-profile'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileService.userStream(targetUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Perfil no disponible'));
          }
          final data = snapshot.data!.data() ?? {};
          final displayName = data['displayName'] ?? 'Usuario';
          final username = data['username'] ?? '';
          final photoURL = data['photoURL'] as String?;
          final bio = data['bio'] ?? '';
          final followers = (data['followersCount'] ?? data['followerCount'] ?? 0) as int;
          final following = (data['followingCount'] ?? 0) as int;
          final posts = (data['postCount'] ?? data['postsCount'] ?? 0) as int;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('@$username',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                          if (bio.toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(bio, style: GoogleFonts.inter(fontSize: 14)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _metrics('Seguidores', followers, () => _openFollowers(targetUid)),
                              _metrics('Siguiendo', following, () => _openFollowing(targetUid)),
                              _metrics('Posts', posts, _goToPostsTab),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: StreamBuilder<bool>(
                    stream: _social.isFollowingStream(targetUid),
                    builder: (context, snap) {
                      final isFollowing = snap.data ?? false;
                      return ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            _social.unfollow(targetUid);
                          } else {
                            _social.follow(targetUid);
                          }
                        },
                        child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Guardados'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PublicPostsTab(uid: targetUid, profileService: _profileService),
                    const _PlaceholderTab(text: 'Guardados del usuario'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metrics(String label, int value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text('$value', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _PublicPostsTab extends StatelessWidget {
  final String uid;
  final ProfileService profileService;
  const _PublicPostsTab({required this.uid, required this.profileService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: profileService.userPosts(uid, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar posts'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Sin publicaciones todavía'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final text = data['text'] as String? ?? '';
            final created = data['createdAt'] as Timestamp?;
            final time = created != null ? created.toDate().toLocal().toString() : '';
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: GoogleFonts.inter(fontSize: 15, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(time, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String text;
  const _PlaceholderTab({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text));
  }
}


