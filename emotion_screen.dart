import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mood.dart';
import '../providers/mood_provider.dart';
import '../widgets/custom_logo.dart';

class EmotionScreen extends StatelessWidget {
  const EmotionScreen({super.key});

  final List<Mood> moods = Mood.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomLogo(size: 50),
            const SizedBox(width: 10),
            Text(
              'Personalized Tourist Route',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
            const SizedBox(height: 10),
            const Text(
              'Select your current mood and we\'ll create\nthe perfect travel experience for you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  final mood = moods[index];
                  return _buildMoodCard(context, mood);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, Mood mood) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        bool isSelected = moodProvider.selectedMood == mood;
        
        return GestureDetector(
          onTap: () {
            moodProvider.selectMood(mood);
            Navigator.pushNamed(context, '/preferences');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [mood.color, mood.color.withOpacity(0.7)]
                    : [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? mood.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? mood.color.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mood.icon,
                  size: 50,
                  color: isSelected ? Colors.white : mood.color,
                ),
                const SizedBox(height: 10),
                Text(
                  mood.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 10,
                        color: mood.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().scale(duration: 300.ms);
      },
    );
  }
}