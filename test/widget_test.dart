import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personalized_tourist_route/main.dart';
import 'package:personalized_tourist_route/providers/mood_provider.dart';
import 'package:personalized_tourist_route/screens/emotion_screen.dart';

void main() {
  testWidgets('Emotion screen shows categories', (WidgetTester tester) async {
    // Создаем провайдер для теста
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MoodProvider(),
        child: const MaterialApp(
          home: EmotionScreen(),
        ),
      ),
    );

    // Проверяем, что заголовок отображается
    expect(find.text('What kind of experience do you prefer?'), findsOneWidget);
    
    // Проверяем, что есть 7 категорий
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Romantic'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Cultural'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
  });
}