import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/post_social_service.dart';

/// Fila like + comentarios para publicaciones de comunidad (misma idea que En Vivo).
class CommunityPostInteractionRow extends StatefulWidget {
  final String postId;
  final String currentUid;
  final PostSocialService service;
  final int seedLikeCount;
  final int seedCommentCount;
  final VoidCallback onOpenComments;

  const CommunityPostInteractionRow({
    super.key,
    required this.postId,
    required this.currentUid,
    required this.service,
    this.seedLikeCount = 0,
    this.seedCommentCount = 0,
    required this.onOpenComments,
  });

  @override
  State<CommunityPostInteractionRow> createState() =>
      _CommunityPostInteractionRowState();
}

class _CommunityPostInteractionRowState
    extends State<CommunityPostInteractionRow> {
  bool _optimisticLiked = false;
  int _optimisticLikeCount = 0;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _optimisticLikeCount = widget.seedLikeCount;
  }

  @override
  void didUpdateWidget(covariant CommunityPostInteractionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _optimisticLikeCount = widget.seedLikeCount;
      _optimisticLiked = false;
    }
  }

  Future<void> _handleLike() async {
    if (_isUpdating || widget.currentUid.isEmpty) return;

    final wasLiked = _optimisticLiked;
    final oldCount = _optimisticLikeCount;

    setState(() {
      _isUpdating = true;
      _optimisticLiked = !_optimisticLiked;
      _optimisticLikeCount = _optimisticLiked ? oldCount + 1 : oldCount - 1;
    });

    try {
      await widget.service.togglePostLike(widget.postId, widget.currentUid);
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticLiked = wasLiked;
          _optimisticLikeCount = oldCount;
        });
      }
      debugPrint('CommunityPostInteractionRow like error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neutral = scheme.onSurfaceVariant;

    return Row(
      children: [
        StreamBuilder<int>(
          stream: widget.service.getPostLikeCountStream(widget.postId),
          builder: (context, countSnapshot) {
            if (!_isUpdating && countSnapshot.hasData) {
              final realCount = countSnapshot.data!;
              if (_optimisticLikeCount != realCount) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isUpdating) {
                    setState(() => _optimisticLikeCount = realCount);
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
                if (!_isUpdating && likedSnapshot.hasData) {
                  final streamLiked = likedSnapshot.data!;
                  if (_optimisticLiked != streamLiked) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_isUpdating) {
                        setState(() => _optimisticLiked = streamLiked);
                      }
                    });
                  }
                }

                final isLiked = _isUpdating
                    ? _optimisticLiked
                    : (likedSnapshot.data ?? _optimisticLiked);

                return _MiniAction(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '$displayCount',
                  color: isLiked ? scheme.primary : neutral,
                  onTap: _handleLike,
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
        StreamBuilder<int>(
          stream: widget.service.getPostCommentCountStream(widget.postId),
          builder: (context, snap) {
            final n = snap.data ?? widget.seedCommentCount;
            return _MiniAction(
              icon: Icons.mode_comment_outlined,
              label: '$n',
              color: neutral,
              onTap: widget.onOpenComments,
            );
          },
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniAction({
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
