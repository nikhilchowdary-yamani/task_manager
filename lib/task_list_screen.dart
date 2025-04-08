import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task.dart';

enum SortOption { priorityHighLow, priorityLowHigh, dueDateEarliest, completion }

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Sorting and filtering state variables.
  SortOption _sortOption = SortOption.dueDateEarliest;
  String _filterPriority = "All";
  String _filterCompletion = "All";

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

  // Helper: convert priority string to a numeric value (for sorting).
  int _priorityToValue(String priority) {
    switch (priority) {
      case "High":
        return 3;
      case "Medium":
        return 2;
      case "Low":
        return 1;
      default:
        return 0;
    }
  }

  // Helper: format DateTime as a string.
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Helper: get color based on priority.
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List with Sorting & Filtering'),
      ),
      body: Column(
        children: [
          // Sorting & Filtering Controls.
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Sorting Dropdown
                Expanded(
                  child: DropdownButton<SortOption>(
                    value: _sortOption,
                    isExpanded: true,
                    onChanged: (SortOption? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOption = newValue;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: SortOption.priorityHighLow,
                        child: Text("Priority High-Low"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.priorityLowHigh,
                        child: Text("Priority Low-High"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.dueDateEarliest,
                        child: Text("Due Date (Earliest)"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.completion,
                        child: Text("Completion"),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Filter by Priority Dropdown.
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterPriority,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _filterPriority = newValue ?? "All";
                      });
                    },
                    items: ["All", "High", "Medium", "Low"].map((filterOption) {
                      return DropdownMenuItem<String>(
                        value: filterOption,
                        child: Text("Priority: $filterOption"),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 8),
                // Filter by Completion Dropdown.
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterCompletion,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _filterCompletion = newValue ?? "All";
                      });
                    },
                    items: ["All", "Completed", "Incomplete"].map((filterOption) {
                      return DropdownMenuItem<String>(
                        value: filterOption,
                        child: Text("Status: $filterOption"),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Task List (StreamBuilder).
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                // Convert Firestore documents into Task objects.
                List<Task> tasks = snapshot.data!.docs.map((doc) {
                  return Task.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                // Apply filtering.
                if (_filterPriority != "All") {
                  tasks = tasks
                      .where((task) => task.priority == _filterPriority)
                      .toList();
                }
                if (_filterCompletion != "All") {
                  if (_filterCompletion == "Completed")
                    tasks = tasks.where((task) => task.isCompleted).toList();
                  else if (_filterCompletion == "Incomplete")
                    tasks = tasks.where((task) => !task.isCompleted).toList();
                }

                // Apply sorting.
                switch (_sortOption) {
                  case SortOption.priorityHighLow:
                    tasks.sort((a, b) =>
                        _priorityToValue(b.priority)
                            .compareTo(_priorityToValue(a.priority)));
                    break;
                  case SortOption.priorityLowHigh:
                    tasks.sort((a, b) =>
                        _priorityToValue(a.priority)
                            .compareTo(_priorityToValue(b.priority)));
                    break;
                  case SortOption.dueDateEarliest:
                    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                    break;
                  case SortOption.completion:
                    tasks.sort((a, b) {
                      if (a.isCompleted == b.isCompleted) return 0;
                      return a.isCompleted ? 1 : -1;
                    });
                    break;
                }

                // Build flat list view with visual priority indicator.
                return ListView(
                  children: tasks.map((task) {
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? newValue) {
                          _toggleTaskCompletion(task, newValue);
                        },
                      ),
                      title: Row(
                        children: [
                          // Colored indicator based on priority.
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.name,
                              style: task.isCompleted
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        "Priority: ${task.priority}\nDue: ${_formatDate(task.dueDate)}",
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteTask(task);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button to Add a New Task.
      // (The add/edit functionality remains unchanged.)
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // Variables for the new task.
          String? name;
          String? priority;
          String? day;
          String? timeRange;
          DateTime? dueDate;
          bool isCompleted = false;

          await showDialog(
            context: context,
            builder: (context) {
              final _formKey = GlobalKey<FormState>();
              // Initialize priority to a default value if not set.
              priority ??= 'Low';
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text('Add Task'),
                    content: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Task Name Field.
                            TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Task Name'),
                              onSaved: (value) => name = value,
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Enter task name'
                                      : null,
                            ),
                            // Priority Dropdown.
                            DropdownButtonFormField<String>(
                              decoration:
                                  InputDecoration(labelText: 'Priority'),
                              value: priority,
                              items: ['Low', 'Medium', 'High'].map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  priority = value;
                                });
                              },
                              onSaved: (value) => priority = value,
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Select a priority'
                                      : null,
                            ),
                            // Due Date Picker.
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dueDate == null
                                        ? "No Date Selected"
                                        : "Due: ${_formatDate(dueDate!)}",
                                  ),
                                ),
                                ElevatedButton(
                                  child: Text("Select Date"),
                                  onPressed: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        dueDate = picked;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            // Day Field.
                            TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Day'),
                              onSaved: (value) => day = value,
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Enter day'
                                      : null,
                            ),
                            // Time Range Field.
                            TextFormField(
                              decoration: InputDecoration(
                                  labelText:
                                      'Time Range (e.g., 9 am - 10 am)'),
                              onSaved: (value) => timeRange = value,
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Enter time range'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        child: Text('Add'),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            // Ensure a due date is selected.
                            if (dueDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please select a due date')));
                              return;
                            }
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );

          // Only add the task if all required details are provided.
          if (name != null &&
              priority != null &&
              day != null &&
              timeRange != null &&
              dueDate != null) {
            FirebaseFirestore.instance.collection('tasks').add({
              'name': name,
              'priority': priority,
              'day': day,
              'timeRange': timeRange,
              'dueDate': dueDate, // Stored as a timestamp in Firestore.
              'isCompleted': isCompleted,
            });
          }
        },
      ),
    );
  }
}
