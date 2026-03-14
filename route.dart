import 'package:flutter/material.dart';
import 'mood.dart';

class LatLng {
  final double latitude;
  final double longitude;
  
  LatLng(this.latitude, this.longitude);
}

class TouristRoute {
  final String id;
  final String name;
  final String description;
  final Mood mood;
  final List<String> activities;
  final int durationHours;
  final double rating;
  final String imageUrl;
  final List<LatLng> waypoints;
  final String weatherPreference;
  final double estimatedCost;

  TouristRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.mood,
    required this.activities,
    required this.durationHours,
    required this.rating,
    required this.imageUrl,
    required this.waypoints,
    required this.weatherPreference,
    required this.estimatedCost,
  });
}