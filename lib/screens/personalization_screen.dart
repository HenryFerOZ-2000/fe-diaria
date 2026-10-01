import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/personalization/domain/profile_emotions.dart';

/// Pantalla de personalización del usuario
class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final _nameController = TextEditingController();
  final _personalizationService = PersonalizationService();
  String? _selectedEmotion;
  bool _isLoading = false;
  int _selectedMinutes = 5;
  String _preferredMoment = 'auto';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final name = _personalizationService.getUserName();
    final emotion = _personalizationService.getUserEmotion();

    if (name.isNotEmpty) {
      _nameController.text = name;
    }

    if (emotion.isNotEmpty) {
      _selectedEmotion = emotion;
    }
    _selectedMinutes = StorageService().getPreferredDailyMinutes();
    _preferredMoment = StorageService().getPreferredSpiritualMoment();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalization() async {
    if (_nameController.text.trim().isEmpty && _selectedEmotion == null) {
      _showMessage(
        'Por favor, ingresa un nombre de usuario o selecciona cómo te sientes',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      // Guardar nombre de usuario (para saludos y personalización en la app)
      if (_nameController.text.trim().isNotEmpty) {
        await provider.setUserName(_nameController.text.trim());
      }

      // Guardar emoción
      if (_selectedEmotion != null) {
        await provider.setUserEmotion(_selectedEmotion!);
      }
      await StorageService().setPreferredDailyMinutes(_selectedMinutes);
      await StorageService().setPreferredSpiritualMoment(_preferredMoment);

      // Recargar versículo personalizado si hay emoción
      if (_selectedEmotion != null) {
        await provider.loadTodayVerse();
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Personalización guardada exitosamente');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error al guardar la personalización', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const moments = <String, String>{
      'auto': 'Según mi día',
      'morning': 'Mañana',
      'evening': 'Noche',
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: VAppBar(
        title: Text('Personalización', style: context.type.heading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VerbumSpace.gutter,
            0,
            VerbumSpace.gutter,
            28,
          ),
          children: [
            const VSectionHeader(
              '¿Cómo quieres que te llamemos?',
              eyebrow: 'Tu nombre',
              padding: EdgeInsets.fromLTRB(2, 16, 2, 10),
            ),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Tu nombre o usuario para los saludos',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VIcon(VerbumIcons.at, size: 20, color: p.inkSubtle),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
              ),
            ),
            const VSectionHeader(
              '¿Cómo te sientes hoy?',
              eyebrow: 'Tu ánimo',
              padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                for (final emotion in profileEmotions)
                  VChoiceTile(
                    icon: emotion.icon,
                    label: emotion.label,
                    selected: _selectedEmotion == emotion.id,
                    onTap: () => setState(() => _selectedEmotion = emotion.id),
                  ),
              ],
            ),
            const VSectionHeader(
              'Tu ritmo diario',
              eyebrow: 'Tu tiempo',
              padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
            ),
            VSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cuánto tiempo quieres dedicar normalmente?',
                    style: context.type.bodyStrong,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final minutes in const [3, 5, 10])
                        ChoiceChip(
                          label: Text('$minutes min'),
                          selected: _selectedMinutes == minutes,
                          onSelected: (_) =>
                              setState(() => _selectedMinutes = minutes),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '¿Cuándo prefieres tu momento principal?',
                    style: context.type.bodyStrong,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in moments.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _preferredMoment == entry.key,
                          onSelected: (_) =>
                              setState(() => _preferredMoment = entry.key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            VButton(
              label: _isLoading ? 'Guardando…' : 'Guardar personalización',
              icon: _isLoading ? null : VerbumIcons.check,
              iconLeading: true,
              expanded: true,
              onPressed: _isLoading ? null : _savePersonalization,
            ),
            const SizedBox(height: 16),
            VSurfaceCard(
              tone: VSurfaceTone.muted,
              radius: VerbumRadius.tile,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VIcon(VerbumIcons.info, size: 20, color: p.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu nombre se usa en saludos y notificaciones. La emoción '
                      'ayuda a elegir versículos y oraciones acordes a tu día.',
                      style: context.type.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
