import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'services/cache_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/widget_service.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/live_screen.dart';
import 'screens/prayers_screen.dart';
import 'screens/bible_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/emotion_selection_screen.dart';
import 'screens/prayer_for_you_screen.dart';
import 'screens/category_prayers_screen.dart';
import 'screens/traditional_prayers_religion_selection_screen.dart';
// import 'services/purchase_service.dart'; // Deshabilitado - opción de pago único removida
import 'services/content_validator.dart';
import 'services/daily_content_service.dart';
import 'theme/app_theme.dart';

int? _initialTabIndex;
String? _notificationPayload;

bool _checkOnboarding() {
  return StorageService().getOnboardingCompleted();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    // Inicializar servicios en orden
    await StorageService.init();
    await CacheService.init();
    await LanguageService.init();
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Verificar si la app se abrió desde una notificación
    final details = await notificationService.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _notificationPayload = details?.notificationResponse?.payload;
      // 'emotion' -> Pantalla de emociones, 'prayer' -> Tab 1 (Oración)
      if (_notificationPayload == 'emotion') {
        // Se manejará en el navegador observer
      } else if (_notificationPayload == 'prayer') {
        _initialTabIndex = 1;
      }
    }
    
    await AdsService().initialize();
    // await PurchaseService().initialize(); // Deshabilitado - opción de pago único removida
    await WidgetService.initialize();
    // Cargar contenido diario (versículos y oraciones) al iniciar la app
    await DailyContentService().loadContent();
    // Validar y normalizar contenidos (solo verificación/log; normalización se hace en memoria)
    await ContentValidator.validateAssets();
  } catch (e) {
    // Log del error pero continuar con la ejecución
    debugPrint('Error initializing services: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Versículo del Día',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: provider.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: _checkOnboarding() ? MainScreen(initialTabIndex: _initialTabIndex) : const OnboardingScreen(),
            routes: {
              '/home': (context) => MainScreen(initialTabIndex: _initialTabIndex),
              '/emotion-selection': (context) => const EmotionSelectionScreen(),
              '/prayer-for-you': (context) => const PrayerForYouScreen(),
              '/category-prayers': (context) => const CategoryPrayersScreen(),
              '/traditional-prayers-religion-selection': (context) => const TraditionalPrayersReligionSelectionScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            navigatorObservers: [
              _NotificationNavigatorObserver(),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Si hay un payload de notificación y la app está lista, navegar
    if (_notificationPayload == 'emotion') {
      // Navegar a pantalla de emociones después de que la app esté lista
      Future.delayed(const Duration(milliseconds: 500), () {
        if (route.navigator != null) {
          route.navigator!.pushNamed('/emotion-selection');
          _notificationPayload = null; // Limpiar payload
        }
      });
    }
  }
}

class MainScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const MainScreen({super.key, this.initialTabIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 2; // Default en "Hoy"
  int? _homeTabIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _homeTabIndex = widget.initialTabIndex;
    // Crear animaciones para cada pantalla
    _animationControllers = List.generate(
      _screens.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _fadeAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Curves.easeInOut,
              ),
            ))
        .toList();
    // Iniciar animación de la primera pantalla
    _animationControllers[_currentIndex].forward();
  }

  List<Widget> get _screens => [
    const ChatScreen(),
    const LiveScreen(),
    HomeScreen(initialTabIndex: _homeTabIndex), // Hoy
    const PrayersScreen(),
    const BibleScreen(),
  ];

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;

    // Verificar que los controllers estén inicializados
    if (!mounted) return;

    // Animar salida de la pantalla actual solo si está visible
    if (_animationControllers[_currentIndex].status == AnimationStatus.forward ||
        _animationControllers[_currentIndex].status == AnimationStatus.completed) {
      _animationControllers[_currentIndex].reverse();
    }

    setState(() {
      _currentIndex = index;
    });

    // Animar entrada de la nueva pantalla
    // Solo iniciar si no está ya en forward o completed
    if (_animationControllers[index].status == AnimationStatus.dismissed ||
        _animationControllers[index].status == AnimationStatus.reverse) {
      _animationControllers[index].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (index) => FadeTransition(
            opacity: _fadeAnimations[index],
            child: _screens[index],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: const Icon(Icons.radio_button_unchecked),
            selectedIcon: const Icon(Icons.radio_button_checked),
            label: 'En Vivo',
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_border),
            selectedIcon: const Icon(Icons.star),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Oraciones',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: 'Biblia',
          ),
        ],
      ),
    );
  }
}
