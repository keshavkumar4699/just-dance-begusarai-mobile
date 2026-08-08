import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database instance
  await DatabaseHelper.instance.database;

  runApp(const JustDanceApp());
}
