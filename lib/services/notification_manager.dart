// lib/services/notification_manager.dart - Complete Firebase only implementation
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/navigation.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> initialize() async {
    await _requestPermission();
    await _configureFirebaseMessaging();
    await _saveTokenToFirestore();
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showInAppNotification(message);
    }
  }

  // Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    final type = message.data['type'];
    final id = message.data['id'];

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      getRouteForType(type),
          (route) => false,
      arguments: id,
    );
  }

  String getRouteForType(String type) {
    switch (type) {
      case 'match':
        return '/matches';
      case 'message':
        return '/chat';
      case 'profile_view':
        return '/profile';
      default:
        return '/main';
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore() async {
    String? token = await _firebaseMessaging.getToken();
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Send match notification
  Future<void> sendMatchNotification(String recipientId, String senderName) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'type': 'match',
          'title': '🎉 New Match!',
          'body': 'You and $senderName liked each other!',
          'recipientId': recipientId,
          'fcmToken': fcmToken,
          'data': {
            'type': 'match',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  // Send profile view notification
  Future<void> sendProfileViewNotification(String profileOwnerId, String viewerName) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(profileOwnerId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'type': 'profile_view',
          'title': '👀 Profile View',
          'body': '$viewerName viewed your profile',
          'recipientId': profileOwnerId,
          'fcmToken': fcmToken,
          'data': {
            'type': 'profile_view',
            'viewerId': FirebaseAuth.instance.currentUser?.uid,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      print('Error sending profile view notification: $e');
    }
  }

  // Send message notification
  Future<void> sendMessageNotification(
      String recipientId,
      String senderName,
      String messageText
      ) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'type': 'message',
          'title': '💌 New Message',
          'body': '$senderName: ${messageText.length > 50 ? messageText.substring(0, 50) + '...' : messageText}',
          'recipientId': recipientId,
          'fcmToken': fcmToken,
          'data': {
            'type': 'message',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'messageText': messageText,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
}