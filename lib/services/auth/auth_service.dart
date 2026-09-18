// lib/services/auth/auth_service.dart
// Specification v7 Section 10, 27, 28: Role-based Authentication Service

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;

  static const String _keyRole = 'auth_active_role';
  static const String _keyPatientId = 'auth_active_patient_id';
  static const String _keyPatientName = 'auth_active_patient_name';

  // Pre-seeded demo users for deterministic demonstration and offline resilience
  static final AppUser demoDoctor = AppUser(
    id: 'doc_sarah_chen',
    name: 'Dr. Sarah Chen, PT, DPT',
    email: 'doctor@physio.ai',
    role: UserRole.doctor,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );

  static final AppUser demoPatient = AppUser(
    id: 'pat_alex_rivera',
    name: 'Alex Rivera',
    email: 'patient@physio.ai',
    role: UserRole.patient,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );

  AuthService() {
    _currentUser = null;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_keyRole);
      final savedPatientId = prefs.getString(_keyPatientId);
      final savedPatientName = prefs.getString(_keyPatientName);

      if (savedRole == UserRole.doctor.name) {
        _currentUser = demoDoctor;
        notifyListeners();
      } else if (savedRole == UserRole.patient.name) {
        if (savedPatientId != null &&
            savedPatientId.isNotEmpty &&
            savedPatientId != demoPatient.id) {
          _currentUser = AppUser(
            id: savedPatientId,
            name: savedPatientName ?? 'Patient $savedPatientId',
            email: '$savedPatientId@physio.ai',
            role: UserRole.patient,
            createdAt: demoPatient.createdAt,
          );
        } else {
          _currentUser = demoPatient;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to restore auth session: $e');
    }
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser == null) {
        await prefs.remove(_keyRole);
        await prefs.remove(_keyPatientId);
        await prefs.remove(_keyPatientName);
      } else {
        await prefs.setString(_keyRole, _currentUser!.role.name);
        if (_currentUser!.isPatient) {
          await prefs.setString(_keyPatientId, _currentUser!.id);
          await prefs.setString(_keyPatientName, _currentUser!.name);
        } else {
          await prefs.remove(_keyPatientId);
          await prefs.remove(_keyPatientName);
        }
      }
    } catch (e) {
      debugPrint('Failed to persist auth session: $e');
    }
  }

  Future<void> signInAsDoctor() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = demoDoctor;
    await _persistSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInAsPatient({String? patientId, String? patientName}) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));
    if (patientId != null &&
        patientId.isNotEmpty &&
        patientId != demoPatient.id) {
      _currentUser = AppUser(
        id: patientId,
        name: patientName ?? 'Patient $patientId',
        email: '$patientId@physio.ai',
        role: UserRole.patient,
        createdAt: demoPatient.createdAt,
      );
    } else {
      _currentUser = demoPatient;
    }
    await _persistSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    if (role == UserRole.doctor) {
      _currentUser = demoDoctor;
    } else {
      _currentUser = demoPatient;
    }
    await _persistSession();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchRole() async {
    if (_currentUser?.role == UserRole.doctor) {
      _currentUser = demoPatient;
    } else {
      _currentUser = demoDoctor;
    }
    await _persistSession();
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _persistSession();
    notifyListeners();
  }
}
