import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/mood_provider.dart';
import '../providers/route_provider.dart';
import '../widgets/custom_logo.dart';
import '../models/mood.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController _locationController = TextEditingController();
  final List<String> durations = const [
    'Half Day (4 hours)',
    'Full Day (8 hours)',
    'Weekend (2 days)',
    'Week (7 days)',
  ];
  
  final List<String> weatherPreferences = const [
    'Any Weather',
    'Sunny',
    'Cloudy',
    'Indoor Activities',
  ];

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CustomLogo(size: 40),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    moodProvider.selectedMood?.color ?? Colors.blue,
                    (moodProvider.selectedMood?.color ?? Colors.blue).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    moodProvider.selectedMood?.icon ?? Icons.emoji_emotions,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You're Feeling: ${moodProvider.selectedMood?.displayName ?? ''}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "We'll find the best experiences for you",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
            
            const SizedBox(height: 30),
            
            // Location
            const Text(
              'Location / City',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g., Paris, Tokyo, New York',
                prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => routeProvider.setLocation(value),
            ),
            
            const SizedBox(height: 20),
            
            // Date
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: routeProvider.selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  routeProvider.setSelectedDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd.MM.yyyy').format(routeProvider.selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Duration
            const Text(
              'Trip Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: routeProvider.duration,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: durations.map((String duration) {
                    return DropdownMenuItem<String>(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      routeProvider.setDuration(newValue);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Weather Preference
            const Text(
              'Weather Preference',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: weatherPreferences.map((pref) {
                bool isSelected = routeProvider.weatherPreference == pref;
                return ChoiceChip(
                  label: Text(pref),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      routeProvider.setWeatherPreference(pref);
                    }
                  },
                  selectedColor: moodProvider.selectedMood?.color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? moodProvider.selectedMood?.color : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Budget
            Text(
              'Budget: \$${routeProvider.budget.round()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('\$50', style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: routeProvider.budget,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    activeColor: moodProvider.selectedMood?.color,
                    onChanged: (value) {
                      routeProvider.setBudget(value);
                    },
                  ),
                ),
                const Text('\$5000', style: TextStyle(color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_locationController.text.isNotEmpty) {
                        routeProvider.generateRoutes(
                          moodProvider.selectedMood ?? Mood.adventurous
                        );
                        Navigator.pushNamed(context, '/routes');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a location'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moodProvider.selectedMood?.color ?? Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Generate Routes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}