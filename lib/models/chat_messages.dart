import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });

  // Factory constructor to create a Message from a Firestore document
  factory Message.fromFirestore(Map<String, dynamic> firestoreData) {
    Timestamp? timestamp = firestoreData['timestamp'] as Timestamp?;

    return Message(
      text: firestoreData['text'] as String? ?? 'Unknown text',
      isUserMessage: firestoreData['isUserMessage'] as bool? ?? false,
      timestamp: timestamp?.toDate() ??
          DateTime.now(), // Use current time if timestamp is null
    );
  }
}
