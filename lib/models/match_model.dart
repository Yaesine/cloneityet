import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String userId;
  final String matchedUserId;
  final DateTime timestamp;

  Match({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    required this.timestamp,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      userId: json['userId'],
      matchedUserId: json['matchedUserId'],
      timestamp: (json['timestamp'] is Timestamp)
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
    );
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      userId: data['userId'] ?? '',
      matchedUserId: data['matchedUserId'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'matchedUserId': matchedUserId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'matchedUserId': matchedUserId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}