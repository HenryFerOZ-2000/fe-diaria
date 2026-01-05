import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
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
          const SnackBar(
            content: Text('Reporte enviado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar reporte: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportar contenido',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Tipo
            Text(
              'Tipo de contenido',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // ID o enlace
            Text(
              'ID o enlace',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetIdController,
              decoration: InputDecoration(
                hintText: 'Ingresa el ID o enlace del contenido',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Motivo
            Text(
              'Motivo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedReason = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Descripción
            Text(
              'Descripción adicional',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe el problema...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 32),
            // Botón enviar
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Enviar reporte',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

