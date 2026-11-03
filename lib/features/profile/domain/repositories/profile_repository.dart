import '../models/provider_profile.dart';

abstract class ProfileRepository {
  Future<ProviderProfile> getProfile();
  Future<void> updateProfile(ProviderProfile profile);
}
