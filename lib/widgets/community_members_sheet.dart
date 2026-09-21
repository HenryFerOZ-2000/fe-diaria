import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'verbum_ambient_background.dart';
import 'verbum_header_actions.dart';

enum CommunityMemberAction { promote, demote, transfer }

@immutable
class CommunityMemberViewData {
  final String uid;
  final String displayName;
  final String username;
  final String? photoUrl;
  final bool isOwner;
  final bool isAdmin;
  final bool isCurrentUser;

  const CommunityMemberViewData({
    required this.uid,
    required this.displayName,
    this.username = '',
    this.photoUrl,
    this.isOwner = false,
    this.isAdmin = false,
    this.isCurrentUser = false,
  });
}

@immutable
class CommunityMemberActionSelection {
  final CommunityMemberAction action;
  final CommunityMemberViewData member;

  const CommunityMemberActionSelection({
    required this.action,
    required this.member,
  });
}

class CommunityMembersPanel extends StatelessWidget {
  final List<CommunityMemberViewData> members;
  final bool canManage;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onClose;
  final ValueChanged<CommunityMemberActionSelection>? onActionSelected;
  final VoidCallback? onOpenAdvancedManagement;

  const CommunityMembersPanel({
    super.key,
    required this.members,
    required this.canManage,
    required this.onClose,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.onActionSelected,
    this.onOpenAdvancedManagement,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: VerbumAmbientBackground(
          glowAlignment: const Alignment(1.25, -1.1),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF493878), Color(0xFF261E45)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF261E45,
                              ).withValues(alpha: .2),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.groups_2_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUESTRA COMUNIDAD',
                              style: GoogleFonts.inter(
                                color: scheme.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Personas de la comunidad',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: scheme.onSurface,
                                fontSize: 24,
                                height: 1.08,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _MemberCountPill(count: members.length),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      VerbumHeaderButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Cerrar miembros',
                        onPressed: isSubmitting ? () {} : onClose,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                Expanded(child: _buildContent(context)),
                if (canManage && onOpenAdvancedManagement != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: scheme.primary.withValues(alpha: .24),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: isSubmitting ? null : onOpenAdvancedManagement,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Administración avanzada',
                                  style: GoogleFonts.inter(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return Semantics(
        label: 'Cargando miembros',
        child: const _MembersLoadingState(),
      );
    }
    if (errorMessage != null) {
      return _MembersMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos reunir a la comunidad',
        message: errorMessage!,
      );
    }
    if (members.isEmpty) {
      return const _MembersMessageState(
        icon: Icons.people_outline_rounded,
        title: 'Aún no hay miembros',
        message:
            'Cuando otras personas se unan, aparecerán aquí para caminar juntas.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _CommunityMemberCard(
        member: members[index],
        canManage: canManage,
        isSubmitting: isSubmitting,
        onActionSelected: onActionSelected,
      ),
    );
  }
}

class _MemberCountPill extends StatelessWidget {
  final int count;

  const _MemberCountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.secondary.withValues(alpha: .18)),
        ),
        child: Text(
          count == 1 ? '1 persona' : '$count personas',
          style: GoogleFonts.inter(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CommunityMemberCard extends StatelessWidget {
  final CommunityMemberViewData member;
  final bool canManage;
  final bool isSubmitting;
  final ValueChanged<CommunityMemberActionSelection>? onActionSelected;

  const _CommunityMemberCard({
    required this.member,
    required this.canManage,
    required this.isSubmitting,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlighted = member.isOwner || member.isCurrentUser;
    final name = member.displayName.trim().isEmpty
        ? 'Miembro'
        : member.displayName.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primary.withValues(alpha: dark ? .14 : .065)
            : scheme.surface.withValues(alpha: dark ? .72 : .88),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: member.isOwner
              ? scheme.secondary.withValues(alpha: .42)
              : scheme.outlineVariant.withValues(alpha: .9),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF261E45).withValues(alpha: .045),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MemberAvatar(member: member, name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.username.trim().isNotEmpty
                          ? '@${member.username.trim().replaceFirst(RegExp(r'^@'), '')}'
                          : 'Miembro de la comunidad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage && !member.isOwner) ...[
                const SizedBox(width: 6),
                PopupMenuButton<CommunityMemberAction>(
                  key: ValueKey('member-actions-${member.uid}'),
                  enabled: !isSubmitting,
                  tooltip: 'Gestionar a $name',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  color: scheme.surface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onSelected: (action) => onActionSelected?.call(
                    CommunityMemberActionSelection(
                      action: action,
                      member: member,
                    ),
                  ),
                  itemBuilder: (_) => member.isAdmin
                      ? const [
                          PopupMenuItem(
                            value: CommunityMemberAction.demote,
                            child: _MemberMenuItem(
                              icon: Icons.remove_moderator_outlined,
                              label: 'Quitar administración',
                            ),
                          ),
                          PopupMenuItem(
                            value: CommunityMemberAction.transfer,
                            child: _MemberMenuItem(
                              icon: Icons.change_circle_outlined,
                              label: 'Transferir liderazgo',
                            ),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: CommunityMemberAction.promote,
                            child: _MemberMenuItem(
                              icon: Icons.add_moderator_outlined,
                              label: 'Hacer administrador',
                            ),
                          ),
                        ],
                ),
              ],
            ],
          ),
          if (member.isOwner || member.isAdmin || member.isCurrentUser) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (member.isOwner)
                  const _MemberRolePill(
                    label: 'Principal',
                    icon: Icons.workspace_premium_outlined,
                    tone: _MemberRoleTone.gold,
                  )
                else if (member.isAdmin)
                  const _MemberRolePill(
                    label: 'Administrador',
                    icon: Icons.shield_outlined,
                    tone: _MemberRoleTone.plum,
                  ),
                if (member.isCurrentUser)
                  const _MemberRolePill(
                    label: 'Tú',
                    icon: Icons.person_outline_rounded,
                    tone: _MemberRoleTone.neutral,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final CommunityMemberViewData member;
  final String name;

  const _MemberAvatar({required this.member, required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = member.photoUrl?.trim();
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: member.isOwner
              ? const [Color(0xFFD8B875), Color(0xFF8E6A2E)]
              : [scheme.primary, scheme.tertiary],
        ),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: photo != null && photo.isNotEmpty
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _AvatarInitial(name: name),
                )
              : _AvatarInitial(name: name),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String name;

  const _AvatarInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: GoogleFonts.playfairDisplay(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _MemberRoleTone { gold, plum, neutral }

class _MemberRolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final _MemberRoleTone tone;

  const _MemberRolePill({
    required this.label,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _MemberRoleTone.gold => scheme.secondary,
      _MemberRoleTone.plum => scheme.primary,
      _MemberRoleTone.neutral => scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MemberMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 10),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _MembersMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MembersMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary, size: 27),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersLoadingState extends StatelessWidget {
  const _MembersLoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 84,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: .58,
                    child: Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: .38,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: .72,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
