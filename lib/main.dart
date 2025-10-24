import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/measurement_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/loading_spinner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(PRISMApp());
}

class PRISMApp extends StatelessWidget {
  const PRISMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'PRISM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: Color(0xFFF8FAFC),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Color(0xFF1E293B)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF3B82F6),
              side: BorderSide(color: Color(0xFF3B82F6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        home: AuthWrapper(),
        routes: {
          '/history': (context) => HistoryScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    
    print('AuthWrapper: isLoading=${authProvider.isLoading}, user=${authProvider.user?.uid}, profileComplete=${authProvider.profileComplete}');
    
    if (authProvider.isLoading) {
      print('AuthWrapper: Showing loading spinner');
      return LoadingSpinner();
    }
    
    if (authProvider.user == null) {
      print('AuthWrapper: No user, showing login screen');
      return LoginScreen();
    }
    
    // Check if user needs to complete profile
    if (!authProvider.profileComplete) {
      print('AuthWrapper: Profile incomplete, showing registration screen');
      return RegistrationScreen(
        isGoogleSignIn: authProvider.user!.providerData.any((provider) => provider.providerId == 'google.com'),
        googleEmail: authProvider.user!.email,
        googleName: authProvider.user!.displayName,
      );
    }
    
    print('AuthWrapper: Profile complete, showing main navigation');
    return MainNavigation();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    MeasurementScreen(),
    HistoryScreen(),
    InsightsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Measure', 1),
                _buildNavItem(Icons.history_outlined, Icons.history, 'History', 2),
                _buildNavItem(Icons.insights_outlined, Icons.insights, 'Insights', 3),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFDC2626).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? Color(0xFFDC2626) : Color(0xFF64748B),
              size: 20,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFFDC2626) : Color(0xFF64748B),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}