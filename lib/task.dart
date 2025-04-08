import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String name;
  bool isCompleted;
  String priority;
  String day;
  String timeRange;
  DateTime dueDate;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.priority,
    required this.day,
    required this.timeRange,
    required this.dueDate,
  });

  // Create a Task object from Firestore document data.
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    Timestamp timestamp = data['dueDate'] as Timestamp? ?? Timestamp.now();
    return Task(
      id: documentId,
      name: data['name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Low',
      day: data['day'] ?? 'Monday',
      timeRange: data['timeRange'] ?? '',
      dueDate: timestamp.toDate(),
    );
  }

  // Convert a Task object into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'priority': priority,
      'day': day,
      'timeRange': timeRange,
      'dueDate': dueDate,
    };
  }
}
