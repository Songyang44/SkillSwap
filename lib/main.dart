import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/profile_page.dart';
import 'pages/home_page.dart';
import 'pages/create_post_page.dart';
import 'pages/chat_list_page.dart';
import 'app_state.dart';



void main() async {
   WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ulmcespqxuzsjkyhxxio.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsbWNlc3BxeHV6c2preWh4eGlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM0OTU1MzgsImV4cCI6MjA2OTA3MTUzOH0.dzPdGFM_mAce-r7jH3BUfXyFRz61_9zGXezvZMbc3Ns',        // 替换为你的 public anon key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Skill Swap',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
        
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    HomePage(),
    ChatListPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePostScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        tooltip: 'Add Post',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(icon: Icons.home, index: 0),
            const SizedBox(width: 40), // middle space for FAB
            _buildTabItem(icon: Icons.chat_bubble_outline, index: 1),
            _buildTabItem(icon: Icons.person, index: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required int index}) {
    final isSelected = selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      onPressed: () => _onItemTapped(index),
    );
  }
}


