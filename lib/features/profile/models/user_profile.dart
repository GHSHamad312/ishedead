import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_he_dead/features/medical/models/medical_info.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? fullName;
  final String? phone;
  final DateTime lastCheckIn;
  final String status;
  final String? willUrl;
  final String? medicalNotes;
  final MedicalInfo? medicalInfo;
  final bool isSetupComplete;
  final int checkInFrequency; // In hours
  final bool voiceAuthEnabled;
  final Map<String, dynamic>? travelPlans;
  final String? legacyMessage;
  final int lastAlertTier;

  const UserProfile({
    required this.uid,
    required this.email,
    this.fullName,
    this.phone,
    required this.lastCheckIn,
    this.status = 'Active',
    this.voiceAuthEnabled = false,
    this.isSetupComplete = false,
    this.willUrl,
    this.medicalNotes,
    this.medicalInfo,
    this.travelPlans,
    this.checkInFrequency = 24,
    this.legacyMessage,
    this.lastAlertTier = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      lastCheckIn: map['last_check_in'] != null
          ? (map['last_check_in'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'Active',
      voiceAuthEnabled: map['voice_auth_enabled'] as bool? ?? false,
      isSetupComplete: map['is_setup_complete'] as bool? ?? false,
      willUrl: map['will_url'] as String?,
      medicalNotes: map['medical_notes'] as String?,
      medicalInfo: map['medical_info'] != null
          ? MedicalInfo.fromMap(map['medical_info'] as Map<String, dynamic>)
          : null,
      travelPlans: map['travel_plans'] as Map<String, dynamic>?,
      checkInFrequency: map['check_in_frequency'] as int? ?? 24,
      legacyMessage: map['legacy_message'] as String?,
      lastAlertTier: map['last_alert_tier'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'last_check_in': Timestamp.fromDate(lastCheckIn),
      'status': status,
      'voice_auth_enabled': voiceAuthEnabled,
      'is_setup_complete': isSetupComplete,
      'will_url': willUrl,
      'medical_notes': medicalNotes,
      'medical_info': medicalInfo?.toMap(),
      'travel_plans': travelPlans,
      'check_in_frequency': checkInFrequency,
      'legacy_message': legacyMessage,
      'last_alert_tier': lastAlertTier,
    };
  }
}
