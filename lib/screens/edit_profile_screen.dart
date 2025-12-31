import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/social_service.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _social = SocialService();
  final _profile = ProfileService();
  final _displayCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isPublic = true;
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

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Inicia sesión para editar tu perfil';
        _loading = false;
      });
      return;
    }
    try {
      final snap = await _profile.getUser(uid);
      final data = snap.data() ?? {};
      _displayCtrl.text = data['displayName'] ?? '';
      _usernameCtrl.text = data['username'] ?? '';
      _bioCtrl.text = data['bio'] ?? '';
      _isPublic = (data['isPublic'] ?? true) as bool;
      _photoUrl = data['photoURL'] as String?;
    } catch (e) {
      _error = 'Error al cargar perfil';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _validUsername(String value) {
    return RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(value);
  }

  Future<void> _save() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final username = _usernameCtrl.text.trim().toLowerCase();
    if (!_validUsername(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username inválido: usa 3-20 chars [a-z0-9._]')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _social.setUsername(username);
      await _social.updateProfile(
        uid: uid,
        displayName: _displayCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        isPublic: _isPublic,
        photoURL: _photoUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _uploadingPhoto = true;
      _pickedFile = picked;
    });
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('users').child(uid).child('avatar.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        _photoUrl = url;
      });
      // guardar de inmediato para no perder consistencia
      await _social.updateProfile(uid: uid, photoURL: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
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
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: _pickedFile != null
                      ? FileImage(File(_pickedFile!.path))
                      : (_photoUrl != null ? NetworkImage(_photoUrl!) : null) as ImageProvider<Object>?,
                  child: _pickedFile == null && _photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _uploadingPhoto ? null : _pickAndUpload,
                  child: _uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Cambiar foto'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayCtrl,
              decoration: const InputDecoration(labelText: 'Nombre visible'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username (min 3, max 20)'),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'Solo minúsculas, números, punto o guión bajo',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio (opcional)', counterText: ''),
              maxLength: 160,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Perfil público'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


