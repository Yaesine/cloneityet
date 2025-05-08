// lib/services/notification_manager.dart - Enhanced version
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/navigation.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add FlutterLocalNotificationsPlugin for in-app notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
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

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Local notification clicked: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteNotificationTap(message);
    });

    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteNotificationTap(initialMessage);
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        message.data.toString(),
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(String title, String body, String payload) async {
    const androidDetails = AndroidNotificationDetails(
      'still_app_channel',
      'Still App Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (message.data['type'] != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleRemoteNotificationTap(message);
              },
              child: const Text('View', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  // Handle notification tap from remote message
  void _handleRemoteNotificationTap(RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    final type = message.data['type'];
    final id = message.data['id'];

    _navigateBasedOnType(type, id);
  }

  // Handle notification tap from local notification
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      // Parse the payload to extract type and id
      final Map<String, dynamic> data = Map<String, dynamic>.from(
          payload.replaceAll('{', '').replaceAll('}', '')
              .split(', ')
              .map((e) => MapEntry(e.split(': ')[0], e.split(': ')[1]))
              .toMap()
      );

      final type = data['type'];
      final id = data['id'];

      _navigateBasedOnType(type, id);
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  // Navigate based on notification type
  void _navigateBasedOnType(String? type, String? id) {
    if (type == null) return;

    switch (type) {
      case 'match':
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/matches',
              (route) => route.settings.name == '/main',
        );
        break;
      case 'message':
        if (id != null) {
          // Get user data before navigating
          _getUserDataAndNavigate(id);
        }
        break;
      case 'super_like':
      case 'profile_view':
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/likes',
              (route) => route.settings.name == '/main',
        );
        break;
      default:
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/main',
              (route) => false,
        );
    }
  }

  // Get user data and navigate to chat
  Future<void> _getUserDataAndNavigate(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Create a simplified user object for navigation
          final user = {
            'id': userId,
            'name': userData['name'] ?? 'User',
            'imageUrls': userData['imageUrls'] ?? [],
          };

          // Navigate to chat screen with user data
          navigatorKey.currentState?.pushNamed(
            '/chat',
            arguments: user,
          );
        }
      }
    } catch (e) {
      print('Error getting user data for navigation: $e');
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

      print('FCM Token saved to Firestore: $token');
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

        print('Match notification sent to $recipientId');
      }
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  // Send SuperLike notification
  Future<void> sendSuperLikeNotification(String recipientId, String senderName) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'type': 'super_like',
          'title': '⭐ Super Like!',
          'body': '$senderName super liked your profile!',
          'recipientId': recipientId,
          'fcmToken': fcmToken,
          'data': {
            'type': 'super_like',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        print('SuperLike notification sent to $recipientId');
      }
    } catch (e) {
      print('Error sending SuperLike notification: $e');
    }
  }

  // Send SuperLike match notification
  Future<void> sendSuperLikeMatchNotification(String recipientId, String senderName) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'type': 'match',
          'title': '✨ SUPER Match!',
          'body': '$senderName super liked you and it\'s a match!',
          'recipientId': recipientId,
          'fcmToken': fcmToken,
          'data': {
            'type': 'match',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        print('SuperLike match notification sent to $recipientId');
      }
    } catch (e) {
      print('Error sending SuperLike match notification: $e');
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

        print('Profile view notification sent to $profileOwnerId');
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

        print('Message notification sent to $recipientId');
      }
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
}