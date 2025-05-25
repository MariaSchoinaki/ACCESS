import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String? photoUrl;
  final String? text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    this.photoUrl,
    this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      userId: map['userId'] ?? '',
      photoUrl: map['photoUrl'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'photoUrl': photoUrl,
      'text': text,
      'timestamp':DateTime.now(),
    };
  }
}
