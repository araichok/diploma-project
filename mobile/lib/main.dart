import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/map_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/saved_routes_provider.dart';
import 'screens/login_screen.dart';
import 'screens/user_main_screen.dart';
import 'screens/admin_main_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => SavedRoutesProvider()),
      ],
      child: MaterialApp(
        title: 'Personalized Tourist Route',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/': (context) => Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoading) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (auth.currentUser == null) {
                return const LoginScreen();
              }
              if (auth.isAdmin) {
                return const AdminMainScreen();
              } else {
                return const UserMainScreen();
              }
            },
          ),
        },
      ),
    );
  }
}
