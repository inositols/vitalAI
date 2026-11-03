import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/models/provider_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository authRepository;
  ProviderProfile? _cachedProfile;

  ProfileRepositoryImpl({required this.authRepository});

  @override
  Future<ProviderProfile> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final user = authRepository.currentUser;
    String name = 'Dr. Chika Okafor';
    String email = 'chika.okafor@voicevitals.ai';

    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        name = user.displayName!.trim();
      }
      if (user.email != null && user.email!.trim().isNotEmpty) {
        email = user.email!.trim();
      }
    }

    _cachedProfile = ProviderProfile(
      id: user?.uid ?? 'provider_default',
      name: name,
      email: email,
    );
    return _cachedProfile!;
  }

  @override
  Future<void> updateProfile(ProviderProfile profile) async {
    _cachedProfile = profile;
  }
}
