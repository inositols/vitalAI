import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/provider_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Cubit managing focused provider profile state and clinical preferences.
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> updateRole(String role) async {
    final updated = state.profile.copyWith(role: role);
    await _saveProfile(updated);
  }

  Future<void> toggleVoiceFeedback() async {
    final updated = state.profile.copyWith(
      voiceFeedbackEnabled: !state.profile.voiceFeedbackEnabled,
    );
    await _saveProfile(updated);
  }

  Future<void> toggleHighContrast() async {
    final updated = state.profile.copyWith(
      highContrastEnabled: !state.profile.highContrastEnabled,
    );
    await _saveProfile(updated);
  }

  Future<void> updateProfile(ProviderProfile profile) async {
    await _saveProfile(profile);
  }

  Future<void> _saveProfile(ProviderProfile profile) async {
    try {
      await repository.updateProfile(profile);
      emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, errorMessage: e.toString()));
    }
  }
}
