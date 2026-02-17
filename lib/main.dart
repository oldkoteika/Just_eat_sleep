import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/auth/auth_storage.dart';
import 'core/auth/user_storage.dart';
import 'core/auth/supabase_auth_service.dart';
import 'shared/widgets/bottom_navigation.dart';
import 'features/home/home_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/auth/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // assets/.env не загружен (500 на Web, нет файла) — конфиг только из --dart-define
  }
  await Hive.initFlutter();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
  AppTheme.setThemeMode(ThemeMode.system);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Жми Ешь Спи',
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      home: const SplashScreen(),
    );
  }
}

/// Экран приветствия с логотипом.
/// Фон зависит от текущей темы приложения.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    // Небольшая анимационная задержка под логотип.
    await Future.delayed(const Duration(seconds: 1));

    final profileCompleted = await AuthStorage.isProfileCompleted();
    final hasPin = await AuthStorage.hasPin();

    if (!mounted) return;

    if (!profileCompleted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => const ProfileSetupScreen(),
        ),
      );
    } else if (!hasPin) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => const PinSetupScreen(),
        ),
      );
    } else {
      // Профиль и PIN есть — обеспечиваем сессию Supabase (signUp при первом запуске, signIn при следующих)
      final user = await UserStorage.getCurrentUser();
      if (user != null) {
        try {
          await SupabaseAuthService.ensureSession(user.id, user.displayName);
        } catch (e, st) {
          // Сеть недоступна или Supabase ошибка — не блокируем вход в приложение
          debugPrint('Supabase ensureSession error: $e');
          debugPrint('$st');
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => const LockScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Используем фоновый цвет из текущей темы
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: screenWidth,
          child: Image.asset(
            'logo.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppScreen _currentScreen = AppScreen.home;

  void _onScreenChanged(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _navigateToHome() {
    setState(() {
      _currentScreen = AppScreen.home;
    });
  }

  void _navigateToCalendar() {
    setState(() {
      _currentScreen = AppScreen.calendar;
    });
  }

  void _navigateToFriends() {
    setState(() {
      _currentScreen = AppScreen.friends;
    });
  }

  Widget _getCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          onNavigateToCalendar: _navigateToCalendar,
          onNavigateToFriends: _navigateToFriends,
        );
      case AppScreen.calendar:
        return CalendarScreen(
          onNavigateHome: _navigateToHome,
        );
      case AppScreen.friends:
        return FriendsScreen(
          onNavigateHome: _navigateToHome,
        );
      case AppScreen.profile:
        return ProfileScreen(
          onNavigateHome: _navigateToHome,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Контент на весь экран — прокручивается под верхнее и нижнее меню
          Positioned.fill(
            child: _getCurrentScreen(),
          ),
          // Нижняя навигация поверх контента (прозрачный фон)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavigation(
              currentScreen: _currentScreen,
              onScreenChanged: _onScreenChanged,
            ),
          ),
        ],
      ),
    );
  }
}
