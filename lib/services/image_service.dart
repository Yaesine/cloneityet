import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Add this line
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      // Check file size first (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image is too large. Maximum file size is 5MB.');
      }

      String fileName = '${userId}_${_uuid.v4()}.jpg';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      // Create upload task with metadata
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file with progress monitoring
      UploadTask uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for completion
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update the user's profile to include this new image
      await _firestore.collection('users').doc(userId).update({
        'imageUrls': FieldValue.arrayUnion([downloadUrl]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}