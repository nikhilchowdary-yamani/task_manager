class Task {
  String id;
  String name;
  bool isCompleted;
  String priority;
  String day;
  String timeRange;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.priority,
    required this.day,
    required this.timeRange,
  });

  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      name: data['name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Low',
      day: data['day'] ?? 'Monday',
      timeRange: data['timeRange'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'priority': priority,
      'day': day,
      'timeRange': timeRange,
    };
  }
}
