import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../design_system/design_system.dart';
import '../services/privacy_security_service.dart';

class ReportContentScreen extends StatefulWidget {
  const ReportContentScreen({super.key});

  @override
  State<ReportContentScreen> createState() => _ReportContentScreenState();
}

class _ReportContentScreenState extends State<ReportContentScreen> {
  final _service = PrivacySecurityService();
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _targetIdController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'Post';
  String _selectedReason = 'Spam';
  bool _isSubmitting = false;

  final List<String> _types = ['Post', 'Comentario', 'Usuario'];
  final List<String> _reasons = [
    'Spam',
    'Acoso',
    'Contenido inapropiado',
    'Suplantación',
    'Otro',
  ];

  @override
  void dispose() {
    _targetIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.submitReport(
        reporterUid: uid,
        type: _selectedType,
        targetId: _targetIdController.text.trim(),
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado correctamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar reporte: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    Widget dropdown(
      String value,
      List<String> options,
      ValueChanged<String> onSelected,
    ) {
      return DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: p.surface,
        borderRadius: BorderRadius.circular(VerbumRadius.control),
        icon: VIcon(VerbumIcons.caretDown, size: 18, color: p.inkMuted),
        style: t.body,
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      );
    }

    return Scaffold(
      appBar: VAppBar(title: Text('Reportar contenido', style: t.heading)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VerbumSpace.gutter,
            12,
            VerbumSpace.gutter,
            40,
          ),
          children: [
            const _FieldLabel('Tipo de contenido'),
            dropdown(
              _selectedType,
              _types,
              (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('ID o enlace'),
            TextFormField(
              controller: _targetIdController,
              style: t.body,
              decoration: const InputDecoration(
                hintText: 'Ingresa el ID o enlace del contenido',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Motivo'),
            dropdown(
              _selectedReason,
              _reasons,
              (value) => setState(() => _selectedReason = value),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Descripción adicional'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              style: t.body,
              decoration: const InputDecoration(
                hintText: 'Describe el problema...',
              ),
            ),
            const SizedBox(height: 28),
            VButton(
              label: 'Enviar reporte',
              icon: VerbumIcons.flag,
              expanded: true,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: context.type.bodyStrong.copyWith(
          fontSize: 13,
          color: context.palette.inkMuted,
        ),
      ),
    );
  }
}
