import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomLogo extends StatelessWidget {
  final double size;
  
  const CustomLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4285F4),
            Color(0xFF9C27B0),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              color: Colors.white,
              size: size * 0.4,
            ),
            Text(
              'TRIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms).then().shake(duration: 300.ms);
  }
}