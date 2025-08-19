import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _userNameKey = 'user_name';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'app_language';

  static UserPreferencesService? _instance;
  static UserPreferencesService get instance => _instance ??= UserPreferencesService._();

  UserPreferencesService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get user name
  String? getUserName() {
    return _prefs?.getString(_userNameKey);
  }

  /// Set user name
  Future<bool> setUserName(String name) async {
    await init();
    final firstLaunchSet = await _prefs?.setBool(_isFirstLaunchKey, false) ?? false;
    final nameSet = await _prefs?.setString(_userNameKey, name) ?? false;
    return firstLaunchSet && nameSet;
  }

  /// Check if it's the first launch
  bool isFirstLaunch() {
    return _prefs?.getBool(_isFirstLaunchKey) ?? true;
  }

  /// Mark first launch as completed
  Future<bool> setFirstLaunchCompleted() async {
    await init();
    return _prefs?.setBool(_isFirstLaunchKey, false) ?? false;
  }

  /// Clear all user preferences
  Future<bool> clearAll() async {
    await init();
    return _prefs?.clear() ?? false;
  }

  /// Check if user has set their name
  bool hasUserName() {
    final name = getUserName();
    return name != null && name.isNotEmpty;
  }

  /// Get welcome message with user name
  String getWelcomeMessage() {
    final name = getUserName();
    if (name != null && name.isNotEmpty) {
      return 'Bonjour, $name !';
    }
    return 'Bonjour !';
  }

  // === GESTION DU THÈME ===

  /// Get saved theme mode (default: light)
  String getThemeMode() {
    return _prefs?.getString(_themeKey) ?? 'light';
  }

  /// Set theme mode
  Future<bool> setThemeMode(String themeMode) async {
    await init();
    return _prefs?.setString(_themeKey, themeMode) ?? false;
  }

  // === GESTION DE LA LANGUE ===

  /// Get saved language (default: system)
  String getLanguage() {
    return _prefs?.getString(_languageKey) ?? 'system';
  }

  /// Set language
  Future<bool> setLanguage(String language) async {
    await init();
    return _prefs?.setString(_languageKey, language) ?? false;
  }
}