import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';
import '../services/social_service.dart';
import '../widgets/verbum_ambient_background.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final ImageProvider? image = _pickedFile != null
        ? FileImage(File(_pickedFile!.path))
        : (_photoUrl?.isNotEmpty == true ? NetworkImage(_photoUrl!) : null);
    final username = _usernameController.text.trim().toLowerCase();
    final usernameValid = username.isEmpty || _validUsername(username);

    return Scaffold(
      body: VerbumAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(
                title: Text(
                  'Editar perfil',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    border: Border.all(
                                      color: scheme.secondary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 51,
                                    backgroundColor: scheme.primaryContainer,
                                    backgroundImage: image,
                                    child: image == null
                                        ? Icon(
                                            Icons.person_outline_rounded,
                                            size: 42,
                                            color: scheme.primary,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: -3,
                                  bottom: 2,
                                  child: IconButton.filled(
                                    tooltip: 'Cambiar foto',
                                    onPressed: _uploadingPhoto
                                        ? null
                                        : _pickAndUpload,
                                    style: IconButton.styleFrom(
                                      backgroundColor: scheme.primary,
                                      foregroundColor: scheme.onPrimary,
                                      side: BorderSide(
                                        color: scheme.surface,
                                        width: 3,
                                      ),
                                    ),
                                    icon: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.photo_camera_outlined,
                                            size: 19,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            Text(
                              'Tu rostro en la comunidad',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'CÓMO QUIERES APARECER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu identidad en Verbum',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _displayController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nombre visible',
                                hintText: '¿Cómo quieres que te llamemos?',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _usernameController,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                hintText: 'tu.usuario',
                                prefixText: '@',
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                ),
                                errorText: usernameValid
                                    ? null
                                    : 'Usa entre 3 y 20 letras, números, punto o _',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Tu usuario ayuda a que otros puedan reconocerte cuando compartes en Comunidad.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      height: 1.45,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving || !usernameValid ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _saving ? 'Guardando…' : 'Guardar cambios',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Puedes cambiar estos datos cuando quieras',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
