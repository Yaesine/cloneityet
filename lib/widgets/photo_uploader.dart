// PhotoUploader widget that can be used in the PhotoManagerScreen
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/image_service.dart';

class PhotoUploader extends StatefulWidget {
  final Function(File) onPhotoSelected;

  const PhotoUploader({
    Key? key,
    required this.onPhotoSelected,
  }) : super(key: key);

  @override
  _PhotoUploaderState createState() => _PhotoUploaderState();
}

class _PhotoUploaderState extends State<PhotoUploader> {
  final ImageService _imageService = ImageService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      File? pickedImage;

      if (source == ImageSource.gallery) {
        pickedImage = await _imageService.pickImageFromGallery();
      } else {
        pickedImage = await _imageService.pickImageFromCamera();
      }

      if (pickedImage != null) {
        widget.onPhotoSelected(pickedImage);
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from Gallery'),
          onTap: () {
            Navigator.of(context).pop();
            _pickImage(ImageSource.gallery);
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Take a Photo'),
          onTap: () {
            Navigator.of(context).pop();
            _pickImage(ImageSource.camera);
          },
        ),
      ],
    );
  }
}

// Updated PhotoManagerScreen with actual photo upload functionality
class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({Key? key}) : super(key: key);

  @override
  _PhotoManagerScreenState createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  late List<String> photos;
  bool _isLoading = false;
  final ImageService _imageService = ImageService();
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AppAuthProvider>(context, listen: false).currentUserId;
    _loadUserPhotos();
  }

  Future<void> _loadUserPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();

      if (userProvider.currentUser != null) {
        setState(() {
          photos = List.from(userProvider.currentUser!.imageUrls);
        });
      } else {
        setState(() {
          photos = [];
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPhoto(File photoFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uploadedUrl = await _imageService.uploadImage(photoFile, _userId);

      if (uploadedUrl != null) {
        setState(() {
          photos.add(uploadedUrl);
        });

        // Update user profile with new photo
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user != null) {
          final updatedUser = user.copyWith(
            imageUrls: photos,
          );

          await userProvider.updateUserProfile(updatedUser);
        }
      }
    } catch (e) {
      print('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photoUrl = photos[index];

      // Delete from Firebase Storage
      await _imageService.deleteImage(photoUrl);

      // Update local photos list
      setState(() {
        photos.removeAt(index);
      });

      // Update user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          imageUrls: photos,
        );

        await userProvider.updateUserProfile(updatedUser);
      }
    } catch (e) {
      print('Error deleting photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => PhotoUploader(
        onPhotoSelected: _uploadPhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Photos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add up to 9 photos to show yourself off',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9, // Maximum 9 photos
              itemBuilder: (context, index) {
                // If we have a photo at this index
                if (index < photos.length) {
                  return buildPhotoItem(photos[index], index);
                } else {
                  // Empty slot for adding new photos
                  return buildAddPhotoItem();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotoItem(String photoUrl, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deletePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildAddPhotoItem() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}