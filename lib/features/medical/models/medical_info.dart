class MedicalInfo {
  final String? bloodType;
  final List<String> allergies;
  final List<String> medications;
  final String? notes;

  MedicalInfo({
    this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'notes': notes,
    };
  }

  factory MedicalInfo.fromMap(Map<String, dynamic> map) {
    return MedicalInfo(
      bloodType: map['bloodType'] as String?,
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      notes: map['notes'] as String?,
    );
  }
}
