import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';
import '../services/social_service.dart';
import '../widgets/sign_in_prompt.dart';
import 'package:verbum/design_system/design_system.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _social = SocialService();
  final _profile = ProfileService();
  final _displayController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;
  String? _photoUrl;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _error = 'Inicia sesión para editar tu perfil';
          _loading = false;
        });
      }
      return;
    }
    try {
      final snapshot = await _profile.getUser(uid);
      final data = snapshot.data() ?? {};
      _displayController.text = data['displayName'] as String? ?? '';
      _usernameController.text = data['username'] as String? ?? '';
      _photoUrl = data['photoURL'] as String?;
    } catch (_) {
      _error = 'No pudimos cargar tu perfil';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validUsername(String value) =>
      RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(value);

  Future<void> _save() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final displayName = _displayController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    if (displayName.isEmpty) {
      _showMessage('Escribe el nombre con el que quieres aparecer.');
      return;
    }
    if (!_validUsername(username)) {
      _showMessage('Revisa tu nombre de usuario antes de continuar.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _social.setUsername(username);
      await _social.updateProfile(
        uid: uid,
        displayName: displayName,
        photoURL: _photoUrl,
      );
      if (!mounted) return;
      _showMessage('Perfil actualizado');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString();
      if (raw.contains('username_taken') || raw.contains('already-exists')) {
        _showMessage('Ese nombre de usuario ya está en uso.');
      } else {
        _showMessage('No pudimos guardar los cambios. Inténtalo nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndUpload() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _uploadingPhoto = true;
      _pickedFile = picked;
    });
    try {
      final reference = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('avatar.jpg');
      await reference.putFile(File(picked.path));
      final url = await reference.getDownloadURL();
      _photoUrl = url;
      await _social.updateProfile(uid: uid, photoURL: url);
      if (mounted) _showMessage('Foto actualizada');
    } catch (_) {
      if (mounted) _showMessage('No pudimos subir la foto.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final appBar = VAppBar(title: Text('Editar perfil', style: t.heading));

    if (_loading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(
          child: VEmptyState(title: 'Cargando tu perfil', loading: true),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: appBar,
        body: _auth.currentUser == null
            ? ListView(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  16,
                  VerbumSpace.gutter,
                  32,
                ),
                children: [
                  SignInPrompt(
                    title: _error!,
                    message:
                        'Con tu cuenta puedes elegir cómo apareces en la '
                        'comunidad.',
                  ),
                ],
              )
            : Center(
                child: VEmptyState(
                  icon: VerbumIcons.warningCircle,
                  title: _error!,
                  message: 'Revisa tu conexión e inténtalo de nuevo.',
                ),
              ),
      );
    }

    final ImageProvider? image = _pickedFile != null
        ? FileImage(File(_pickedFile!.path))
        : (_photoUrl?.isNotEmpty == true ? NetworkImage(_photoUrl!) : null);
    final username = _usernameController.text.trim().toLowerCase();
    final usernameValid = username.isEmpty || _validUsername(username);

    Widget fieldIcon(VerbumIcons icon) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: VIcon(icon, size: 20, color: p.inkMuted),
    );
    const iconConstraints = BoxConstraints(minWidth: 44);

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          8,
          VerbumSpace.gutter,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.surface,
                        boxShadow: VerbumShadows.soft(p),
                      ),
                      child: CircleAvatar(
                        radius: 51,
                        backgroundColor: p.surfaceMuted,
                        backgroundImage: image,
                        child: image == null
                            ? VIcon(VerbumIcons.user, size: 42, color: p.rubric)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: 2,
                      child: Tooltip(
                        message: 'Cambiar foto',
                        child: Material(
                          color: p.emphasis,
                          shape: CircleBorder(
                            side: BorderSide(color: p.background, width: 3),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _uploadingPhoto ? null : _pickAndUpload,
                            child: SizedBox.square(
                              dimension: 42,
                              child: Center(
                                child: _uploadingPhoto
                                    ? SizedBox.square(
                                        dimension: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: p.onEmphasis,
                                        ),
                                      )
                                    : VIcon(
                                        VerbumIcons.camera,
                                        size: 19,
                                        color: p.onEmphasis,
                                        semanticLabel: 'Cambiar foto',
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  'Tu rostro en la comunidad',
                  style: t.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const VSectionHeader(
            'Tu identidad en Verbum',
            eyebrow: 'Cómo quieres aparecer',
          ),
          VSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _displayController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: t.body,
                  decoration: InputDecoration(
                    labelText: 'Nombre visible',
                    hintText: '¿Cómo quieres que te llamemos?',
                    prefixIcon: fieldIcon(VerbumIcons.identificationBadge),
                    prefixIconConstraints: iconConstraints,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: t.body,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: 'tu.usuario',
                    prefixIcon: fieldIcon(VerbumIcons.at),
                    prefixIconConstraints: iconConstraints,
                    errorText: usernameValid
                        ? null
                        : 'Usa entre 3 y 20 letras, números, punto o _',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: VIcon(VerbumIcons.info, size: 15, color: p.gold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu usuario ayuda a que otros puedan reconocerte '
                        'cuando compartes en Comunidad.',
                        style: t.caption.copyWith(
                          color: p.inkMuted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          VButton(
            label: _saving ? 'Guardando…' : 'Guardar cambios',
            icon: VerbumIcons.check,
            iconLeading: true,
            expanded: true,
            loading: _saving,
            onPressed: _saving || !usernameValid ? null : _save,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Puedes cambiar estos datos cuando quieras',
              style: t.caption.copyWith(color: p.inkSubtle),
            ),
          ),
        ],
      ),
    );
  }
}
