import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/mood_provider.dart';
import 'providers/route_provider.dart';
import 'screens/emotion_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/routes_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: MaterialApp(
        title: 'Personalized Tourist Route',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const EmotionScreen(),
          '/preferences': (context) => const PreferencesScreen(),
          '/routes': (context) => const RoutesScreen(),
        },
      ),
    );
  }
}