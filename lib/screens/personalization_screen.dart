import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';

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

  final List<Map<String, dynamic>> _emotions = [
    {'id': 'ansioso', 'name': 'Ansioso', 'icon': Icons.psychology, 'color': Color(0xFFFF9800)},
    {'id': 'triste', 'name': 'Triste', 'icon': Icons.sentiment_very_dissatisfied, 'color': Color(0xFF2196F3)},
    {'id': 'agradecido', 'name': 'Agradecido', 'icon': Icons.favorite, 'color': Color(0xFF4CAF50)},
    {'id': 'motivado', 'name': 'Motivado', 'icon': Icons.trending_up, 'color': Color(0xFFFF5722)},
    {'id': 'preocupado', 'name': 'Preocupado', 'icon': Icons.warning, 'color': Color(0xFFFFC107)},
    {'id': 'feliz', 'name': 'Feliz', 'icon': Icons.sentiment_very_satisfied, 'color': Color(0xFFFFEB3B)},
    {'id': 'desanimado', 'name': 'Desanimado', 'icon': Icons.sentiment_dissatisfied, 'color': Color(0xFF9E9E9E)},
    {'id': 'enojado', 'name': 'Enojado', 'icon': Icons.mood_bad, 'color': Color(0xFFF44336)},
    {'id': 'tranquilo', 'name': 'Tranquilo', 'icon': Icons.wb_sunny, 'color': Color(0xFF87CEEB)},
  ];

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalization() async {
    if (_nameController.text.trim().isEmpty && _selectedEmotion == null) {
      _showMessage('Por favor, ingresa tu nombre o selecciona cómo te sientes', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      // Guardar nombre
      if (_nameController.text.trim().isNotEmpty) {
        await provider.setUserName(_nameController.text.trim());
      }
      
      // Guardar emoción
      if (_selectedEmotion != null) {
        await provider.setUserEmotion(_selectedEmotion!);
      }

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
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Personalización',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de nombre
                _buildSectionHeader(
                  'Tu Nombre',
                  Icons.person_outline,
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildNameInput(colorScheme),
                const SizedBox(height: 32),
                
                // Sección de emociones
                _buildSectionHeader(
                  '¿Cómo te sientes hoy?',
                  Icons.emoji_emotions_outlined,
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildEmotionGrid(isDark, colorScheme),
                const SizedBox(height: 32),
                
                // Botón de guardar
                _buildSaveButton(colorScheme),
                const SizedBox(height: 24),
                
                // Información adicional
                _buildInfoCard(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Ingresa tu nombre',
          hintStyle: GoogleFonts.inter(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.edit_outlined,
            color: colorScheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildEmotionGrid(bool isDark, ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _emotions.length,
      itemBuilder: (context, index) {
        final emotion = _emotions[index];
        final isSelected = _selectedEmotion == emotion['id'];
        
        return _buildEmotionCard(
          emotion: emotion,
          isSelected: isSelected,
          colorScheme: colorScheme,
          onTap: () {
            setState(() {
              _selectedEmotion = emotion['id'] as String;
            });
          },
        );
      },
    );
  }

  Widget _buildEmotionCard({
    required Map<String, dynamic> emotion,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    final emotionColor = emotion['color'] as Color;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? emotionColor.withOpacity(0.2)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? emotionColor
                  : colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: emotionColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emotion['icon'] as IconData,
                size: 32,
                color: isSelected ? emotionColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                emotion['name'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? emotionColor : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePersonalization,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Guardar Personalización',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Al personalizar tu experiencia, recibirás versículos y oraciones especialmente seleccionados para ti según cómo te sientas hoy.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

