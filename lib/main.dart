import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'login.dart';
import 'homepage.dart';
import 'theme_settings.dart';
import 'splash_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

// Inside main.dart
class _MyAppState extends State<MyApp> {
  bool _isDark = false;
  MaterialColor _seed = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

// Inside main.dart
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dark  = prefs.getBool('isDark') ?? false;
    final name  = prefs.getString('themeColor') ?? 'Indigo';
    const map = {
      'Indigo': Colors.indigo,
      'Green' : Colors.green,
      'Teal'  : Colors.teal,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
    };
    setState(() {
      _isDark = dark;
      _seed   = map[name] ?? Colors.indigo;
    });
  }
  
// Inside main.dart
  Future<Widget> _firstPage() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs  = await SharedPreferences.getInstance();
    final logged = prefs.getBool('loggedIn') ?? false;
    return logged ? const HomePage() : const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _seed,
        brightness: _isDark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home' : (_) => const HomePage(),
        '/theme': (_) => ThemeSettingsPage(
              onThemeChanged: (d, c) => setState(() {
                _isDark = d;
                _seed   = c;
              }),
            ),
      },
      home: FutureBuilder(
        future: _firstPage(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return snap.data!;
        },
      ),
    );
  }
}