import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/lock_screen.dart';
import 'constants.dart';

class JustDanceApp extends StatelessWidget {
  const JustDanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LockScreen(),
    );
  }
}
