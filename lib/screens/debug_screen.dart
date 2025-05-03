import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _statusMessage = 'Debug information will appear here';
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking Firebase connection...';
    });

    try {
      await _firestoreService.verifyFirestoreConnection();
      setState(() {
        _statusMessage = 'Firebase connection successful';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Firebase connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading all users...';
      _allUsers = [];
    });

    try {
      _allUsers = await _firestoreService.getAllUsers();
      setState(() {
        _statusMessage = 'Loaded ${_allUsers.length} users';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading users: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debug Status: $_statusMessage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkFirebaseConnection,
              child: const Text('Check Firebase Connection'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadAllUsers,
              child: const Text('Load All Users'),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Users:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ..._allUsers.map((user) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.imageUrls.isNotEmpty
                      ? NetworkImage(user.imageUrls[0])
                      : null,
                  child: user.imageUrls.isEmpty
                      ? Text(user.name[0])
                      : null,
                ),
                title: Text('${user.name}, ${user.age}'),
                subtitle: Text('ID: ${user.id}'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}