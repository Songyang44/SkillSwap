import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/profile_page.dart';
import 'pages/home_page.dart';
import 'pages/create_post_page.dart';
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
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page= ProfilePage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

return Scaffold(
  body: Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: page,
  ),
  bottomNavigationBar: BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 6.0,
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.home,
              color: selectedIndex == 0 ? Colors.blue : Colors.grey),
          onPressed: () {
            setState(() {
              selectedIndex = 0;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.person,
              color: selectedIndex == 1 ? Colors.blue : Colors.grey),
          onPressed: () {
            setState(() {
              selectedIndex = 1;
            });
          },
        ),
      ],
    ),
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen()),
      );
    },
    child: Icon(Icons.add),
    backgroundColor: Colors.blueAccent,
    tooltip: 'Add Post',
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
);

  }
}


