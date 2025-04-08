import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'calendar_screen.dart';
import 'graph_screen.dart';
import 'options_screen.dart';
import 'firt.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const InputScreen(),
    const CalendarScreen(),
    const GraphScreen(),
    const OptionsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // 背景色を白に設定
        selectedItemColor: Colors.black, // 選択されたアイテムの文字色を黒に設定
        unselectedItemColor: Colors.black54, // 未選択アイテムの文字色を薄い黒に設定
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
