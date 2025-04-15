import 'package:flutter/material.dart';
import 'home.dart';
import 'firt.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diet App',
      theme: ThemeData(
        primaryColor: const Color(0xFFD5BDAE), // アクセントカラー
        scaffoldBackgroundColor: const Color(0xFFEBE9EA), // ベースカラー
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD5BDAE),
          titleTextStyle: TextStyle(
            color: Color(0xFF34251F), // テキストカラー
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF34251F),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF34251F)),
          bodyMedium: TextStyle(color: Color(0xFF34251F)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFEBE9EA),
          selectedItemColor: Color(0xFF34251F),
          unselectedItemColor: Color(0xFF34251F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD5BDAE),
            foregroundColor: const Color(0xFF34251F),
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    final dbHelper = DatabaseHelper();
    final hasUserData = await dbHelper.hasUserData();
    
    return hasUserData ? const HomeScreen() : const InitialSetupScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('エラーが発生しました: ${snapshot.error}'),
            ),
          );
        }
        return snapshot.data ?? const InitialSetupScreen();
      },
    );
  }
}
