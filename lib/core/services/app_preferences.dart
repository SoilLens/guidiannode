import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static SharedPreferences? _instance;

  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _showCommunityBannersKey = 'show_community_banners';
  static const _showSafetyTipsKey = 'show_safety_tips';

  static Future<void> ensureInitialized() async {
    _instance ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefs {
    final prefs = _instance;
    if (prefs == null) {
      throw StateError(
        'AppPreferences.ensureInitialized() must be called before use.',
      );
    }
    return prefs;
  }

  static bool get hasSeenOnboarding =>
      _prefs.getBool(_hasSeenOnboardingKey) ?? false;

  static Future<bool> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_hasSeenOnboardingKey, value);

  static bool get showCommunityBanners =>
      _prefs.getBool(_showCommunityBannersKey) ?? true;

  static Future<bool> setShowCommunityBanners(bool value) =>
      _prefs.setBool(_showCommunityBannersKey, value);

  static bool get showSafetyTips => _prefs.getBool(_showSafetyTipsKey) ?? true;

  static Future<bool> setShowSafetyTips(bool value) =>
      _prefs.setBool(_showSafetyTipsKey, value);
}
