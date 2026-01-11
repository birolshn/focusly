import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/notification_service.dart';
import 'services/pomodoro_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle (bulunamazsa devam et)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    ('Warning: .env file not found, using defaults');
  }

  // Firebase'i başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }
  await NotifyService.init();
  await PomodoroService().init();
  runApp(const FocuslyApp());
}

class FocuslyApp extends StatefulWidget {
  const FocuslyApp({super.key});

  @override
  State<FocuslyApp> createState() => _FocuslyAppState();
}

class _FocuslyAppState extends State<FocuslyApp> {
  SharedPreferences? _prefs;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    final languageCode = _prefs?.getString('language_code') ?? 'en';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      // _prefs null ise yeniden yükle
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString('language_code', languageCode);
      if (mounted) {
        setState(() {
          _locale = Locale(languageCode);
        });
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      // Yükleme tamamlanana kadar loading göster
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Focusly',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is logged in
          if (snapshot.hasData) {
            return HomePage(onLanguageChanged: _changeLanguage);
          }

          // User is not logged in
          return const LoginPage();
        },
      ),
    );
  }
}
