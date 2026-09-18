// lib/auth/login_screen.dart
// Visual Reference 1 (media_1789667766593.png) Implementation for MotionCare

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/widgets/motioncare_logo.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // 1. MotionCare Two-Tone Brand Logo & Tagline
                  const Center(
                    child: MotionCareLogo(fontSize: 34, showTagline: true),
                  ),
                  const SizedBox(height: 32),

                  // 2. Segmented Role Switcher Pill Container (Exact Image 1 reproduction)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inactiveTrack,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        // Patient Tab (Left)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.patient),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.patient
                                    ? AppTheme.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 19,
                                    color: _selectedRole == UserRole.patient
                                        ? Colors.white
                                        : AppTheme.darkText,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Patient',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: _selectedRole == UserRole.patient
                                          ? Colors.white
                                          : AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Doctor Tab (Right)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.doctor),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.doctor
                                    ? AppTheme.primaryGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 18,
                                    color: _selectedRole == UserRole.doctor
                                        ? Colors.white
                                        : AppTheme.darkText,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Doctor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: _selectedRole == UserRole.doctor
                                          ? Colors.white
                                          : AppTheme.darkText,
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
                  const SizedBox(height: 28),

                  // 3. "Welcome Back" Header
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue your recovery journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),

                  // Patient Account Quick Selector (when Patient role is active)
                  if (_selectedRole == UserRole.patient) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: firestore.allPatients.map((p) {
                        final isSelected = _selectedPatientId == p.patientId;
                        return ChoiceChip(
                          label: Text(
                            p.patientName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.darkText,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          backgroundColor: AppTheme.surfaceGray,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedPatientId = p.patientId;
                                _emailController.text =
                                    '${p.patientId}@physio.ai';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Password Input Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. "Forgot password?" Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Primary Action Button: "Log In ->"
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: auth.isLoading ? null : _handleSignIn,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _selectedRole == UserRole.doctor
                                          ? 'Sign In to Doctor Dashboard'
                                          : 'Sign In to Patient Portal',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 8. "OR" Divider
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(
                          color: AppTheme.cardBorder,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSubtle,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppTheme.cardBorder,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 9. "Continue with Google" Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundWhite,
                        side: const BorderSide(
                          color: AppTheme.cardBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleLogo(),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 10. Footer: "Don't have an account? Sign Up"
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: const [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtle Clinical Regulatory Notice
                  Text(
                    AppConstants.clinicalScopeBoundaryStatement,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSubtle.withOpacity(0.8),
                      height: 1.3,
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

  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFFEA4335),
                  Color(0xFFFBBC05),
                  Color(0xFF34A853),
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 20.0, 20.0)),
          ),
        ),
      ),
    );
  }
}
