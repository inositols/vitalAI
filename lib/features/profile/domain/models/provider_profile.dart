import 'package:equatable/equatable.dart';

/// Domain model representing a healthcare provider's profile.
class ProviderProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String facility;
  final String specialty;
  final String licenseNumber;
  final bool voiceFeedbackEnabled;
  final bool highContrastEnabled;
  final bool hapticFeedbackEnabled;

  const ProviderProfile({
    this.id = '',
    this.name = '',
    this.email = '',
    this.role = 'Attending Physician',
    this.facility = 'Memorial Health Clinic',
    this.specialty = 'Cardiology & General Medicine',
    this.licenseNumber = 'MD-74892-NY',
    this.voiceFeedbackEnabled = true,
    this.highContrastEnabled = false,
    this.hapticFeedbackEnabled = true,
  });

  ProviderProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? facility,
    String? specialty,
    String? licenseNumber,
    bool? voiceFeedbackEnabled,
    bool? highContrastEnabled,
    bool? hapticFeedbackEnabled,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      facility: facility ?? this.facility,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      voiceFeedbackEnabled: voiceFeedbackEnabled ?? this.voiceFeedbackEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        facility,
        specialty,
        licenseNumber,
        voiceFeedbackEnabled,
        highContrastEnabled,
        hapticFeedbackEnabled,
      ];
}
