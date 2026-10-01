import 'package:flutter/material.dart';

import 'package:verbum/design_system/design_system.dart';

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
    final p = context.palette;
    final t = context.type;

    return Material(
      color: p.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VerbumRadius.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                16,
                VerbumSpace.gutter - 4,
                14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(VerbumRadius.control),
                      boxShadow: VerbumShadows.subtle(p),
                    ),
                    alignment: Alignment.center,
                    child: VIcon(
                      VerbumIcons.usersThree,
                      weight: VIconWeight.duotone,
                      color: p.rubric,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nuestra comunidad', style: t.rubric),
                        const SizedBox(height: 3),
                        Text(
                          'Personas de la comunidad',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.title.copyWith(fontSize: 24, height: 1.08),
                        ),
                        const SizedBox(height: 8),
                        _MemberCountPill(count: members.length),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  VIconButton(
                    icon: VerbumIcons.close,
                    semanticLabel: 'Cerrar miembros',
                    onPressed: isSubmitting ? () {} : onClose,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.lineSoft),
            Expanded(child: _buildContent(context)),
            if (canManage && onOpenAdvancedManagement != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  8,
                  VerbumSpace.gutter,
                  14,
                ),
                child: VListGroup(
                  children: [
                    VListRow(
                      leading: VerbumIcons.userGear,
                      title: 'Administración avanzada',
                      onTap: isSubmitting ? null : onOpenAdvancedManagement,
                    ),
                  ],
                ),
              ),
          ],
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
        icon: VerbumIcons.cloudSlash,
        title: 'No pudimos reunir a la comunidad',
        message: errorMessage!,
      );
    }
    if (members.isEmpty) {
      return const _MembersMessageState(
        icon: VerbumIcons.users,
        title: 'Aún no hay miembros',
        message:
            'Cuando otras personas se unan, aparecerán aquí para caminar juntas.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        VerbumSpace.gutter,
        16,
        VerbumSpace.gutter,
        12,
      ),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VIcon(VerbumIcons.users, size: 14, color: p.inkMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                count == 1 ? '1 persona' : '$count personas',
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: p.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
    final p = context.palette;
    final t = context.type;
    final name = member.displayName.trim().isEmpty
        ? 'Miembro'
        : member.displayName.trim();

    return VSurfaceCard(
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.all(13),
      borderColor: member.isOwner ? p.butter : null,
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
                      style: t.bodyStrong.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.username.trim().isNotEmpty
                          ? '@${member.username.trim().replaceFirst(RegExp(r'^@'), '')}'
                          : 'Miembro de la comunidad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption.copyWith(color: p.inkMuted),
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
                  icon: VIcon(VerbumIcons.dotsThree, color: p.inkMuted),
                  color: p.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shadowColor: p.ink.withValues(alpha: .2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VerbumRadius.control),
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
                              icon: VerbumIcons.shieldSlash,
                              label: 'Quitar administración',
                            ),
                          ),
                          PopupMenuItem(
                            value: CommunityMemberAction.transfer,
                            child: _MemberMenuItem(
                              icon: VerbumIcons.arrowsClockwise,
                              label: 'Transferir liderazgo',
                            ),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: CommunityMemberAction.promote,
                            child: _MemberMenuItem(
                              icon: VerbumIcons.shieldPlus,
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
                    icon: VerbumIcons.medal,
                    tone: _MemberRoleTone.gold,
                  )
                else if (member.isAdmin)
                  const _MemberRolePill(
                    label: 'Administrador',
                    icon: VerbumIcons.shield,
                    tone: _MemberRoleTone.plum,
                  ),
                if (member.isCurrentUser)
                  const _MemberRolePill(
                    label: 'Tú',
                    icon: VerbumIcons.user,
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
    final p = context.palette;
    final photo = member.photoUrl?.trim();
    const size = 48.0;
    return Container(
      width: size,
      height: size,
      padding: member.isOwner ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: member.isOwner ? p.butter : null,
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .3),
        child: ColoredBox(
          color: p.surfaceMuted,
          child: photo != null && photo.isNotEmpty
              ? Image.network(
                  photo,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _AvatarInitial(name: name),
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
    return Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: context.type.bodyStrong.copyWith(
          color: context.palette.rubric,
          fontSize: 18,
        ),
      ),
    );
  }
}

enum _MemberRoleTone { gold, plum, neutral }

class _MemberRolePill extends StatelessWidget {
  final String label;
  final VerbumIcons icon;
  final _MemberRoleTone tone;

  const _MemberRolePill({
    required this.label,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg) = switch (tone) {
      _MemberRoleTone.gold => (p.butter, p.onButter),
      _MemberRoleTone.plum => (p.surfaceMuted, p.rubric),
      _MemberRoleTone.neutral => (p.lineSoft, p.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIcon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.type.caption.copyWith(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberMenuItem extends StatelessWidget {
  final VerbumIcons icon;
  final String label;

  const _MemberMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        VIcon(icon, size: 19, color: p.rubric),
        const SizedBox(width: 10),
        Flexible(child: Text(label, style: context.type.bodyStrong)),
      ],
    );
  }
}

class _MembersMessageState extends StatelessWidget {
  final VerbumIcons icon;
  final String title;
  final String message;

  const _MembersMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VerbumSpace.gutter),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: VEmptyState(icon: icon, title: title, message: message),
        ),
      ),
    );
  }
}

class _MembersLoadingState extends StatelessWidget {
  const _MembersLoadingState();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.all(VerbumSpace.gutter),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => VSurfaceCard(
        radius: VerbumRadius.tile,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
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
                          color: p.surfaceMuted,
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
                          color: p.lineSoft,
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
      ),
    );
  }
}
