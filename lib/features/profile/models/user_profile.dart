import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_he_dead/features/medical/models/medical_info.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? fullName; // Added
  final String? phone; // Added
  final DateTime lastCheckIn;
  final bool registrationPaid;
  final String status;
  final String? willUrl;
  final String? medicalNotes; // Keeping for legacy, prefer medicalInfo.notes
  final MedicalInfo? medicalInfo; // Added structured data
  final Map<String, dynamic>? travelPlans;
  final bool isSafetyModeEnabled;
  final bool isSetupComplete;
  final int checkInFrequency; // (hours)
  final String? legacyMessage; // Added

  UserProfile({
    required this.uid,
    required this.email,
    this.fullName,
    this.phone,
    required this.lastCheckIn,
    required this.registrationPaid,
    required this.status,
    this.willUrl,
    this.medicalNotes,
    this.medicalInfo,
    this.travelPlans,
    this.isSafetyModeEnabled = false,
    this.isSetupComplete = false,
    this.checkInFrequency = 24,
    this.legacyMessage,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['full_name'],
      phone: data['phone'],
      lastCheckIn: (data['last_check_in'] as Timestamp).toDate(),
      registrationPaid: data['registration_paid'] ?? false,
      status: data['status'] ?? 'Active',
      willUrl: data['will_url'],
      medicalNotes: data['medical_notes'],
      medicalInfo: data['medical_id'] != null
          ? MedicalInfo.fromMap(data['medical_id'])
          : null,
      travelPlans: data['travel_plans'],
      isSafetyModeEnabled: data['is_safety_mode_enabled'] ?? false,
      isSetupComplete: data['is_setup_complete'] ?? false,
      checkInFrequency: data['check_in_frequency'] ?? 24,
      legacyMessage: data['legacy_message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'last_check_in': Timestamp.fromDate(lastCheckIn),
      'registration_paid': registrationPaid,
      'status': status,
      'will_url': willUrl,
      'medical_notes': medicalNotes,
      'medical_id': medicalInfo?.toMap(),
      'travel_plans': travelPlans,
      'is_safety_mode_enabled': isSafetyModeEnabled,
      'is_setup_complete': isSetupComplete,
      'check_in_frequency': checkInFrequency,
      'legacy_message': legacyMessage,
    };
  }
}
