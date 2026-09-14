import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../services/community_service.dart';
import '../widgets/verbum_ambient_background.dart';

enum CommunityEntryMode { landing, join, create, success }

class CommunityEntryScreen extends StatefulWidget {
  final String uid;
  final CommunityEntryMode initialMode;

  const CommunityEntryScreen({
    super.key,
    required this.uid,
    this.initialMode = CommunityEntryMode.landing,
  });

  @override
  State<CommunityEntryScreen> createState() => _CommunityEntryScreenState();
}

class _CommunityEntryScreenState extends State<CommunityEntryScreen> {
  final _service = CommunityService();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _leader = TextEditingController();
  late CommunityEntryMode _mode = widget.initialMode;
  Map<String, dynamic>? _preview;
  int _createStep = 0;
  bool _busy = false;
  String? _error;
  String? _createdCode;
  String? _createdName;

  @override
  void dispose() {
    for (final controller in [_code, _name, _city, _description, _leader]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (_mode == CommunityEntryMode.landing) {
              Navigator.pop(context);
            } else {
              setState(() {
                _mode = CommunityEntryMode.landing;
                _preview = null;
                _error = null;
              });
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: VerbumAmbientBackground(
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: switch (_mode) {
              CommunityEntryMode.landing => _landing(),
              CommunityEntryMode.join => _join(),
              CommunityEntryMode.create => _create(),
              CommunityEntryMode.success => _success(),
            },
          ),
        ),
      ),
    );
  }

  Widget _landing() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('landing'),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF261E45), Color(0xFF5C487C), Color(0xFF8A6942)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -20,
                child: Icon(
                  Icons.groups_rounded,
                  size: 190,
                  color: Colors.white.withValues(alpha: .07),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'CRECER JUNTOS',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD8B875),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La fe se vive mejor\nen comunidad.',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Conecta con tu iglesia, parroquia o grupo para compartir, orar y caminar acompañado.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.55,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: () => setState(() => _mode = CommunityEntryMode.join),
          icon: const Icon(Icons.link_rounded),
          label: const Text('Unirme a una comunidad'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _mode = CommunityEntryMode.create),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear una comunidad'),
        ),
        const SizedBox(height: 22),
        _note(
          Icons.shield_outlined,
          'Siempre verás la información de la comunidad antes de entrar.',
        ),
      ],
    );
  }

  Widget _join() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('join'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        _eyebrow('INGRESAR'),
        Text(
          'Encuentra tu\ncomunidad',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Escribe el código que te compartió el administrador.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _code,
          enabled: !_busy && _preview == null,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(8),
          ],
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: 5,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            hintText: 'ABC234',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        const SizedBox(height: 18),
        if (_preview == null)
          FilledButton(
            onPressed: _busy ? null : _findCommunity,
            child: _loadingLabel('Continuar'),
          )
        else ...[
          _previewCard(_preview!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _joinCommunity,
            icon: const Icon(Icons.login_rounded),
            label: _loadingLabel('Unirme ahora'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _preview = null),
            child: const Text('Usar otro código'),
          ),
        ],
      ],
    );
  }

  Widget _previewCard(Map<String, dynamic> data) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.church_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']?.toString() ?? 'Comunidad',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data['city']?.toString() ?? '',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['description']?.toString() ?? '',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 14),
          _note(
            Icons.verified_user_outlined,
            'Podrás salir de la comunidad cuando quieras.',
          ),
        ],
      ),
    );
  }

  Widget _create() {
    return ListView(
      key: const ValueKey('create'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _eyebrow('PASO ${_createStep + 1} DE 3'),
        Text(
          [
            'Dale una identidad',
            'Cuenta su historia',
            'Todo listo',
          ][_createStep],
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_createStep + 1) / 3,
          minHeight: 4,
          borderRadius: BorderRadius.circular(9),
        ),
        const SizedBox(height: 28),
        if (_createStep == 0) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la comunidad',
              prefixIcon: Icon(Icons.groups_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ] else if (_createStep == 1) ...[
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: '¿Qué encontrarán las personas aquí?',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _leader,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Responsable (opcional)',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          _note(
            Icons.auto_awesome_outlined,
            'Podrás añadir imagen, administradores y permisos después.',
          ),
        ] else ...[
          _summaryRow(Icons.groups_rounded, _name.text),
          _summaryRow(Icons.location_on_outlined, _city.text),
          _summaryRow(Icons.lock_open_rounded, 'Ingreso mediante invitación'),
          const SizedBox(height: 12),
          _note(
            Icons.info_outline,
            'Serás el administrador principal de esta comunidad.',
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            if (_createStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => setState(() => _createStep--),
                  child: const Text('Atrás'),
                ),
              ),
            if (_createStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _busy ? null : _nextCreate,
                child: _loadingLabel(
                  _createStep == 2 ? 'Crear comunidad' : 'Continuar',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _success() {
    final invitation =
        'Te invito a unirte a $_createdName en Verbum. Usa el código $_createdCode.';
    return ListView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 30),
        Icon(
          Icons.check_circle_rounded,
          size: 78,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 18),
        Text(
          'Tu comunidad\nestá lista',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                'CÓDIGO DE INVITACIÓN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _createdCode ?? '',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Share.share(invitation),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Compartir invitación'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _createdCode ?? ''));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Código copiado')));
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar código'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ir a mi comunidad'),
        ),
      ],
    );
  }

  Future<void> _findCommunity() async {
    if (_code.text.trim().isEmpty) {
      return setState(() => _error = 'Escribe el código de invitación.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.findCommunityByInviteCode(_code.text);
      if (!mounted) return;
      setState(
        () => result == null
            ? _error = 'No encontramos una comunidad con ese código.'
            : _preview = result,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinCommunity() async {
    setState(() => _busy = true);
    try {
      await _service.joinCommunityWithCode(
        uid: widget.uid,
        inviteCode: _code.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _nextCreate() async {
    setState(() => _error = null);
    if (_createStep == 0 &&
        (_name.text.trim().isEmpty || _city.text.trim().isEmpty)) {
      return setState(() => _error = 'Completa el nombre y la ciudad.');
    }
    if (_createStep < 2) {
      return setState(() => _createStep++);
    }
    setState(() => _busy = true);
    try {
      final id = await _service.createCommunity(
        uid: widget.uid,
        name: _name.text,
        city: _city.text,
        description: _description.text,
        priestName: _leader.text,
      );
      final doc = await _service.communityStream(id).first;
      if (!mounted) return;
      setState(() {
        _createdName = _name.text.trim();
        _createdCode = doc.data()?['inviteCode']?.toString();
        _mode = CommunityEntryMode.success;
        _busy = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Widget _eyebrow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
  Widget _note(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.tertiary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
  Widget _summaryRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  Widget _loadingLabel(String text) => _busy
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(text);
}
