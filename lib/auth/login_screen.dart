// lib/auth/login_screen.dart
// Specification v7 Section 10, 27, 28: Dedicated Role-based Login Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/firestore/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.doctor;
  String _selectedPatientId = 'pat_alex_rivera';
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'doctor@physio.ai');
    _passwordController = TextEditingController(text: 'clinical_pass_2026');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.doctor) {
        _emailController.text = 'doctor@physio.ai';
        _passwordController.text = 'clinical_pass_2026';
      } else {
        _emailController.text = '$_selectedPatientId@physio.ai';
        _passwordController.text = 'patient_pass_2026';
      }
    });
  }

  void _handleSignIn() {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    if (_selectedRole == UserRole.doctor) {
      auth.signInAsDoctor();
    } else {
      final profile = firestore.getHealthProfile(_selectedPatientId);
      auth.signInAsPatient(
        patientId: _selectedPatientId,
        patientName: profile?.patientName ?? 'Alex Rivera',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.watch<FirestoreService>();
    final activePatientProfile = firestore.getHealthProfile(_selectedPatientId);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        size: 52,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MotionCare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'AI-Assisted Physiotherapy Monitoring System',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 28),

                  // Role Selection Segmented Control
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.doctor),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.doctor
                                    ? AppTheme.primaryTeal
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_services_rounded,
                                    size: 18,
                                    color: _selectedRole == UserRole.doctor
                                        ? AppTheme.darkBg
                                        : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Doctor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == UserRole.doctor
                                        ? AppTheme.darkBg
                                        : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.patient),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.patient
                                    ? AppTheme.primaryAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: _selectedRole == UserRole.patient
                                        ? AppTheme.darkBg
                                        : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Patient',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == UserRole.patient
                                          ? AppTheme.darkBg
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role Profile Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _selectedRole == UserRole.doctor
                                ? AppTheme.primaryTeal.withOpacity(0.2)
                                : AppTheme.primaryAccent.withOpacity(0.2),
                            child: Icon(
                              _selectedRole == UserRole.doctor
                                  ? Icons.health_and_safety
                                  : Icons.fitness_center,
                              color: _selectedRole == UserRole.doctor
                                  ? AppTheme.primaryTeal
                                  : AppTheme.primaryAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRole == UserRole.doctor
                                      ? 'Dr. Sarah Chen, PT, DPT'
                                      : (activePatientProfile?.patientName ?? 'Alex Rivera'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _selectedRole == UserRole.doctor
                                      ? 'Physiotherapist • Prescribe & Review'
                                      : 'Patient • ${activePatientProfile?.affectedBodyPart ?? "Active Care"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedRole == UserRole.doctor ? 'DOCTOR' : 'PATIENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _selectedRole == UserRole.doctor
                                    ? AppTheme.primaryTeal
                                    : AppTheme.primaryAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_selectedRole == UserRole.patient) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Select Patient Account:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: firestore.allPatients.map((p) {
                        final isSelected = _selectedPatientId == p.patientId;
                        return ChoiceChip(
                          label: Text(
                            p.patientName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppTheme.darkBg : AppTheme.textLight,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryAccent,
                          backgroundColor: AppTheme.cardBg,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedPatientId = p.patientId;
                                _emailController.text = '${p.patientId}@physio.ai';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Account Email',
                      prefixIcon: const Icon(Icons.alternate_email, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password Input Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Sign In Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.darkBg,
                              ),
                            )
                          : Icon(
                              _selectedRole == UserRole.doctor
                                  ? Icons.medical_services_rounded
                                  : Icons.login_rounded,
                              color: AppTheme.darkBg,
                            ),
                      label: Text(
                        auth.isLoading
                            ? 'Signing In...'
                            : _selectedRole == UserRole.doctor
                                ? 'Sign In to Doctor Dashboard'
                                : 'Sign In to Patient Portal',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedRole == UserRole.doctor
                            ? AppTheme.primaryTeal
                            : AppTheme.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: auth.isLoading ? null : _handleSignIn,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1 Mandatory Clinical Boundary Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            AppConstants.clinicalScopeBoundaryStatement,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
