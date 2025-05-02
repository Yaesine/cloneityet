import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class MessageProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _messagesSubscription;
  String? _currentChatUserId;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load messages for a specific match
  Future<void> loadMessages(String matchedUserId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentChatUserId = matchedUserId;
    notifyListeners();

    try {
      _messages = await _firestoreService.getMessages(matchedUserId);

      // Mark all messages from the matched user as read
      await _firestoreService.markMessagesAsRead(matchedUserId);

      // Start listening for new messages
      _startMessagesStream(matchedUserId);
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      bool success = await _firestoreService.sendMessage(receiverId, text);

      if (success) {
        // Message will be added through the stream listener
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Listen to messages stream
  void _startMessagesStream(String matchedUserId) {
    // Cancel previous subscription if it exists
    _messagesSubscription?.cancel();

    _messagesSubscription = _firestoreService.messagesStream(matchedUserId)
        .listen((updatedMessages) {
      _messages = updatedMessages;
      // Mark any new messages as read
      _firestoreService.markMessagesAsRead(matchedUserId);
      notifyListeners();
    });
  }

  // Stop listening to messages stream
  void stopMessagesStream() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _currentChatUserId = null;
  }

  @override
  void dispose() {
    stopMessagesStream();
    super.dispose();
  }
}