// lib/services/notification_service_implementation.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationServiceImplementation {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Process notifications created by app
  Future<void> _processNotifications() async {
    // Listen for pending notifications
    _firestore
        .collection('notifications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final notification = doc.data() as Map<String, dynamic>;

        // Send via Firebase Cloud Messaging
        try {
          final HttpsCallable callable = _functions.httpsCallable('sendNotification');
          await callable.call({
            'token': notification['fcmToken'],
            'title': notification['title'],
            'body': notification['body'],
            'data': notification['data'],
          });

          // Update status to sent
          await doc.reference.update({'status': 'sent'});
        } catch (e) {
          print('Error sending notification: $e');
          // Update status to failed
          await doc.reference.update({'status': 'failed'});
        }
      }
    });
  }
}