class EmergencyContact {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String relationship;
  final int priority;
  final bool accessVault;
  final bool accessLegacyMessage;
  final bool accessMedicalInfo;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.relationship = 'Friend',
    required this.priority,
    this.accessVault = false,
    this.accessLegacyMessage = true,
    this.accessMedicalInfo = false,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> data, String id) {
    return EmergencyContact(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? 'Friend',
      priority: data['priority'] ?? 1,
      accessVault: data['accessVault'] ?? false,
      accessLegacyMessage:
          data['accessLegacyMessage'] ?? true, // Defaulting to true for now
      accessMedicalInfo: data['accessMedicalInfo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
      'priority': priority,
      'accessVault': accessVault,
      'accessLegacyMessage': accessLegacyMessage,
      'accessMedicalInfo': accessMedicalInfo,
    };
  }
}
