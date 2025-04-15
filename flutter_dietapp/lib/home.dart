// アプリのメイン画面。記録・カレンダー・グラフ・オプションの各画面をタブで切り替えます。

import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'calendar_screen.dart';
import 'graph_screen.dart';
import 'options_screen.dart';
import 'firt.dart';
import 'database_helper.dart';

// ホーム画面（タブ切り替え）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 各タブの画面
  final List<Widget> _pages = [
    const InputScreen(),
    const CalendarScreen(),
    const GraphScreen(),
    const OptionsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // ユーザーデータがなければ初期設定画面へ
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final dbHelper = DatabaseHelper();
    final hasData = await dbHelper.hasUserData();
    if (!hasData && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InitialSetupScreen()),
      );
    }
  }

  // タブ切り替え
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ボトムナビゲーションバーで画面切り替え
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFE4C1B5),
        selectedItemColor: const Color(0xFF544C40),
        unselectedItemColor: const Color(0xFF544C40),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'グラフ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'オプション',
          ),
        ],
      ),
    );
  }
}
