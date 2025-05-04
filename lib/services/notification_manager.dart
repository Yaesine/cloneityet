// lib/services/notification_manager.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _flutterLocalNotifications =
  FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Initialize local notifications for version 9.6.1
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotifications.initialize(
      initializationSettings,
      onSelectNotification: _onSelectNotification,
    );
  }

  // Handle notification tap
  Future<void> _onSelectNotification(String? payload) async {
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length == 2) {
        final type = parts[0];
        final id = parts[1];

        navigatorKey.currentState?.pushNamed(getRouteForType(type), arguments: id);
      }
    }
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
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: '${message.data['type']}|${message.data['id']}',
      );
    }
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

  // Show local notification for version 9.6.1
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'tinder_clone_channel',
      'Tinder Clone Notifications',
      channelDescription: 'Channel for Tinder Clone notifications',  // ✅ Use named parameter
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      showWhen: true,
    );

    const IOSNotificationDetails iOSPlatformChannelSpecifics =
    IOSNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
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