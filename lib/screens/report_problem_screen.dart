import 'package:flutter/material.dart';
import '../design_system/design_system.dart';
import '../services/help_support_service.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _service = HelpSupportService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Bug';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug',
    'Sugerencia',
    'Cuenta',
    'Contenido',
    'Otro',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _service.submitSupportTicket(
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reporte enviado correctamente. Gracias por tu feedback.',
            ),
          ),
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
    return Scaffold(
      appBar: VAppBar(
        title: Text('Reportar un problema', style: context.type.heading),
      ),
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
            const _FieldLabel('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: p.surface,
              borderRadius: BorderRadius.circular(VerbumRadius.control),
              icon: VIcon(VerbumIcons.caretDown, size: 18, color: p.inkMuted),
              style: context.type.body,
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Descripción del problema'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 8,
              style: context.type.body,
              decoration: const InputDecoration(
                hintText: 'Describe el problema o sugerencia en detalle...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor describe el problema';
                }
                if (value.trim().length < 10) {
                  return 'La descripción debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const VNotice('Pronto podrás adjuntar una captura de pantalla.'),
            const SizedBox(height: 28),
            VButton(
              label: 'Enviar reporte',
              icon: VerbumIcons.paperPlaneRight,
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
