import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request location permission and get current position
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Check for location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Update user location in Firestore without using geocoding
  Future<void> updateUserLocation(String userId) async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        // Create GeoPoint for Firestore
        GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);

        // Just use a default location name since geocoding might have issues
        String location = 'Current Location';

        // Update user document
        await _firestore.collection('users').doc(userId).update({
          'location': location,
          'geoPoint': geoPoint,
        });

        print('Updated user location in Firestore: $location');
      }
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Calculate distance between two users
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }
}