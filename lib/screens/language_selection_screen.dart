import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../main.dart';

/// Pantalla de selección de idioma inicial
/// Se muestra solo la primera vez que se abre la app
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Guardar idioma seleccionado
    await LanguageService.setLanguage(languageCode);

    // Esperar un momento para mostrar la selección
    await Future.delayed(const Duration(milliseconds: 300));

    // Navegar a la pantalla principal
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Título
                      Text(
                        'Verbum',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selecciona tu idioma',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Opciones de idioma
                      _buildLanguageOption(
                        context: context,
                        languageCode: 'es',
                        languageName: 'Español',
                        flag: '🇪🇸',
                        onTap: () => _selectLanguage('es'),
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOption(
                        context: context,
                        languageCode: 'en',
                        languageName: 'English',
                        flag: '🇺🇸',
                        onTap: () => _selectLanguage('en'),
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOption(
                        context: context,
                        languageCode: 'pt',
                        languageName: 'Português',
                        flag: '🇧🇷',
                        onTap: () => _selectLanguage('pt'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String languageCode,
    required String languageName,
    required String flag,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedLanguage == languageCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageName,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

