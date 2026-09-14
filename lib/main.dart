import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/storage_service.dart';
import 'services/cache_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_background_handler.dart';
import 'services/push_messaging_service.dart';
import 'services/ads_service.dart';
import 'services/deep_link_service.dart';
import 'services/system_ui_service.dart';
import 'services/widget_service.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/community_screen.dart';
import 'screens/prayers_screen.dart';
import 'screens/bible_screen.dart';
import 'screens/profile_hub_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/setup_username_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/spiritual_stats_screen.dart';
import 'screens/achievement_detail_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/report_content_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/sessions_devices_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spiritual_paths_screen.dart';
import 'screens/comments_screen.dart';
import 'screens/my_posts_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/emotion_selection_screen.dart';
import 'screens/prayer_for_you_screen.dart';
import 'screens/category_prayers_screen.dart';
import 'screens/traditional_prayers_religion_selection_screen.dart';
// import 'services/purchase_service.dart'; // Deshabilitado - opción de pago único removida
import 'services/content_validator.dart';
import 'services/daily_content_service.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_auth_screen.dart';
import 'bible/ui/bible_books_screen.dart';

int? _initialTabIndex;
String? _notificationPayload;
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

bool _checkOnboarding() {
  return StorageService().getOnboardingCompleted();
}

bool _hasFaithSelection() {
  return StorageService().getValidatedTraditionalPrayersReligion().isNotEmpty;
}

Widget _buildHomeEntry() {
  if (!_hasFaithSelection()) {
    return const TraditionalPrayersReligionSelectionScreen(
      requireSelection: true,
      nextRouteOnSelect: '/home',
    );
  }
  return MainScreen(initialTabIndex: _initialTabIndex);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUiService.applyFromPlatformBrightness();
  await MobileAds.instance.initialize();

  try {
    await Firebase.initializeApp();
    // App Check reduce abuso de APIs Firebase y evita warnings de token ausente.
    // En debug usa proveedor de desarrollo; en release usa providers reales.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Inicializar servicios en orden
    await StorageService.init();
    await StorageService()
        .syncTraditionalPrayersReligionFromCloudForCurrentUser();
    await CacheService.init();
    await LanguageService.init();
    final notificationService = NotificationService();
    await notificationService.initialize();
    await PushMessagingService().initialize();

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

    if (kDebugMode) {
      debugPrint(
        '[Verbum/Notifications] cold start: launchFromNotification=${details?.didNotificationLaunchApp} '
        'payload=$_notificationPayload',
      );
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
  DeepLinkService.instance.initialize(_navigatorKey);
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
      child: Consumer2<AppProvider, AuthProvider>(
        builder: (context, provider, auth, child) {
          final bool onboardingCompleted = _checkOnboarding();
          final bool traditionSelected = _hasFaithSelection();

          Widget startScreen;
          if (!traditionSelected) {
            startScreen = TraditionalPrayersReligionSelectionScreen(
              requireSelection: true,
              nextRouteOnSelect: auth.isSignedIn ? '/home' : '/welcome',
            );
          } else if (auth.isSignedIn) {
            startScreen = onboardingCompleted
                ? _buildHomeEntry()
                : const OnboardingScreen();
          } else {
            // Invitado: si ya completó onboarding, dejar pasar; si no, mostrar welcome.
            startScreen = onboardingCompleted
                ? _buildHomeEntry()
                : const WelcomeAuthScreen();
          }

          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Verbum',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: provider.darkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              SystemUiService.applyFromContext(context);
              return child ?? const SizedBox.shrink();
            },
            home: startScreen,
            routes: {
              '/home': (context) => _buildHomeEntry(),
              '/emotion-selection': (context) => const EmotionSelectionScreen(),
              '/prayer-for-you': (context) => const PrayerForYouScreen(),
              '/category-prayers': (context) => const CategoryPrayersScreen(),
              '/traditional-prayers-religion-selection': (context) =>
                  const TraditionalPrayersReligionSelectionScreen(),
              '/profile': (context) => ProfileHubScreen(),
              '/my-profile': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                int? initialTab;
                if (args is int) {
                  initialTab = args;
                } else if (args is Map && args['initialTabIndex'] is int) {
                  initialTab = args['initialTabIndex'] as int;
                }
                return MySocialProfileScreen(initialTabIndex: initialTab);
              },
              '/edit-profile': (context) => const EditProfileScreen(),
              '/setup-username': (context) => const SetupUsernameScreen(),
              '/streak': (context) => const StreakScreen(),
              '/spiritual-stats': (context) => const SpiritualStatsScreen(),
              '/achievement-detail': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                return AchievementDetailScreen(
                  achievement: args['achievement'],
                  stats: args['stats'],
                );
              },
              '/plan': (context) => const PlanScreen(),
              '/account-settings': (context) => const AccountSettingsScreen(),
              '/blocked-users': (context) => const BlockedUsersScreen(),
              '/report-content': (context) => const ReportContentScreen(),
              '/privacy-policy': (context) => const PrivacyPolicyScreen(),
              '/terms': (context) => const TermsScreen(),
              '/sessions-devices': (context) => const SessionsDevicesScreen(),
              '/delete-account': (context) => const DeleteAccountScreen(),
              '/help-support': (context) => const HelpSupportScreen(),
              '/faq': (context) => const FaqScreen(),
              '/report-problem': (context) => const ReportProblemScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/spiritual-paths': (context) => const SpiritualPathsScreen(),
              '/comments': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                final postId = args?['postId'] as String? ?? '';
                return CommentsScreen(postId: postId);
              },
              '/my-posts': (context) => const MyPostsScreen(),
              '/welcome': (context) => const WelcomeAuthScreen(),
              '/bible-offline': (context) => const BibleBooksScreen(),
            },
            navigatorObservers: [
              _NotificationNavigatorObserver(),
              FirebaseAnalyticsObserver(
                analytics: FirebaseAnalytics.instance,
              ),
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
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
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
    // Iniciar animación de la primera pantalla
    _animationControllers[_currentIndex].forward();
  }

  List<Widget> get _screens => [
    const ChatScreen(),
    const CommunityScreen(),
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
    if (_animationControllers[_currentIndex].status ==
            AnimationStatus.forward ||
        _animationControllers[_currentIndex].status ==
            AnimationStatus.completed) {
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 3, 12, 9),
        child: Container(
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF262130).withValues(alpha: .97)
                : const Color(0xFFFFFCF7).withValues(alpha: .98),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: scheme.outline.withValues(alpha: .14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .28 : .11),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 63,
            backgroundColor: Colors.transparent,
            indicatorColor: scheme.primary.withValues(alpha: dark ? .24 : .11),
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            animationDuration: const Duration(milliseconds: 280),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_2_outlined),
                selectedIcon: Icon(Icons.groups_2_rounded),
                label: 'Comunidad',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Hoy',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Oraciones',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Biblia',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
