import 'package:flutter/material.dart';
enum Mood {
  happy,
  romantic,
  adventurous,
  thrilling,
  curious,
  relaxed,
}

extension MoodExtension on Mood {
  String get displayName {
    switch (this) {
      case Mood.happy:
        return 'Happy';
      case Mood.romantic:
        return 'Romantic';
      case Mood.adventurous:
        return 'Adventurous';
      case Mood.thrilling:
        return 'Thrilling & Exciting';
      case Mood.curious:
        return 'Curious';
      case Mood.relaxed:
        return 'Relaxed';
    }
  }

  String get description {
    switch (this) {
      case Mood.happy:
        return 'Discover joyful places that will make you smile';
      case Mood.romantic:
        return 'Perfect spots for you and your loved one';
      case Mood.adventurous:
        return 'Find your next adventure off the beaten path';
      case Mood.thrilling:
        return 'Heart-pumping experiences for thrill seekers';
      case Mood.curious:
        return 'Explore fascinating places that spark wonder';
      case Mood.relaxed:
        return 'Peaceful destinations to unwind and recharge';
    }
  }

  IconData get icon {
    switch (this) {
      case Mood.happy:
        return Icons.emoji_emotions;
      case Mood.romantic:
        return Icons.favorite;
      case Mood.adventurous:
        return Icons.terrain;
      case Mood.thrilling:
        return Icons.flash_on;
      case Mood.curious:
        return Icons.explore;
      case Mood.relaxed:
        return Icons.self_improvement;
    }
  }

  Color get color {
    switch (this) {
      case Mood.happy:
        return Colors.amber;
      case Mood.romantic:
        return Colors.pink;
      case Mood.adventurous:
        return Colors.green;
      case Mood.thrilling:
        return Colors.orange;
      case Mood.curious:
        return Colors.purple;
      case Mood.relaxed:
        return Colors.blue;
    }
  }
}