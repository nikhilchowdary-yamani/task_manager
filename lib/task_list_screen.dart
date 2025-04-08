import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Toggle the completed state for a task in Firestore.
  void _toggleTaskCompletion(Task task, bool? newValue) {
    if (newValue == null) return;
    FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .update({'isCompleted': newValue});
  }

  // Delete a task from Firestore.
  void _deleteTask(Task task) {
    FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Task List with Firebase'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          // Convert each document into a Task object.
          List<Task> tasks = snapshot.data!.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          // Group tasks by day and then by time range.
          Map<String, Map<String, List<Task>>> groupedTasks = {};
          for (var task in tasks) {
            // Group by day.
            if (!groupedTasks.containsKey(task.day)) {
              groupedTasks[task.day] = {};
            }
            // Group by time range within the day.
            if (!groupedTasks[task.day]!.containsKey(task.timeRange)) {
              groupedTasks[task.day]![task.timeRange] = [];
            }
            groupedTasks[task.day]![task.timeRange]!.add(task);
          }

          // Build the list view. Each day is an ExpansionTile containing time slots.
          return ListView(
            children: groupedTasks.entries.map((dayEntry) {
              String day = dayEntry.key;
              Map<String, List<Task>> timeSlots = dayEntry.value;
              return ExpansionTile(
                title: Text(day),
                children: timeSlots.entries.map((timeSlotEntry) {
                  String timeRange = timeSlotEntry.key;
                  List<Task> tasksForTimeRange = timeSlotEntry.value;
                  return ExpansionTile(
                    title: Text(timeRange),
                    children: tasksForTimeRange.map((task) {
                      return ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? newValue) {
                            _toggleTaskCompletion(task, newValue);
                          },
                        ),
                        title: Text(
                          task.name,
                          style: task.isCompleted
                              ? TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        subtitle: Text('Priority: ${task.priority}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteTask(task);
                          },
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
      // Floating action button to add a new task.
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // Show a dialog to collect new task details.
          String? name;
          String? priority;
          String? day;
          String? timeRange;
          bool isCompleted = false;

          await showDialog(
            context: context,
            builder: (context) {
              final _formKey = GlobalKey<FormState>();
              return AlertDialog(
                title: Text('Add Task'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Task Name'),
                          onSaved: (value) => name = value,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter task name'
                              : null,
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Priority'),
                          onSaved: (value) => priority = value,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter priority'
                              : null,
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Day'),
                          onSaved: (value) => day = value,
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Enter day' : null,
                        ),
                        TextFormField(
                          decoration:
                              InputDecoration(labelText: 'Time Range (e.g., 9 am - 10 am)'),
                          onSaved: (value) => timeRange = value,
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Enter time range' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: Text('Add'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          );

          // Only add the task if all required details are provided.
          if (name != null && priority != null && day != null && timeRange != null) {
            FirebaseFirestore.instance.collection('tasks').add({
              'name': name,
              'priority': priority,
              'day': day,
              'timeRange': timeRange,
              'isCompleted': isCompleted,
            });
          }
        },
      ),
    );
  }
}
