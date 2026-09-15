import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        SliverAppBar(
          pinned: true,
          backgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: .94),
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Tu espacio',
            style: GoogleFonts.playfairDisplay(
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: const [VerbumHeaderActions(showProfile: false)],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
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
                _CompletionCard(
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
              ],
              const SizedBox(height: 16),
              _WeeklyJourneyCard(stats: stats),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${stats.prayersCompleted}',
                      label: 'Oraciones',
                      icon: Icons.favorite_outline_rounded,
                      tint: const Color(0xFF9B5C62),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      value: '${stats.versesRead}',
                      label: 'Lecturas',
                      icon: Icons.menu_book_rounded,
                      tint: const Color(0xFF6B7398),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      value: '${stats.activeDaysLast30}',
                      label: 'Días activos',
                      icon: Icons.wb_sunny_outlined,
                      tint: const Color(0xFF9A783D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionTitle(
                eyebrow: 'TU HUELLA',
                title: 'Lo que has ido cultivando',
              ),
              const SizedBox(height: 12),
              _ActionGroup(
                children: [
                  _ProfileAction(
                    icon: Icons.route_outlined,
                    title: 'Caminos espirituales',
                    subtitle: 'Procesos guiados para lo que hoy necesitas',
                    onTap: () =>
                        Navigator.pushNamed(context, '/spiritual-paths'),
                  ),
                  _ProfileAction(
                    icon: Icons.forum_outlined,
                    title: 'Mis publicaciones',
                    subtitle: '${stats.postsCreated} compartidas en comunidad',
                    onTap: () => Navigator.pushNamed(context, '/my-profile'),
                  ),
                  _ProfileAction(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Contenido guardado',
                    subtitle: 'Vuelve a los versículos que te hablaron',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),
                  _ProfileAction(
                    icon: Icons.insights_outlined,
                    title: 'Datos espirituales',
                    subtitle: 'Métricas, hitos y logros de tu camino',
                    onTap: () =>
                        Navigator.pushNamed(context, '/spiritual-stats'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _SectionTitle(
                eyebrow: 'A TU MANERA',
                title: 'Personaliza tu experiencia',
              ),
              const SizedBox(height: 12),
              _ActionGroup(
                children: [
                  _ProfileAction(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Tradición cristiana',
                    subtitle: tradition,
                    onTap: onTraditionTap,
                  ),
                  _ProfileAction(
                    icon: Icons.tune_rounded,
                    title: 'Mi ritmo espiritual',
                    subtitle: 'Tiempo, emoción y momento preferido',
                    onTap: () =>
                        Navigator.pushNamed(context, '/personalization'),
                  ),
                  _ProfileAction(
                    icon: Icons.notifications_none_rounded,
                    title: 'Recordatorios y preferencias',
                    subtitle: 'Horarios, contenido, idioma y apariencia',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _SectionTitle(
                eyebrow: 'VERBUM',
                title: 'Cuenta y aplicación',
              ),
              const SizedBox(height: 12),
              _ActionGroup(
                children: [
                  _ProfileAction(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Cuenta y seguridad',
                    subtitle: 'Sesiones, privacidad y datos de la cuenta',
                    onTap: () =>
                        Navigator.pushNamed(context, '/account-settings'),
                  ),
                  _ProfileAction(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Plan de Verbum',
                    subtitle: 'Consulta los beneficios de tu plan',
                    onTap: () => Navigator.pushNamed(context, '/plan'),
                  ),
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    title: 'Ayuda y soporte',
                    subtitle: 'Preguntas frecuentes y contacto',
                    onTap: () => Navigator.pushNamed(context, '/help-support'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Tu actividad se sincroniza de forma segura',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2345), Color(0xFF493878), Color(0xFF594675)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33264F).withValues(alpha: .25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD7B36A).withValues(alpha: .13),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE4C682).withValues(alpha: .8),
                    width: 1.4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  backgroundImage: photoUrl?.isNotEmpty == true
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl?.isNotEmpty == true
                      ? null
                      : Text(
                          name.characters.first.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username.isEmpty ? 'Tu camino en Verbum' : '@$username',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .12),
                        ),
                      ),
                      child: Text(
                        tradition,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF1DDAA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Editar perfil',
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyJourneyCard extends StatelessWidget {
  final SpiritualStats stats;
  const _WeeklyJourneyCard({required this.stats});

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final completed = days
        .where((day) => stats.activeDaysMap[_dateKey(day)] == true)
        .length;
    final todayDone = stats.activeDaysMap[_dateKey(now)] == true;
    final labels = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/streak'),
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .8),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu semana con Dios',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          todayDone
                              ? 'Hoy ya diste tu paso'
                              : 'Aún puedes dedicarte un momento',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${stats.currentStreak}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'días',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final active =
                      stats.activeDaysMap[_dateKey(days[index])] == true;
                  final isToday = index == now.weekday - 1;
                  return Column(
                    children: [
                      Text(
                        labels[index],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 29,
                        height: 29,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHighest.withValues(
                                  alpha: .65,
                                ),
                          border: isToday
                              ? Border.all(color: scheme.secondary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          active ? Icons.check_rounded : Icons.circle,
                          size: active ? 16 : 5,
                          color: active ? Colors.white : scheme.outline,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$completed de 7 días esta semana',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    'Ver constancia',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color tint;
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: tint),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  const _SectionTitle({required this.eyebrow, required this.title});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: GoogleFonts.inter(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ActionGroup extends StatelessWidget {
  final List<_ProfileAction> children;
  const _ActionGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .85)),
      ),
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              children[index],
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 16,
                  color: scheme.outlineVariant.withValues(alpha: .7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: scheme.outline,
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CompletionCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.secondaryContainer.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Completa tu nombre y usuario para que la comunidad pueda reconocerte.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _SignOutSheet extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _SignOutSheet({required this.onCancel, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¿Cerrar sesión?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tu camino y tus datos permanecerán guardados para cuando regreses.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Cerrar sesión'),
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
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
