import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../services/storage_service.dart';
import '../faith/faith_tradition.dart';
import '../faith/tradition_capabilities.dart';
import '../widgets/verbum_ambient_background.dart';
import '../widgets/verbum_header_actions.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.surface,
                        colorScheme.primary.withValues(alpha: 0.12),
                      ]
                    : [
                        colorScheme.primary.withValues(alpha: 0.06),
                        colorScheme.tertiary.withValues(alpha: 0.05),
                      ],
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comunidad',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'FE QUE SE COMPARTE',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: const [VerbumHeaderActions()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(11),
                  labelColor: Colors.white,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, size: 7),
                          SizedBox(width: 7),
                          Text('En vivo'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_2_outlined, size: 17),
                          SizedBox(width: 7),
                          Text('Mi comunidad'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const VerbumAmbientBackground(
          child: TabBarView(
            children: [LiveScreen(showAppBar: false), _MyCommunityTab()],
          ),
        ),
      ),
    );
  }
}

class _MyCommunityTab extends StatefulWidget {
  const _MyCommunityTab();

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
    if (uid == null) {
      return _MyCommunityEmptyView(
        title: 'Inicia sesion para ver tu comunidad',
        subtitle: 'Cuando inicies sesion, podras unirte con un codigo.',
        buttonLabel: 'Iniciar sesion',
        buttonIcon: Icons.login,
        onJoin: () => Navigator.of(context).pushNamed('/welcome'),
      );
    }

    return StreamBuilder(
      stream: _profileService.userStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudo cargar tu comunidad por ahora.'),
          );
        }

        final userData = snapshot.data?.data() ?? <String, dynamic>{};
        final communityId = (userData['communityId'] as String?)?.trim();
        final hasCommunity = communityId != null && communityId.isNotEmpty;

        if (!hasCommunity) {
          return _MyCommunityEmptyView(
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
              return const Center(child: CircularProgressIndicator());
            }

            if (communitySnapshot.hasError) {
              return const Center(
                child: Text('No se pudo cargar tu comunidad por ahora.'),
              );
            }

            if (!communitySnapshot.hasData || !communitySnapshot.data!.exists) {
              return const _MyCommunityEmptyView(
                title: 'Tu comunidad no esta disponible',
                subtitle:
                    'No pudimos encontrar la comunidad asociada a tu perfil.',
                buttonLabel: 'Entendido',
                buttonIcon: Icons.info_outline,
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

class _MyCommunityEmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onJoin;
  final VoidCallback? onCreate;

  const _MyCommunityEmptyView({
    this.title = 'Aun no perteneces a ninguna comunidad',
    this.subtitle =
        'Unete con un codigo o crea una comunidad nueva para tu parroquia o grupo.',
    this.buttonLabel = 'Unirme a una comunidad',
    this.buttonIcon = Icons.vpn_key_outlined,
    this.onJoin,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            if (onJoin != null && onCreate != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onJoin,
                  icon: Icon(buttonIcon),
                  label: Text(buttonLabel),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear comunidad'),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: onJoin,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBasicView extends StatelessWidget {
  final String communityId;
  final Map<String, dynamic> data;
  final bool isAdmin;
  final bool isCreator;
  final String currentUid;
  final Map<String, dynamic> currentUserData;
  final CommunityService communityService;
  final CommunityPostsSocialService communitySocial;

  const _CommunityBasicView({
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CommunityWelcomeHero(
          name: name?.isNotEmpty == true ? name! : 'Mi comunidad',
          city: city ?? '',
          imageUrl: imageUrl,
          isAdmin: isAdmin,
          isVerified: isVerified,
          inviteCode: inviteCode,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'Nuestro espacio',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isAdmin ? 'ADMINISTRADOR' : 'MIEMBRO',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Información y gestión',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
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
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verificada',
                              style: GoogleFonts.inter(
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
                const SizedBox(height: 8),
                _CommunityMembersButton(
                  communityId: communityId,
                  currentUid: currentUid,
                  communityService: communityService,
                  adminIds: ((data['adminIds'] as List?) ?? const [])
                      .map((id) => id?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet(),
                  createdBy: ((data['createdBy'] as String?) ?? '').trim(),
                ),
                if (isCreator) ...[
                  const SizedBox(height: 4),
                  _ManageAdminsButton(
                    communityId: communityId,
                    currentUid: currentUid,
                    communityService: communityService,
                  ),
                ],
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        city,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.inter(
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
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Responsable: $priestName',
                            style: GoogleFonts.inter(
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
                        Icon(
                          Icons.vpn_key_outlined,
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
                                style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
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
                                content: Text('Codigo copiado al portapapeles'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined),
                        ),
                        IconButton(
                          tooltip: 'Compartir invitación',
                          onPressed: () => Share.share(
                            'Te invito a unirte a ${name?.isNotEmpty == true ? name : 'mi comunidad'} en Verbum. Usa el código $inviteCode.',
                          ),
                          icon: const Icon(Icons.ios_share_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (canPublish) ...[
          const SizedBox(height: 12),
          _CommunityComposerCard(
            communityId: communityId,
            currentUid: currentUid,
            currentUserData: currentUserData,
            communityService: communityService,
          ),
          const SizedBox(height: 12),
        ] else if (!isAdmin && !membersCanPost) ...[
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
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo los administradores pueden publicar en esta comunidad.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
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
        Row(
          children: [
            Text(
              'Lo que compartimos',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(Icons.auto_awesome, size: 17, color: colorScheme.secondary),
          ],
        ),
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
                      Icon(
                        Icons.forum_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aun no hay publicaciones en esta comunidad.',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
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
                  communityAdminIds: ((data['adminIds'] as List?) ?? const [])
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
    );
  }
}

class _CommunityWelcomeHero extends StatelessWidget {
  final String name;
  final String city;
  final String? imageUrl;
  final bool isAdmin;
  final bool isVerified;
  final String inviteCode;

  const _CommunityWelcomeHero({
    required this.name,
    required this.city,
    required this.imageUrl,
    required this.isAdmin,
    required this.isVerified,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF261E45).withValues(alpha: .24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF261E45),
                    Color(0xDD493878),
                    Color(0xB37B5928),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -24,
              top: -22,
              child: Icon(
                Icons.groups_rounded,
                size: 190,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          isAdmin ? 'Tu comunidad · Admin' : 'Tu comunidad',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFD8B875),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          city,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _HeroAction(
                        icon: Icons.tune_rounded,
                        label: 'Preferencias',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                      if (isAdmin && inviteCode.isNotEmpty) ...[
                        const SizedBox(width: 9),
                        _HeroAction(
                          icon: Icons.ios_share_rounded,
                          label: 'Invitar',
                          onTap: () => Share.share(
                            'Te invito a unirte a $name en Verbum. Usa el código $inviteCode.',
                          ),
                        ),
                      ],
                    ],
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

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _HeroAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        icon: const Icon(Icons.edit_outlined, size: 18),
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
        onPressed: () => _openManageAdminsDialog(context),
        icon: const Icon(Icons.manage_accounts_outlined, size: 18),
        label: const Text('Gestion manual por UID (fallback)'),
      ),
    );
  }

  Future<void> _openManageAdminsDialog(BuildContext context) async {
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

            return AlertDialog(
              title: const Text('Gestionar administradores'),
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
                          Text(
                            'Responsable principal: $createdBy',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: addController,
                            enabled: !isSubmitting,
                            decoration: const InputDecoration(
                              labelText: 'UID para agregar administrador',
                              hintText: 'Pega el UID de users/{uid}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
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
                              icon: const Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 18,
                              ),
                              label: const Text('Agregar administrador'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Administradores actuales',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...adminIds.map((adminUid) {
                            final isOwner = adminUid == createdBy;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  adminUid,
                                  style: GoogleFonts.inter(fontSize: 13),
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
                                        final email =
                                            (d?['email'] as String?)?.trim() ??
                                            '';
                                        final label = [name, email]
                                            .where((e) => e.isNotEmpty)
                                            .join(' · ');
                                        if (label.isEmpty) {
                                          return const Text(
                                            'Sin datos de perfil',
                                          );
                                        }
                                        return Text(label);
                                      },
                                    ),
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    if (isOwner)
                                      const Chip(label: Text('Principal'))
                                    else ...[
                                      TextButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (confirmContext) => AlertDialog(
                                                        title: const Text(
                                                          'Transferir liderazgo',
                                                        ),
                                                        content: Text(
                                                          'El nuevo responsable principal sera $adminUid. '
                                                          'Desde ese momento, esa cuenta gestionara administradores.',
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
                                                          ElevatedButton(
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
                                                        communityId:
                                                            communityId,
                                                        actorUid: currentUid,
                                                        newOwnerUid: adminUid,
                                                      );
                                                });
                                              },
                                        child: const Text(
                                          'Transferir liderazgo',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () => runAction(() async {
                                                await communityService
                                                    .removeCommunityAdmin(
                                                      communityId: communityId,
                                                      actorUid: currentUid,
                                                      targetUid: adminUid,
                                                    );
                                              }),
                                        child: const Text('Quitar'),
                                      ),
                                    ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => _openMembersDialog(context),
        icon: const Icon(Icons.groups_outlined, size: 18),
        label: const Text('Ver miembros'),
      ),
    );
  }

  Future<void> _openMembersDialog(BuildContext context) async {
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

            return AlertDialog(
              title: const Text('Miembros'),
              content: SizedBox(
                width: 460,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: communityService.communityStream(communityId),
                  builder: (context, communitySnapshot) {
                    if (communitySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final communityData =
                        communitySnapshot.data?.data() ?? <String, dynamic>{};
                    final liveCreatedBy =
                        (communityData['createdBy'] as String?)?.trim() ??
                        createdBy;
                    final liveAdminIdsRaw =
                        (communityData['adminIds'] as List?) ??
                        adminIds.toList();
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 140,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            'No se pudieron cargar los miembros.',
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Text(
                            'Aun no hay miembros en esta comunidad.',
                          );
                        }
                        return SizedBox(
                          height: 420,
                          child: ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final userDoc = docs[index];
                              final uid = userDoc.id;
                              final d = userDoc.data();
                              final displayName =
                                  ((d['displayName'] as String?) ?? 'Miembro')
                                      .trim();
                              final email = ((d['email'] as String?) ?? '')
                                  .trim();
                              final photo = (d['photoURL'] as String?)?.trim();
                              final isOwner = uid == liveCreatedBy;
                              final isAdmin = liveAdminIds.contains(uid);

                              Future<void> confirmTransfer() async {
                                final ok =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (confirmContext) => AlertDialog(
                                        title: const Text(
                                          'Transferir liderazgo',
                                        ),
                                        content: Text(
                                          'El nuevo responsable principal sera $uid. '
                                          'Desde ese momento, esa cuenta gestionara administradores.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              confirmContext,
                                            ).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(
                                              confirmContext,
                                            ).pop(true),
                                            child: const Text('Transferir'),
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
                                        newOwnerUid: uid,
                                      );
                                });
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      (photo != null && photo.isNotEmpty)
                                      ? NetworkImage(photo)
                                      : null,
                                  child: (photo == null || photo.isEmpty)
                                      ? Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : '?',
                                        )
                                      : null,
                                ),
                                title: Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                      : 'Miembro',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      email.isNotEmpty ? email : uid,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isAdmin || isOwner) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (isAdmin)
                                            const Chip(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              label: Text('Admin'),
                                            ),
                                          if (isOwner)
                                            const Chip(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              label: Text('Principal'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: canManage && !isOwner
                                    ? PopupMenuButton<String>(
                                        enabled: !isSubmitting,
                                        onSelected: (value) async {
                                          if (value == 'make_admin') {
                                            await runAction(() async {
                                              await communityService
                                                  .addCommunityAdmin(
                                                    communityId: communityId,
                                                    actorUid: currentUid,
                                                    targetUid: uid,
                                                  );
                                            });
                                            return;
                                          }
                                          if (value == 'remove_admin') {
                                            await runAction(() async {
                                              await communityService
                                                  .removeCommunityAdmin(
                                                    communityId: communityId,
                                                    actorUid: currentUid,
                                                    targetUid: uid,
                                                  );
                                            });
                                            return;
                                          }
                                          if (value == 'transfer') {
                                            await confirmTransfer();
                                          }
                                        },
                                        itemBuilder: (context) {
                                          if (!isAdmin) {
                                            return const [
                                              PopupMenuItem<String>(
                                                value: 'make_admin',
                                                child: Text('Hacer admin'),
                                              ),
                                            ];
                                          }
                                          return const [
                                            PopupMenuItem<String>(
                                              value: 'remove_admin',
                                              child: Text('Quitar admin'),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'transfer',
                                              child: Text(
                                                'Transferir liderazgo',
                                              ),
                                            ),
                                          ];
                                        },
                                      )
                                    : null,
                              );
                            },
                          ),
                        );
                      },
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
          child: Icon(
            Icons.edit_note_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          '¿Qué quieres compartir?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Una reflexión, intención o mensaje'),
        trailing: const Icon(Icons.arrow_outward_rounded),
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
        icon: const Icon(Icons.logout_rounded, size: 18),
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
    final isDark = theme.brightness == Brightness.dark;
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
      color: isDark ? const Color(0xFF292431) : const Color(0xFFFFFCF7),
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
                                style: GoogleFonts.inter(
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
                                  style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
