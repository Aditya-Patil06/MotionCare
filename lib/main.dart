// lib/main.dart
// Main Application Entrypoint with Role-based Navigation & MultiProvider

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth/login_screen.dart';
import 'core/theme.dart';
import 'doctor/dashboard/doctor_dashboard.dart';
import 'patient/dashboard/patient_dashboard.dart';
import 'services/auth/auth_service.dart';
import 'services/firestore/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MotionCareApp());
}

class MotionCareApp extends StatelessWidget {
  const MotionCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'MotionCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.currentUser == null) {
      return const LoginScreen();
    }

    if (auth.currentUser!.isDoctor) {
      return const DoctorDashboard();
    } else {
      return const PatientDashboard();
    }
  }
}
