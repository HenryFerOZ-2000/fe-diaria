import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/community_service.dart';
import 'package:verbum/design_system/design_system.dart';

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
      appBar: VAppBar(
        leading: VBackButton(
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
        ),
      ),
      body: SafeArea(
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
    );
  }

  static const _padding = EdgeInsets.fromLTRB(
    VerbumSpace.gutter + 4,
    12,
    VerbumSpace.gutter + 4,
    32,
  );

  Widget _fieldIcon(VerbumIcons icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: VIcon(icon, size: 20, color: context.palette.inkMuted),
  );

  static const _iconConstraints = BoxConstraints(minWidth: 44);

  Widget _landing() {
    final t = context.type;
    return ListView(
      key: const ValueKey('landing'),
      padding: _padding,
      children: [
        const VFeatureCard(
          eyebrow: 'Crecer juntos',
          title: 'La fe se vive mejor\nen comunidad.',
          watermark: VerbumIcons.usersThree,
          photo: VerbumPhotos.communityGroup,
        ),
        const SizedBox(height: 22),
        Text(
          'Conecta con tu iglesia, parroquia o grupo para compartir, orar y '
          'caminar acompañado.',
          style: t.body.copyWith(height: 1.55, color: context.palette.inkMuted),
        ),
        const SizedBox(height: 26),
        VButton(
          label: 'Unirme a una comunidad',
          icon: VerbumIcons.link,
          iconLeading: true,
          expanded: true,
          onPressed: () => setState(() => _mode = CommunityEntryMode.join),
        ),
        const SizedBox(height: 12),
        VButton(
          label: 'Crear una comunidad',
          icon: VerbumIcons.plus,
          iconLeading: true,
          variant: VButtonVariant.outlined,
          expanded: true,
          onPressed: () => setState(() => _mode = CommunityEntryMode.create),
        ),
        const SizedBox(height: 22),
        _note(
          VerbumIcons.shield,
          'Siempre verás la información de la comunidad antes de entrar.',
        ),
      ],
    );
  }

  Widget _join() {
    final p = context.palette;
    final t = context.type;
    return ListView(
      key: const ValueKey('join'),
      padding: _padding,
      children: [
        _eyebrow('Ingresar'),
        Text('Encuentra tu\ncomunidad', style: t.display),
        const SizedBox(height: 12),
        Text(
          'Escribe el código que te compartió el administrador.',
          style: t.body.copyWith(color: p.inkMuted),
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
          style: t.heading.copyWith(fontSize: 25, letterSpacing: 5),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            hintText: 'ABC234',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: VNotice(_error!, tone: VNoticeTone.error),
          ),
        const SizedBox(height: 18),
        if (_preview == null)
          VButton(
            label: 'Continuar',
            icon: VerbumIcons.arrowRight,
            expanded: true,
            loading: _busy,
            onPressed: _busy ? null : _findCommunity,
          )
        else ...[
          _previewCard(_preview!),
          const SizedBox(height: 16),
          VButton(
            label: 'Unirme ahora',
            icon: VerbumIcons.signIn,
            iconLeading: true,
            expanded: true,
            loading: _busy,
            onPressed: _busy ? null : _joinCommunity,
          ),
          const SizedBox(height: 4),
          VButton(
            label: 'Usar otro código',
            variant: VButtonVariant.text,
            expanded: true,
            onPressed: _busy ? null : () => setState(() => _preview = null),
          ),
        ],
      ],
    );
  }

  Widget _previewCard(Map<String, dynamic> data) {
    final p = context.palette;
    final t = context.type;
    final city = data['city']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    return VSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(VerbumRadius.control),
                ),
                alignment: Alignment.center,
                child: VIcon(
                  VerbumIcons.church,
                  weight: VIconWeight.duotone,
                  color: p.rubric,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']?.toString() ?? 'Comunidad',
                      style: t.heading,
                    ),
                    if (city.isNotEmpty)
                      Text(city, style: t.caption.copyWith(color: p.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(description, style: t.body.copyWith(height: 1.45)),
          ],
          const SizedBox(height: 14),
          _note(
            VerbumIcons.shieldCheck,
            'Podrás salir de la comunidad cuando quieras.',
          ),
        ],
      ),
    );
  }

  Widget _create() {
    final t = context.type;
    return ListView(
      key: const ValueKey('create'),
      padding: _padding,
      children: [
        _eyebrow('Paso ${_createStep + 1} de 3'),
        Text(
          [
            'Dale una identidad',
            'Cuenta su historia',
            'Todo listo',
          ][_createStep],
          style: t.title,
        ),
        const SizedBox(height: 12),
        VProgressBar(
          value: (_createStep + 1) / 3,
          semanticLabel: 'Paso ${_createStep + 1} de 3',
        ),
        const SizedBox(height: 28),
        if (_createStep == 0) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: t.body,
            decoration: InputDecoration(
              labelText: 'Nombre de la comunidad',
              prefixIcon: _fieldIcon(VerbumIcons.usersThree),
              prefixIconConstraints: _iconConstraints,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            style: t.body,
            decoration: InputDecoration(
              labelText: 'Ciudad',
              prefixIcon: _fieldIcon(VerbumIcons.mapPin),
              prefixIconConstraints: _iconConstraints,
            ),
          ),
        ] else if (_createStep == 1) ...[
          TextField(
            controller: _description,
            maxLines: 4,
            style: t.body,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: '¿Qué encontrarán las personas aquí?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _leader,
            textCapitalization: TextCapitalization.words,
            style: t.body,
            decoration: InputDecoration(
              labelText: 'Responsable (opcional)',
              prefixIcon: _fieldIcon(VerbumIcons.user),
              prefixIconConstraints: _iconConstraints,
            ),
          ),
          const SizedBox(height: 14),
          _note(
            VerbumIcons.sparkle,
            'Podrás añadir imagen, administradores y permisos después.',
          ),
        ] else ...[
          VSurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Column(
              children: [
                _summaryRow(VerbumIcons.usersThree, _name.text),
                _summaryRow(VerbumIcons.mapPin, _city.text),
                _summaryRow(
                  VerbumIcons.lockSimpleOpen,
                  'Ingreso mediante invitación',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _note(
            VerbumIcons.info,
            'Serás el administrador principal de esta comunidad.',
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: VNotice(_error!, tone: VNoticeTone.error),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            if (_createStep > 0)
              Expanded(
                child: VButton(
                  label: 'Atrás',
                  variant: VButtonVariant.outlined,
                  expanded: true,
                  onPressed: _busy ? null : () => setState(() => _createStep--),
                ),
              ),
            if (_createStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: VButton(
                label: _createStep == 2 ? 'Crear comunidad' : 'Continuar',
                expanded: true,
                loading: _busy,
                onPressed: _busy ? null : _nextCreate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _success() {
    final p = context.palette;
    final t = context.type;
    final invitation =
        'Te invito a unirte a $_createdName en Verbum. Usa el código $_createdCode.';
    return ListView(
      key: const ValueKey('success'),
      padding: _padding,
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.sageSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: VIcon(VerbumIcons.check, size: 42, color: p.sageInk),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tu comunidad\nestá lista',
          textAlign: TextAlign.center,
          style: t.display,
        ),
        const SizedBox(height: 26),
        VSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Código de invitación', style: t.rubric),
              const SizedBox(height: 8),
              SelectableText(
                _createdCode ?? '',
                style: t.title.copyWith(letterSpacing: 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        VButton(
          label: 'Compartir invitación',
          icon: VerbumIcons.shareNetwork,
          iconLeading: true,
          expanded: true,
          onPressed: () =>
              SharePlus.instance.share(ShareParams(text: invitation)),
        ),
        const SizedBox(height: 10),
        VButton(
          label: 'Copiar código',
          icon: VerbumIcons.copy,
          iconLeading: true,
          variant: VButtonVariant.outlined,
          expanded: true,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _createdCode ?? ''));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Código copiado')));
          },
        ),
        const SizedBox(height: 4),
        VButton(
          label: 'Ir a mi comunidad',
          variant: VButtonVariant.text,
          expanded: true,
          onPressed: () => Navigator.pop(context),
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
    child: Text(text, style: context.type.rubric),
  );
  Widget _note(VerbumIcons icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      VIcon(icon, size: 17, color: context.palette.gold),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: context.type.caption.copyWith(
            height: 1.35,
            color: context.palette.inkMuted,
          ),
        ),
      ),
    ],
  );
  Widget _summaryRow(VerbumIcons icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        VIcon(icon, color: context.palette.rubric),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: context.type.bodyStrong.copyWith(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}
