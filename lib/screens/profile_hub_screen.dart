import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/spiritual_stats.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/profile_service.dart';
import '../services/spiritual_stats_service.dart';
import '../services/storage_service.dart';
import '../widgets/verbum_ambient_background.dart';
import '../widgets/verbum_header_actions.dart';
import 'favorites_screen.dart';
import 'traditional_prayers_religion_selection_screen.dart';
import 'welcome_auth_screen.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/today/application/constancy_progress.dart';
import '../features/today/presentation/constancy_card.dart';
import '../features/today/application/constancy_calendar.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();
  final _statsService = SpiritualStatsService();

  String get _tradition {
    switch (StorageService().getValidatedTraditionalPrayersReligion()) {
      case 'catolica':
        return 'Tradición católica';
      case 'cristiana':
        return 'Tradición evangélica';
      default:
        return 'Cristiana general';
    }
  }

  Future<void> _changeTradition() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TraditionalPrayersReligionSelectionScreen(),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SignOutSheet(
        onCancel: () => Navigator.pop(sheetContext, false),
        onConfirm: () => Navigator.pop(sheetContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<app_auth.AuthProvider>().signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

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
        glowAlignment: const Alignment(1.25, -.95),
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _profileService.userStream(uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting &&
                  !profileSnapshot.hasData) {
                return const _ProfileLoading();
              }
              final data = profileSnapshot.data?.data() ?? <String, dynamic>{};
              return StreamBuilder<SpiritualStats>(
                stream: _statsService.statsStream(),
                initialData: SpiritualStats.empty(),
                builder: (context, statsSnapshot) => _ProfileContent(
                  data: data,
                  stats: statsSnapshot.data ?? SpiritualStats.empty(),
                  tradition: _tradition,
                  onTraditionTap: _changeTradition,
                  onLogout: _logout,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final SpiritualStats stats;
  final String tradition;
  final VoidCallback onTraditionTap;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.data,
    required this.stats,
    required this.tradition,
    required this.onTraditionTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (data['displayName'] as String?)?.trim();
    final username = (data['username'] as String?)?.trim() ?? '';
    final photoUrl = (data['photoURL'] as String?)?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'Tu perfil';
    final complete = displayName?.isNotEmpty == true && username.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        VAppBar.sliver(
          context,
          title: Text('Tu espacio', style: context.type.display),
          actions: const [VerbumHeaderActions(showProfile: false)],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            VerbumSpace.gutter,
            6,
            VerbumSpace.gutter,
            MediaQuery.paddingOf(context).bottom + 28,
          ),
          sliver: SliverList.list(
            children: [
              _IdentityCard(
                name: name,
                username: username,
                photoUrl: photoUrl,
                tradition: tradition,
              ),
              if (!complete) ...[
                const SizedBox(height: 12),
                VActionTile(
                  tone: VSurfaceTone.accent,
                  icon: VerbumIcons.userPlus,
                  title: 'Completa tu perfil',
                  subtitle:
                      'Tu nombre y usuario ayudan a que la comunidad te reconozca.',
                  iconColor: context.palette.accent,
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
              ],
              const SizedBox(height: 16),
              _weekCard(context),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: VStatTile(
                      value: '${stats.prayersCompleted}',
                      label: 'Oraciones',
                      icon: VerbumIcons.handsPraying,
                      iconColor: context.palette.rubric,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VStatTile(
                      value: '${stats.versesRead}',
                      label: 'Lecturas',
                      icon: VerbumIcons.bookOpenText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VStatTile(
                      value: '${stats.activeDaysLast30}',
                      label: 'Días activos',
                      icon: VerbumIcons.sun,
                      iconColor: context.palette.accent,
                    ),
                  ),
                ],
              ),
              const VSectionHeader(
                'Lo que has ido cultivando',
                eyebrow: 'Tu huella',
                padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
              ),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.path,
                    title: 'Caminos espirituales',
                    subtitle: 'Procesos guiados para lo que hoy necesitas',
                    onTap: () =>
                        Navigator.pushNamed(context, '/spiritual-paths'),
                  ),
                  VListRow(
                    leading: VerbumIcons.chatsCircle,
                    title: 'Mis publicaciones',
                    subtitle: '${stats.postsCreated} compartidas en comunidad',
                    onTap: () => Navigator.pushNamed(context, '/my-profile'),
                  ),
                  VListRow(
                    leading: VerbumIcons.bookmarkSimple,
                    title: 'Contenido guardado',
                    subtitle: 'Vuelve a los versículos que te hablaron',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),
                  VListRow(
                    leading: VerbumIcons.chartLineUp,
                    title: 'Datos espirituales',
                    subtitle: 'Métricas, hitos y logros de tu camino',
                    onTap: () =>
                        Navigator.pushNamed(context, '/spiritual-stats'),
                  ),
                ],
              ),
              const VSectionHeader(
                'Personaliza tu experiencia',
                eyebrow: 'A tu manera',
                padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
              ),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.church,
                    title: 'Tradición cristiana',
                    value: tradition,
                    onTap: onTraditionTap,
                  ),
                  VListRow(
                    leading: VerbumIcons.slidersHorizontal,
                    title: 'Mi ritmo espiritual',
                    subtitle: 'Tiempo, emoción y momento preferido',
                    onTap: () =>
                        Navigator.pushNamed(context, '/personalization'),
                  ),
                  VListRow(
                    leading: VerbumIcons.bell,
                    title: 'Recordatorios y preferencias',
                    subtitle: 'Horarios, contenido, idioma y apariencia',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
              const VSectionHeader(
                'Cuenta y aplicación',
                eyebrow: 'Verbum',
                padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
              ),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.userGear,
                    title: 'Cuenta y seguridad',
                    subtitle: 'Sesiones, privacidad y datos de la cuenta',
                    onTap: () =>
                        Navigator.pushNamed(context, '/account-settings'),
                  ),
                  VListRow(
                    leading: VerbumIcons.medal,
                    title: 'Plan de Verbum',
                    subtitle: 'Consulta los beneficios de tu plan',
                    onTap: () => Navigator.pushNamed(context, '/plan'),
                  ),
                  VListRow(
                    leading: VerbumIcons.question,
                    title: 'Ayuda y soporte',
                    subtitle: 'Preguntas frecuentes y contacto',
                    onTap: () => Navigator.pushNamed(context, '/help-support'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: VButton(
                  label: 'Cerrar sesión',
                  icon: VerbumIcons.signOut,
                  iconLeading: true,
                  variant: VButtonVariant.text,
                  onPressed: onLogout,
                ),
              ),
              Center(
                child: Text(
                  'Tu actividad se sincroniza de forma segura',
                  style: context.type.caption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// La misma tarjeta de constancia de "Hoy", con los datos de la semana.
  Widget _weekCard(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final week = [
      for (var i = 0; i < 7; i++)
        stats.activeDaysMap[ymdKey(monday.add(Duration(days: i)))] == true,
    ];
    return ConstancyCard(
      progress: ConstancyProgress.from(
        totalDays: stats.currentStreak,
        completedMoments: week[now.weekday - 1] ? 1 : 0,
        totalMoments: 1,
      ),
      weekLabels: const ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
      weekCompleted: week,
      todayIndex: now.weekday - 1,
      onTap: () => Navigator.pushNamed(context, '/streak'),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String username;
  final String? photoUrl;
  final String tradition;

  const _IdentityCard({
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.tradition,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final hasPhoto = photoUrl?.isNotEmpty == true;
    return VSurfaceCard(
      tone: VSurfaceTone.ink,
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.gold, width: 1.4),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: p.onInverse.withValues(alpha: .1),
              backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      name.characters.first.toUpperCase(),
                      style: type.title.copyWith(color: p.onInverse),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.title.copyWith(color: p.onInverse, fontSize: 25),
                ),
                const SizedBox(height: 2),
                Text(
                  username.isEmpty ? 'Tu camino en Verbum' : '@$username',
                  style: type.body.copyWith(
                    color: p.onInverse.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 10),
                VMetaChip(
                  icon: VerbumIcons.church,
                  label: tradition,
                  color: p.gold,
                ),
              ],
            ),
          ),
          VIconButton(
            icon: VerbumIcons.pencilSimple,
            semanticLabel: 'Editar perfil',
            variant: VIconButtonVariant.ghost,
            color: p.onInverse,
            onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
        ],
      ),
    );
  }
}

class _SignOutSheet extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _SignOutSheet({required this.onCancel, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VerbumRadius.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: p.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          Text('¿Cerrar sesión?', style: context.type.title),
          const SizedBox(height: 7),
          Text(
            'Tu camino y tus datos permanecerán guardados para cuando regreses.',
            textAlign: TextAlign.center,
            style: context.type.body,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Cancelar',
                  variant: VButtonVariant.outlined,
                  expanded: true,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VButton(
                  label: 'Cerrar sesión',
                  expanded: true,
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();
  @override
  Widget build(BuildContext context) => const Center(
    child: VEmptyState(loading: true, title: 'Cargando tu espacio…'),
  );
}
