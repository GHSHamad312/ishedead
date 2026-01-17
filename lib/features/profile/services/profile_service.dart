import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/emergency_contact.dart';
import '../../auth/auth_provider.dart';
import 'package:is_he_dead/features/medical/models/medical_info.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(FirebaseFirestore.instance);
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.read(profileServiceProvider).getUserProfile(user.uid);
});

final emergencyContactsProvider = StreamProvider<List<EmergencyContact>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(profileServiceProvider).getContacts(user.uid);
});

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService(this._firestore);

  // User Profile
  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Stream<UserProfile?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, uid);
      }
      return null;
    });
  }

  Future<void> updateMedicalNotes(String uid, String encryptedNotes) async {
    await _firestore.collection('users').doc(uid).update({
      'medical_notes': encryptedNotes,
    });
  }

  // New Structured Medical Info
  Future<void> updateMedicalInfo(String uid, MedicalInfo info) async {
    // For now, saving as a map field 'medical_info'
    // in a real app, might be a subcollection if it grows large
    await _firestore.collection('users').doc(uid).update({
      'medical_info': info.toMap(),
    });
  }

  Future<MedicalInfo?> getMedicalInfo(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('medical_info')) {
      return MedicalInfo.fromMap(
        doc.data()!['medical_info'] as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<void> updateWillUrl(String uid, String url) async {
    await _firestore.collection('users').doc(uid).update({'will_url': url});
  }

  Future<void> updateLegacyMessage(String uid, String message) async {
    await _firestore.collection('users').doc(uid).update({
      'legacy_message': message,
    });
  }

  Future<void> updateLastCheckIn(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'last_check_in': FieldValue.serverTimestamp(),
      'last_alert_tier': 0, // Reset alert cycle
      'last_alert_time': null, // Clear last alert time
      'status': 'Active', // Reset status to Active
    });
  }

  Future<void> updateCheckInFrequency(String uid, int hours) async {
    await _firestore.collection('users').doc(uid).update({
      'check_in_frequency': hours,
    });
  }

  Future<void> completeSetup(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'is_setup_complete': true,
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Emergency Contacts
  CollectionReference _contactsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('contacts');
  }

  Stream<List<EmergencyContact>> getContacts(String uid) {
    return _contactsRef(uid).orderBy('priority').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EmergencyContact.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> addContact(String uid, EmergencyContact contact) async {
    // If ID is provided in model, use it as document ID
    if (contact.id.isNotEmpty) {
      await _contactsRef(uid).doc(contact.id).set(contact.toMap());
    } else {
      await _contactsRef(uid).add(contact.toMap());
    }
  }

  Future<void> updateContact(String uid, EmergencyContact contact) async {
    await _contactsRef(uid).doc(contact.id).update(contact.toMap());
  }

  Future<void> deleteContact(String uid, String contactId) async {
    await _contactsRef(uid).doc(contactId).delete();
  }
}
