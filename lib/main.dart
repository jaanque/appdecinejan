import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('ERROR: Supabase credentials are missing in .env');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Movie Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
          primary: Colors.black,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade600,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent, // Minimalist: No heavy indicator blob, just icon color change
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
              selectedIcon: const Icon(Icons.home_filled, color: Colors.black),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: Colors.grey.shade600),
              selectedIcon: const Icon(Icons.explore, color: Colors.black),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey.shade600),
              selectedIcon: const Icon(Icons.person, color: Colors.black),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
