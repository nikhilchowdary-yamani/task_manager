import 'package:flutter/material.dart';
import '../task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Sample nested data for schedules
  List<DaySchedule> daySchedules = [
    DaySchedule(
      day: 'Monday',
      timeSlots: [
        TimeSlot(
          timeRange: '9 am - 10 am',
          tasks: [
            Task(name: 'HW1', isCompleted: false, priority: 'High'),
            Task(name: 'Essay2', isCompleted: false, priority: 'Medium'),
          ],
        ),
        TimeSlot(
          timeRange: '12 pm - 2 pm',
          tasks: [
            Task(name: 'Review notes', isCompleted: false, priority: 'Low'),
            Task(name: 'Prepare presentation', isCompleted: false, priority: 'High'),
          ],
        ),
      ],
    ),
    DaySchedule(
      day: 'Tuesday',
      timeSlots: [
        TimeSlot(
          timeRange: '10 am - 11 am',
          tasks: [
            Task(name: 'Team meeting', isCompleted: false, priority: 'High'),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List with Schedule'),
      ),
      body: ListView.builder(
        itemCount: daySchedules.length,
        itemBuilder: (context, dayIndex) {
          final daySchedule = daySchedules[dayIndex];
          return ExpansionTile(
            title: Text(daySchedule.day),
            children: daySchedule.timeSlots.map((timeSlot) {
              return ExpansionTile(
                title: Text(timeSlot.timeRange),
                children: timeSlot.tasks.map((task) {
                  return ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          task.isCompleted = value ?? false;
                        });
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
                        setState(() {
                          timeSlot.tasks.remove(task);
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// Helper model class to represent a time slot and its associated tasks.
class TimeSlot {
  String timeRange;
  List<Task> tasks;

  TimeSlot({required this.timeRange, required this.tasks});
}

// Helper model class to represent a day's schedule.
class DaySchedule {
  String day;
  List<TimeSlot> timeSlots;

  DaySchedule({required this.day, required this.timeSlots});
}
