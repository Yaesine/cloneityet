import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request location permission and get current position
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }

  // Get address from coordinates (simpler version)
  Future<String> getAddressFromPosition(Position position) async {
    try {
      // Just return the coordinates as a string for now
      return '${position.latitude}, ${position.longitude}';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Update user location in Firestore
  Future<void> updateUserLocation(String userId) async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        String address = await getAddressFromPosition(position);

        // Create GeoPoint for Firestore
        GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);

        // Update user document
        await _firestore.collection('users').doc(userId).update({
          'location': address,
          'geoPoint': geoPoint,
        });
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