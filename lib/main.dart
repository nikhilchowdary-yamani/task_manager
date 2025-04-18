import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'task_list_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(MaterialApp(
    home: TaskListScreen(),
  ));
}
