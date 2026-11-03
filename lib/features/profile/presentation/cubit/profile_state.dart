import 'package:equatable/equatable.dart';
import '../../domain/models/provider_profile.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProviderProfile profile;
  final ProfileStatus status;
  final String? errorMessage;

  const ProfileState({
    this.profile = const ProviderProfile(),
    this.status = ProfileStatus.initial,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProviderProfile? profile,
    ProfileStatus? status,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [profile, status, errorMessage];
}
