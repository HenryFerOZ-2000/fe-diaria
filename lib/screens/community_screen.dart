import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'live_screen.dart';
import 'community_post_detail_screen.dart';
import 'community_entry_screen.dart';
import '../services/profile_service.dart';
import '../services/community_service.dart';
import '../services/community_posts_social_service.dart';
import '../services/post_social_service.dart';
import '../widgets/community_post_interaction_row.dart';
import '../widgets/community_members_sheet.dart';
import '../services/storage_service.dart';
import '../faith/faith_tradition.dart';
import '../faith/tradition_capabilities.dart';
import '../widgets/verbum_ambient_background.dart';
import '../data/spiritual_paths_catalog.dart';
import '../models/spiritual_path.dart';
import 'spiritual_path_detail_screen.dart';
import '../features/paths/presentation/path_photos.dart';
import '../services/spiritual_path_service.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/community/presentation/community_cover.dart';
import '../widgets/sign_in_prompt.dart';
import '../widgets/cover_scroll_frame.dart';

/// Firma para pedir la portada de "Mi comunidad" con los datos del grupo.
typedef MyCommunityCoverBuilder =
    Widget Function({
      required String title,
      String? subtitle,
      Widget? extra,
      ImageProvider? image,
    });

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CommunityTab _tab = CommunityTab.live;

  void _onTab(CommunityTab tab) => setState(() => _tab = tab);

  /// Para medir cada portada (franja bajo la hora).
  final _liveKey = GlobalKey();
  final _mineKey = GlobalKey();

  Widget _liveCover(int weeklyCount) => CommunityCover(
    key: _liveKey,
    image: AssetImage(VerbumPhotos.communityCandles.asset),
    eyebrow: 'Fe que se comparte',
    title: 'Comunidad',
    subtitle: 'Nadie ora solo.',
    extra: weeklyCount == 0
        ? null
        : CommunityGlassChip(
            dotColor: const Color(0xFF7EE0B5),
            label:
                '$weeklyCount ${weeklyCount == 1 ? 'intención' : 'intenciones'} esta semana',
          ),
    tab: _tab,
    onTab: _onTab,
  );

  Widget _mineCover({
    required String title,
    String? subtitle,
    Widget? extra,
    ImageProvider? image,
  }) => CommunityCover(
    key: _mineKey,
    image: image ?? AssetImage(VerbumPhotos.communityGroup.asset),
    eyebrow: 'Mi comunidad',
    title: title,
    subtitle: subtitle,
    extra: extra,
    tab: _tab,
    onTab: _onTab,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: IndexedStack(
        index: _tab.index,
        children: [
          CoverScrollFrame(
            coverKey: _liveKey,
            child: LiveScreen(showAppBar: false, coverBuilder: _liveCover),
          ),
          CoverScrollFrame(
            coverKey: _mineKey,
            child: _MyCommunityTab(cover: _mineCover),
          ),
        ],
      ),
    );
  }
}

class _MyCommunityTab extends StatefulWidget {
  const _MyCommunityTab({required this.cover});

  final MyCommunityCoverBuilder cover;

  @override
  State<_MyCommunityTab> createState() => _MyCommunityTabState();
}

class _MyCommunityTabState extends State<_MyCommunityTab> {
  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();
  final _communityService = CommunityService();
  final _communitySocial = CommunityPostsSocialService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final defaultCover = widget.cover(
      title: 'Crece en la fe con otros',
      subtitle: 'Tu parroquia o grupo, en un solo lugar.',
    );
    if (uid == null) {
      return ListView(
        padding: EdgeInsets.only(
          bottom: 28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          defaultCover,
          const Padding(
            padding: EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              8,
              VerbumSpace.gutter,
              0,
            ),
            child: SignInPrompt(
              title: 'Inicia sesión para ver tu comunidad',
              message:
                  'Con tu cuenta puedes unirte con un código o crear la '
                  'comunidad de tu parroquia o grupo.',
            ),
          ),
        ],
      );
    }

    return StreamBuilder(
      stream: _profileService.userStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _MyCommunityLoading(cover: defaultCover);
        }

        if (snapshot.hasError) {
          return _MyCommunityEmptyView(
            cover: defaultCover,
            title: 'No se pudo cargar tu comunidad',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
            buttonLabel: 'Entendido',
            buttonIcon: VerbumIcons.info,
          );
        }

        final userData = snapshot.data?.data() ?? <String, dynamic>{};
        final communityId = (userData['communityId'] as String?)?.trim();
        final hasCommunity = communityId != null && communityId.isNotEmpty;

        if (!hasCommunity) {
          return _MyCommunityEmptyView(
            cover: defaultCover,
            onJoin: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityEntryScreen(
                  uid: uid,
                  initialMode: CommunityEntryMode.join,
                ),
              ),
            ),
            onCreate: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityEntryScreen(
                  uid: uid,
                  initialMode: CommunityEntryMode.create,
                ),
              ),
            ),
          );
        }

        return StreamBuilder(
          stream: _communityService.communityStream(communityId),
          builder: (context, communitySnapshot) {
            if (communitySnapshot.connectionState == ConnectionState.waiting) {
              return _MyCommunityLoading(cover: defaultCover);
            }

            if (communitySnapshot.hasError ||
                !communitySnapshot.hasData ||
                !communitySnapshot.data!.exists) {
              return _MyCommunityEmptyView(
                cover: defaultCover,
                title: 'Tu comunidad no está disponible',
                subtitle:
                    'No pudimos encontrar la comunidad asociada a tu perfil.',
                buttonLabel: 'Entendido',
                buttonIcon: VerbumIcons.info,
              );
            }

            final data = communitySnapshot.data!.data() ?? <String, dynamic>{};
            final adminIdsRaw = (data['adminIds'] as List?) ?? const [];
            final adminIds = adminIdsRaw
                .map((id) => id?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            final isAdmin = adminIds.contains(uid);
            final createdBy = (data['createdBy'] as String?)?.trim() ?? '';
            final isCreator = createdBy == uid;
            return _CommunityBasicView(
              cover: widget.cover,
              communityId: communityId,
              data: data,
              isAdmin: isAdmin,
              isCreator: isCreator,
              currentUid: uid,
              currentUserData: userData,
              communityService: _communityService,
              communitySocial: _communitySocial,
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _openJoinDialog({required String uid}) async {
    final controller = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Unirme a una comunidad'),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Codigo de invitacion',
                  hintText: 'Ejemplo: VERBUM001',
                ),
                enabled: !isSubmitting,
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresa un codigo de invitacion.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final currentUser = await _profileService.getUser(
                              uid,
                            );
                            final currentCommunityId =
                                (currentUser.data()?['communityId'] as String?)
                                    ?.trim();
                            await _communityService.joinCommunityWithCode(
                              uid: uid,
                              inviteCode: code,
                              currentCommunityId: currentCommunityId,
                            );
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Te uniste a la comunidad correctamente.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unirme'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _openCreateCommunityDialog({required String uid}) async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final descriptionController = TextEditingController();
    final priestController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final faithTradition = faithTraditionFromStorageString(
              StorageService().getValidatedTraditionalPrayersReligion(),
            );
            return AlertDialog(
              title: const Text('Crear comunidad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la comunidad *',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'Ciudad *'),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion *',
                        hintText: 'Breve descripcion de la comunidad',
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priestController,
                      decoration: InputDecoration(
                        labelText: TraditionUiStrings.communityLeaderFieldLabel(
                          faithTradition,
                        ),
                        hintText: TraditionUiStrings.communityLeaderHint(
                          faithTradition,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de imagen (opcional)',
                        hintText: 'https://...',
                      ),
                      keyboardType: TextInputType.url,
                      enabled: !isSubmitting,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final city = cityController.text.trim();
                          final desc = descriptionController.text.trim();
                          if (name.isEmpty || city.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nombre, ciudad y descripcion son obligatorios.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final currentUser = await _profileService.getUser(
                              uid,
                            );
                            final currentCommunityId =
                                (currentUser.data()?['communityId'] as String?)
                                    ?.trim();
                            await _communityService.createCommunity(
                              uid: uid,
                              currentCommunityId: currentCommunityId,
                              name: name,
                              city: city,
                              description: desc,
                              priestName: priestController.text.trim().isEmpty
                                  ? null
                                  : priestController.text.trim(),
                              imageUrl: imageUrlController.text.trim().isEmpty
                                  ? null
                                  : imageUrlController.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Comunidad creada. Ya eres administrador.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MyCommunityLoading extends StatelessWidget {
  const _MyCommunityLoading({required this.cover});

  final Widget cover;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        cover,
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _MyCommunityEmptyView extends StatelessWidget {
  final Widget cover;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VerbumIcons buttonIcon;
  final VoidCallback? onJoin;
  final VoidCallback? onCreate;

  const _MyCommunityEmptyView({
    required this.cover,
    this.title = 'Aún no perteneces a ninguna comunidad',
    this.subtitle =
        'Únete con un código o crea una comunidad para tu parroquia o grupo.',
    this.buttonLabel = 'Unirme con un código',
    this.buttonIcon = VerbumIcons.key,
    this.onJoin,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return ListView(
      padding: EdgeInsets.only(
        bottom: 28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        cover,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VerbumSpace.gutter,
            8,
            VerbumSpace.gutter,
            0,
          ),
          child: VSurfaceCard(
            radius: VerbumRadius.card,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const VPhotoFrame(
                      VerbumPhotos.handsTogether,
                      width: 64,
                      aspectRatio: 1,
                      tiltDegrees: -4,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: type.heading.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(subtitle, style: type.body.copyWith(color: p.inkMuted)),
                const SizedBox(height: 18),
                if (onJoin != null)
                  VButton(
                    label: buttonLabel,
                    icon: buttonIcon,
                    iconLeading: true,
                    expanded: true,
                    onPressed: onJoin,
                  ),
                if (onCreate != null) ...[
                  const SizedBox(height: 10),
                  VButton(
                    label: 'Crear una comunidad',
                    icon: VerbumIcons.plusCircle,
                    iconLeading: true,
                    variant: VButtonVariant.outlined,
                    expanded: true,
                    onPressed: onCreate,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityBasicView extends StatelessWidget {
  final MyCommunityCoverBuilder cover;
  final String communityId;
  final Map<String, dynamic> data;
  final bool isAdmin;
  final bool isCreator;
  final String currentUid;
  final Map<String, dynamic> currentUserData;
  final CommunityService communityService;
  final CommunityPostsSocialService communitySocial;

  const _CommunityBasicView({
    required this.cover,
    required this.communityId,
    required this.data,
    required this.isAdmin,
    required this.isCreator,
    required this.currentUid,
    required this.currentUserData,
    required this.communityService,
    required this.communitySocial,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = (data['name'] as String?)?.trim();
    final city = (data['city'] as String?)?.trim();
    final description = (data['description'] as String?)?.trim();
    final priestName = (data['priestName'] as String?)?.trim();
    final imageUrl = (data['imageUrl'] as String?)?.trim();
    final isVerified = (data['isVerified'] as bool?) ?? false;
    final membersCanPost = (data['membersCanPost'] as bool?) ?? true;
    final inviteCode = (data['inviteCode'] as String?)?.trim() ?? '';
    final canPublish = isAdmin || membersCanPost;

    final title = name?.isNotEmpty == true ? name! : 'Mi comunidad';
    return ListView(
      padding: EdgeInsets.only(
        bottom: 28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        cover(
          title: title,
          image: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
          extra: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isVerified)
                const CommunityGlassChip(
                  icon: VerbumIcons.sealCheck,
                  label: 'Verificada',
                ),
              if (city != null && city.isNotEmpty)
                CommunityGlassChip(icon: VerbumIcons.mapPin, label: city),
              if (isAdmin && inviteCode.isNotEmpty)
                CommunityGlassChip(
                  icon: VerbumIcons.userPlus,
                  label: 'Invitar · $inviteCode',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Te invito a unirte a $title en Verbum. Usa el código $inviteCode.',
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VerbumSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdmin ||
                  ((data['activeSpiritualPathId'] as String?)?.isNotEmpty ==
                      true)) ...[
                const SizedBox(height: 14),
                _CommunityPathCard(
                  communityId: communityId,
                  currentUid: currentUid,
                  pathId: data['activeSpiritualPathId'] as String?,
                  isAdmin: isAdmin,
                  communityService: communityService,
                ),
              ],
              const SizedBox(height: 12),
              _CommunityQuickActions(
                onPublish: canPublish
                    ? () => _CommunityComposerCard(
                        communityId: communityId,
                        currentUid: currentUid,
                        currentUserData: currentUserData,
                        communityService: communityService,
                      )._openCreatePostDialog(context)
                    : null,
                onMembers: () => _CommunityMembersButton(
                  communityId: communityId,
                  currentUid: currentUid,
                  communityService: communityService,
                  adminIds: ((data['adminIds'] as List?) ?? const [])
                      .map((id) => id?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet(),
                  createdBy: ((data['createdBy'] as String?) ?? '').trim(),
                )._openMembersSheet(context),
                onInvite: isAdmin && inviteCode.isNotEmpty
                    ? () => SharePlus.instance.share(
                        ShareParams(
                          text:
                              'Te invito a unirte a $title en Verbum. Usa el código $inviteCode.',
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Nuestro espacio', style: context.type.heading),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.butter,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isAdmin ? 'Guía' : 'Miembro',
                      style: context.type.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.palette.onButter,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              VSurfaceCard(
                radius: VerbumRadius.card,
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Información y gestión',
                              style: context.type.heading.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VIcon(
                                    VerbumIcons.sealCheck,
                                    weight: VIconWeight.fill,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificada',
                                    style: VerbumFonts.sans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        _EditCommunityButton(
                          communityId: communityId,
                          currentUid: currentUid,
                          data: data,
                          communityService: communityService,
                        ),
                      ],
                      if (city != null && city.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            VIcon(
                              VerbumIcons.mapPin,
                              size: 16,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              city,
                              style: VerbumFonts.sans(
                                fontSize: 13.5,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: VerbumFonts.sans(
                            fontSize: 14,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      if (priestName != null && priestName.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const VIcon(VerbumIcons.user, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Responsable: $priestName',
                                  style: VerbumFonts.sans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isAdmin && inviteCode.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              VIcon(
                                VerbumIcons.key,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Codigo de invitacion',
                                      style: VerbumFonts.sans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      inviteCode,
                                      style: VerbumFonts.sans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar codigo',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: inviteCode),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Codigo copiado al portapapeles',
                                      ),
                                    ),
                                  );
                                },
                                icon: const VIcon(VerbumIcons.copy),
                              ),
                              IconButton(
                                tooltip: 'Compartir invitación',
                                onPressed: () => SharePlus.instance.share(
                                  ShareParams(
                                    text:
                                        'Te invito a unirte a ${name?.isNotEmpty == true ? name : 'mi comunidad'} en Verbum. Usa el código $inviteCode.',
                                  ),
                                ),
                                icon: const VIcon(VerbumIcons.shareNetwork),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!canPublish) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        VIcon(
                          VerbumIcons.info,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solo los administradores pueden publicar en esta comunidad.',
                            style: VerbumFonts.sans(
                              fontSize: 13.5,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _LeaveCommunityButton(
                communityId: communityId,
                currentUid: currentUid,
                isAdmin: isAdmin,
                isCreator: isCreator,
                communityService: communityService,
              ),
              const SizedBox(height: 12),
              Text('Muro', style: context.type.heading),
              const SizedBox(height: 8),
              StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                stream: communityService.communityPostsStream(communityId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No se pudieron cargar las publicaciones por ahora.',
                      ),
                    );
                  }

                  final docs = snapshot.data ?? [];
                  if (kDebugMode) {
                    debugPrint(
                      '[Verbum/community_feed] UI communityId=$communityId '
                      'postsEnLista=${docs.length}',
                    );
                  }
                  if (docs.isEmpty) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            VIcon(
                              VerbumIcons.chatsCircle,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aun no hay publicaciones en esta comunidad.',
                                style: VerbumFonts.sans(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: docs.map((doc) {
                      final post = doc.data();
                      return _CommunityPostTile(
                        postId: doc.id,
                        post: post,
                        currentUid: currentUid,
                        isAdmin: isAdmin,
                        communityAdminIds:
                            ((data['adminIds'] as List?) ?? const [])
                                .map((id) => id?.toString() ?? '')
                                .where((id) => id.isNotEmpty)
                                .toSet(),
                        communityService: communityService,
                        social: communitySocial,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Accesos directos de "Mi comunidad": publicar, miembros e invitar.
class _CommunityQuickActions extends StatelessWidget {
  const _CommunityQuickActions({
    required this.onMembers,
    this.onPublish,
    this.onInvite,
  });

  final VoidCallback onMembers;
  final VoidCallback? onPublish;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (onPublish != null) (VerbumIcons.notePencil, 'Publicar', onPublish!),
      (VerbumIcons.usersThree, 'Miembros', onMembers),
      if (onInvite != null) (VerbumIcons.userPlus, 'Invitar', onInvite!),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: actions[i].$1,
              label: actions[i].$2,
              onTap: actions[i].$3,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final VerbumIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return VSurfaceCard(
      onTap: onTap,
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      semanticLabel: label,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: VIcon(icon, size: 19, color: p.rubric),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodyStrong.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _CommunityPathCard extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final String? pathId;
  final bool isAdmin;
  final CommunityService communityService;

  const _CommunityPathCard({
    required this.communityId,
    required this.currentUid,
    required this.pathId,
    required this.isAdmin,
    required this.communityService,
  });

  Future<void> _choose(BuildContext context) async {
    final selected = await showModalBottomSheet<SpiritualPath>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camino de la comunidad',
                style: context.type.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige un recorrido que todos puedan realizar juntos.',
                style: context.type.body.copyWith(
                  color: context.palette.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              ...SpiritualPathsCatalog.paths.map(
                (path) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: VPhotoFrame(
                    photoForPath(path.id),
                    width: 50,
                    aspectRatio: 1,
                  ),
                  title: Text(path.title),
                  subtitle: Text(path.subtitle),
                  trailing: const VIcon(VerbumIcons.caretRight),
                  onTap: () => Navigator.pop(sheetContext, path),
                ),
              ),
              if (pathId?.isNotEmpty == true)
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await communityService.setCommunitySpiritualPath(
                      communityId: communityId,
                      editorUid: currentUid,
                    );
                  },
                  icon: const VIcon(VerbumIcons.stopCircle),
                  label: const Text('Finalizar el camino actual'),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await communityService.setCommunitySpiritualPath(
      communityId: communityId,
      editorUid: currentUid,
      pathId: selected.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final hasPath = pathId?.isNotEmpty == true;
    final path = hasPath ? SpiritualPathsCatalog.byId(pathId!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionHeader(
          'Camino de la comunidad',
          trailing: isAdmin ? (path == null ? 'Elegir' : 'Cambiar') : null,
          onTrailingTap: isAdmin ? () => _choose(context) : null,
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        ),
        VSurfaceCard(
          radius: VerbumRadius.card,
          padding: const EdgeInsets.all(12),
          onTap: path != null
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SpiritualPathDetailScreen(path: path),
                  ),
                )
              : () => _choose(context),
          child: Row(
            children: [
              path == null
                  ? Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(VerbumRadius.tile),
                      ),
                      child: VIcon(VerbumIcons.path, color: p.rubric),
                    )
                  : VPhotoFrame(
                      photoForPath(path.id),
                      width: 62,
                      aspectRatio: 1,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: path == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin
                                ? 'Elijan un camino para recorrer juntos'
                                : 'Aún no hay un camino elegido',
                            style: type.heading.copyWith(fontSize: 15.5),
                          ),
                          Text(
                            isAdmin
                                ? 'Toca para elegirlo'
                                : 'Quien guía la comunidad lo elegirá',
                            style: type.caption,
                          ),
                        ],
                      )
                    : FutureBuilder<SpiritualPathProgress>(
                        future: SpiritualPathService().progressFor(path.id),
                        builder: (context, snapshot) {
                          final progress = snapshot.data;
                          final done = progress?.completedDays.length ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                done == 0
                                    ? 'Para recorrer juntos'
                                    : 'Tu avance · día $done de ${path.days.length}',
                                style: type.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                path.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: type.heading.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value:
                                      progress?.progressFor(path.days.length) ??
                                      0,
                                  minHeight: 6,
                                  color: p.sage,
                                  backgroundColor: p.surfaceMuted,
                                  semanticsLabel: 'Tu avance en el camino',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(width: 8),
              VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditCommunityButton extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final Map<String, dynamic> data;
  final CommunityService communityService;

  const _EditCommunityButton({
    required this.communityId,
    required this.currentUid,
    required this.data,
    required this.communityService,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => _openEditDialog(context),
        icon: const VIcon(VerbumIcons.pencilSimple, size: 18),
        label: const Text('Editar comunidad'),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final descriptionController = TextEditingController(
      text: ((data['description'] as String?) ?? '').trim(),
    );
    final priestController = TextEditingController(
      text: ((data['priestName'] as String?) ?? '').trim(),
    );
    bool membersCanPost = (data['membersCanPost'] as bool?) ?? true;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final faithTradition = faithTraditionFromStorageString(
              StorageService().getValidatedTraditionalPrayersReligion(),
            );
            return AlertDialog(
              title: const Text('Editar comunidad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                        hintText: 'Describe brevemente la comunidad',
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priestController,
                      decoration: InputDecoration(
                        labelText:
                            TraditionUiStrings.communityLeaderFieldLabelShort(
                              faithTradition,
                            ),
                        hintText: TraditionUiStrings.communityLeaderHint(
                          faithTradition,
                        ),
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: membersCanPost,
                      onChanged: isSubmitting
                          ? null
                          : (v) => setDialogState(() => membersCanPost = v),
                      title: const Text('Permitir que los miembros publiquen'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await communityService.updateCommunityBasicInfo(
                              communityId: communityId,
                              editorUid: currentUid,
                              description: descriptionController.text,
                              priestName: priestController.text,
                              membersCanPost: membersCanPost,
                            );
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Comunidad actualizada correctamente.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ManageAdminsButton extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final CommunityService communityService;

  const _ManageAdminsButton({
    required this.communityId,
    required this.currentUid,
    required this.communityService,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => openDialog(context),
        icon: const VIcon(VerbumIcons.userGear, size: 18),
        label: const Text('Gestion manual por UID (fallback)'),
      ),
    );
  }

  Future<void> openDialog(BuildContext context) async {
    final addController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> runAction(Future<void> Function() action) async {
              setDialogState(() => isSubmitting = true);
              try {
                await action();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Operacion completada.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              } finally {
                if (context.mounted) {
                  setDialogState(() => isSubmitting = false);
                }
              }
            }

            final scheme = Theme.of(context).colorScheme;
            return AlertDialog(
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              icon: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.palette.emphasis,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: VIcon(
                  VerbumIcons.userGear,
                  color: context.palette.onEmphasis,
                ),
              ),
              title: Text(
                'Administración avanzada',
                textAlign: TextAlign.center,
                style: VerbumFonts.serif(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 460,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: communityService.communityStream(communityId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snap.hasData || !snap.data!.exists) {
                      return const Text('La comunidad no esta disponible.');
                    }
                    final communityData =
                        snap.data!.data() ?? <String, dynamic>{};
                    final createdBy =
                        (communityData['createdBy'] as String?)?.trim() ?? '';
                    final adminIdsRaw =
                        (communityData['adminIds'] as List?) ?? const [];
                    final adminIds = adminIdsRaw
                        .map((id) => id?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toList();

                    final canManage = createdBy == currentUid;
                    if (!canManage) {
                      return const Text(
                        'Solo el responsable principal puede gestionar administradores.',
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: scheme.secondary.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.secondary.withValues(alpha: .2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VIcon(
                                  VerbumIcons.info,
                                  size: 19,
                                  color: scheme.secondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Utiliza esta opción solo si la persona no aparece todavía en la lista principal.',
                                    style: VerbumFonts.sans(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: addController,
                            enabled: !isSubmitting,
                            decoration: InputDecoration(
                              labelText: 'UID de la persona',
                              hintText: 'Pega aquí su identificador',
                              prefixIcon: const VIcon(VerbumIcons.key),
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: .5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () => runAction(() async {
                                      await communityService.addCommunityAdmin(
                                        communityId: communityId,
                                        actorUid: currentUid,
                                        targetUid: addController.text,
                                      );
                                      addController.clear();
                                    }),
                              icon: const VIcon(VerbumIcons.userPlus, size: 18),
                              label: const Text('Añadir como administrador'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Administradores actuales',
                            style: VerbumFonts.serif(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...adminIds.map((adminUid) {
                            final isOwner = adminUid == createdBy;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? scheme.secondary.withValues(alpha: .07)
                                    : scheme.surfaceContainerHighest.withValues(
                                        alpha: .42,
                                      ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isOwner
                                      ? scheme.secondary.withValues(alpha: .25)
                                      : scheme.outlineVariant,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 5,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        (isOwner
                                                ? scheme.secondary
                                                : scheme.primary)
                                            .withValues(alpha: .11),
                                    shape: BoxShape.circle,
                                  ),
                                  child: VIcon(
                                    isOwner
                                        ? VerbumIcons.medal
                                        : VerbumIcons.shield,
                                    size: 20,
                                    color: isOwner
                                        ? scheme.secondary
                                        : scheme.primary,
                                  ),
                                ),
                                title: Text(
                                  isOwner
                                      ? 'Responsable principal'
                                      : 'Administrador',
                                  style: VerbumFonts.sans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle:
                                    FutureBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>
                                    >(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(adminUid)
                                          .get(),
                                      builder: (context, userSnap) {
                                        final d = userSnap.data?.data();
                                        final name =
                                            (d?['displayName'] as String?)
                                                ?.trim() ??
                                            '';
                                        final username =
                                            (d?['username'] as String?)
                                                ?.trim() ??
                                            '';
                                        if (name.isNotEmpty) return Text(name);
                                        if (username.isNotEmpty) {
                                          return Text(
                                            '@${username.replaceFirst(RegExp(r'^@'), '')}',
                                          );
                                        }
                                        return const Text(
                                          'Perfil sin nombre visible',
                                        );
                                      },
                                    ),
                                trailing: isOwner
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.secondary.withValues(
                                            alpha: .1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Principal',
                                          style: VerbumFonts.sans(
                                            color: scheme.secondary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : PopupMenuButton<String>(
                                        enabled: !isSubmitting,
                                        tooltip: 'Gestionar administrador',
                                        icon: const VIcon(
                                          VerbumIcons.dotsThree,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        onSelected: (value) async {
                                          if (value == 'remove') {
                                            await runAction(() async {
                                              await communityService
                                                  .removeCommunityAdmin(
                                                    communityId: communityId,
                                                    actorUid: currentUid,
                                                    targetUid: adminUid,
                                                  );
                                            });
                                            return;
                                          }
                                          final ok =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (confirmContext) => AlertDialog(
                                                  backgroundColor:
                                                      scheme.surface,
                                                  surfaceTintColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                  title: Text(
                                                    'Transferir liderazgo',
                                                    style: VerbumFonts.serif(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  content: const Text(
                                                    'Esta persona pasará a gestionar la comunidad y sus administradores.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            confirmContext,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            confirmContext,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Transferir',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;
                                          if (!ok) return;
                                          await runAction(() async {
                                            await communityService
                                                .transferCommunityLeadership(
                                                  communityId: communityId,
                                                  actorUid: currentUid,
                                                  newOwnerUid: adminUid,
                                                );
                                          });
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'transfer',
                                            child: Text('Transferir liderazgo'),
                                          ),
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Text(
                                              'Quitar administración',
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
    addController.dispose();
  }
}

class _CommunityMembersButton extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final CommunityService communityService;
  final Set<String> adminIds;
  final String createdBy;

  const _CommunityMembersButton({
    required this.communityId,
    required this.currentUid,
    required this.communityService,
    required this.adminIds,
    required this.createdBy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: .055),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: .16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openMembersSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: VIcon(
                  VerbumIcons.usersThree,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personas de la comunidad',
                      style: VerbumFonts.sans(
                        color: scheme.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conoce a quienes caminan contigo',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VerbumFonts.sans(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              VIcon(VerbumIcons.caretRight, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMembersSheet(BuildContext context) async {
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF171220).withValues(alpha: .52),
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> runAction(
              Future<void> Function() action,
              String successMessage,
            ) async {
              setSheetState(() => isSubmitting = true);
              try {
                await action();
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(successMessage)));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
              }
            }

            Widget panel({
              List<CommunityMemberViewData> members = const [],
              bool loading = false,
              String? error,
              bool canManage = false,
            }) {
              return CommunityMembersPanel(
                members: members,
                canManage: canManage,
                isLoading: loading,
                isSubmitting: isSubmitting,
                errorMessage: error,
                onClose: () => Navigator.of(sheetContext).pop(),
                onActionSelected: (selection) async {
                  switch (selection.action) {
                    case CommunityMemberAction.promote:
                      await runAction(
                        () => communityService.addCommunityAdmin(
                          communityId: communityId,
                          actorUid: currentUid,
                          targetUid: selection.member.uid,
                        ),
                        '${selection.member.displayName} ahora ayuda a administrar la comunidad.',
                      );
                    case CommunityMemberAction.demote:
                      await runAction(
                        () => communityService.removeCommunityAdmin(
                          communityId: communityId,
                          actorUid: currentUid,
                          targetUid: selection.member.uid,
                        ),
                        'Se actualizaron los permisos de ${selection.member.displayName}.',
                      );
                    case CommunityMemberAction.transfer:
                      final confirmed = await _confirmLeadershipTransfer(
                        context,
                        selection.member,
                      );
                      if (!confirmed) return;
                      await runAction(
                        () => communityService.transferCommunityLeadership(
                          communityId: communityId,
                          actorUid: currentUid,
                          newOwnerUid: selection.member.uid,
                        ),
                        '${selection.member.displayName} es ahora la persona responsable principal.',
                      );
                  }
                },
                onOpenAdvancedManagement: canManage
                    ? () async {
                        Navigator.of(sheetContext).pop();
                        await Future<void>.delayed(Duration.zero);
                        if (!context.mounted) return;
                        await _ManageAdminsButton(
                          communityId: communityId,
                          currentUid: currentUid,
                          communityService: communityService,
                        ).openDialog(context);
                      }
                    : null,
              );
            }

            return FractionallySizedBox(
              heightFactor: .92,
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: communityService.communityStream(communityId),
                builder: (context, communitySnapshot) {
                  if (communitySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return panel(loading: true);
                  }
                  if (communitySnapshot.hasError) {
                    return panel(
                      error:
                          'No se pudo cargar la información de la comunidad.',
                    );
                  }
                  final communityData =
                      communitySnapshot.data?.data() ?? <String, dynamic>{};
                  final liveCreatedBy =
                      (communityData['createdBy'] as String?)?.trim() ??
                      createdBy;
                  final liveAdminIdsRaw =
                      (communityData['adminIds'] as List?) ?? adminIds.toList();
                  final liveAdminIds = liveAdminIdsRaw
                      .map((id) => id?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet();
                  final canManage = currentUid == liveCreatedBy;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: communityService.communityMembersStream(
                      communityId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return panel(loading: true, canManage: canManage);
                      }
                      if (snapshot.hasError) {
                        return panel(
                          error: 'No se pudieron cargar los miembros.',
                          canManage: canManage,
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final members =
                          docs.map((userDoc) {
                            final uid = userDoc.id;
                            final data = userDoc.data();
                            return CommunityMemberViewData(
                              uid: uid,
                              displayName:
                                  ((data['displayName'] as String?) ??
                                          'Miembro')
                                      .trim(),
                              username: ((data['username'] as String?) ?? '')
                                  .trim(),
                              photoUrl: (data['photoURL'] as String?)?.trim(),
                              isOwner: uid == liveCreatedBy,
                              isAdmin: liveAdminIds.contains(uid),
                              isCurrentUser: uid == currentUid,
                            );
                          }).toList()..sort((a, b) {
                            final aRank = a.isOwner ? 0 : (a.isAdmin ? 1 : 2);
                            final bRank = b.isOwner ? 0 : (b.isAdmin ? 1 : 2);
                            final rank = aRank.compareTo(bRank);
                            if (rank != 0) return rank;
                            return a.displayName.toLowerCase().compareTo(
                              b.displayName.toLowerCase(),
                            );
                          });
                      return panel(members: members, canManage: canManage);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmLeadershipTransfer(
    BuildContext context,
    CommunityMemberViewData member,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: VerbumAmbientBackground(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: scheme.secondary.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: VIcon(
                            VerbumIcons.arrowsClockwise,
                            color: scheme.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Transferir liderazgo',
                          textAlign: TextAlign.center,
                          style: VerbumFonts.serif(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${member.displayName} será la persona responsable principal y podrá gestionar a los administradores.',
                          textAlign: TextAlign.center,
                          style: VerbumFonts.sans(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text('Transferir'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ) ??
        false;
  }
}

class _CommunityComposerCard extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final Map<String, dynamic> currentUserData;
  final CommunityService communityService;

  const _CommunityComposerCard({
    required this.communityId,
    required this.currentUid,
    required this.currentUserData,
    required this.communityService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: VIcon(
            VerbumIcons.notePencil,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          '¿Qué quieres compartir?',
          style: VerbumFonts.sans(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Una reflexión, intención o mensaje'),
        trailing: const VIcon(VerbumIcons.arrowUpRight),
        onTap: () => _openCreatePostDialog(context),
      ),
    );
  }

  Future<void> _openCreatePostDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva publicacion'),
              content: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe algo para tu comunidad...',
                ),
                enabled: !isSubmitting,
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Escribe un mensaje antes de publicar.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final authorName =
                                (currentUserData['displayName'] as String?)
                                    ?.trim();
                            final authorPhoto =
                                (currentUserData['photoURL'] as String?)
                                    ?.trim();

                            await communityService.createCommunityPost(
                              communityId: communityId,
                              authorId: currentUid,
                              authorName: authorName,
                              authorPhotoUrl: authorPhoto,
                              text: text,
                            );

                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Publicacion enviada a tu comunidad.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LeaveCommunityButton extends StatelessWidget {
  final String communityId;
  final String currentUid;
  final bool isAdmin;
  final bool isCreator;
  final CommunityService communityService;

  const _LeaveCommunityButton({
    required this.communityId,
    required this.currentUid,
    required this.isAdmin,
    required this.isCreator,
    required this.communityService,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _confirmLeave(context),
        icon: const VIcon(VerbumIcons.signOut, size: 18),
        label: const Text('Salir de la comunidad'),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final message = isCreator
        ? 'Eres el responsable principal. Debes transferir el liderazgo antes de salir.'
        : (isAdmin
              ? 'Si sales, dejaras de ver/publicar/interactuar en esta comunidad y perderas permisos de administrador.'
              : 'Si sales, dejaras de ver/publicar/interactuar en esta comunidad.');

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Salir de la comunidad'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !context.mounted) return;

    try {
      await communityService.leaveCommunity(
        communityId: communityId,
        uid: currentUid,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saliste de la comunidad.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _CommunityPostTile extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final String currentUid;
  final bool isAdmin;
  final Set<String> communityAdminIds;
  final CommunityService communityService;
  final CommunityPostsSocialService social;

  const _CommunityPostTile({
    required this.postId,
    required this.post,
    required this.currentUid,
    required this.isAdmin,
    required this.communityAdminIds,
    required this.communityService,
    required this.social,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CommunityPostDetailScreen(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authorName = ((post['authorName'] as String?) ?? 'Miembro').trim();
    final authorPhotoUrl = (post['authorPhotoUrl'] as String?)?.trim();
    final text = ((post['text'] as String?) ?? '').trim();
    final createdAt = post['createdAt'] as Timestamp?;
    final timeLabel = _formatTimeAgo(createdAt?.toDate());
    final likeSeed = firestoreIntCount(post['likeCount']);
    final commentSeed = firestoreIntCount(post['commentCount']);
    final authorId = ((post['authorId'] as String?) ?? '').trim();
    final authorIsAdmin = communityAdminIds.contains(authorId);
    final canDelete = isAdmin || authorId == currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: context.palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(23),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openDetail(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage:
                            (authorPhotoUrl != null &&
                                authorPhotoUrl.isNotEmpty)
                            ? NetworkImage(authorPhotoUrl)
                            : null,
                        child:
                            (authorPhotoUrl == null || authorPhotoUrl.isEmpty)
                            ? Text(
                                authorName.isNotEmpty
                                    ? authorName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                authorName.isNotEmpty ? authorName : 'Miembro',
                                style: VerbumFonts.sans(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (authorIsAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Admin',
                                  style: VerbumFonts.sans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: VerbumFonts.sans(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (canDelete)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value != 'delete') return;
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Eliminar publicación'),
                                    content: const Text(
                                      'Esta publicación se eliminará y no se podrá recuperar.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (!ok || !context.mounted) return;
                            try {
                              await communityService.deleteCommunityPost(
                                postId: postId,
                                actorUid: currentUid,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Publicación eliminada.'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Eliminar publicación'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: VerbumFonts.sans(
                      fontSize: 14,
                      height: 1.45,
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: CommunityPostInteractionRow(
              postId: postId,
              currentUid: currentUid,
              service: social,
              seedLikeCount: likeSeed,
              seedCommentCount: commentSeed,
              onOpenComments: () => _openDetail(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'ahora';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}
