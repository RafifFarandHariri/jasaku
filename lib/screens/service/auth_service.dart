import 'package:shared_preferences/shared_preferences.dart';
import 'package:jasaku_app/models/user_model.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userIdKey = 'userId';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userNrpKey = 'userNrp';
  static const String _userRoleKey = 'userRole';
  static const String _userPhoneKey = 'userPhone';

  // Simpan data login
  static Future<void> saveLoginData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setInt(_userIdKey, user.id ?? 0);
      await prefs.setString(_userNameKey, user.nama);
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userNrpKey, user.nrp);
      await prefs.setString(_userRoleKey, user.role);
      await prefs.setString(_userPhoneKey, user.phone ?? '');
    } catch (e) {
      print('Error saving login data: $e');
    }
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get user data dari shared preferences
  static Future<User?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) return null;

      return User(
        id: prefs.getInt(_userIdKey),
        nrp: prefs.getString(_userNrpKey) ?? '',
        nama: prefs.getString(_userNameKey) ?? '',
        email: prefs.getString(_userEmailKey) ?? '',
        phone: prefs.getString(_userPhoneKey),
        role: prefs.getString(_userRoleKey) ?? 'customer',
      );
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Logout - hapus data
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNrpKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userPhoneKey);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Update user data
  static Future<void> updateUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, user.nama);
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userRoleKey, user.role);
      await prefs.setString(_userPhoneKey, user.phone ?? '');
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // Update user role (misal dari customer ke provider)
  static Future<void> updateUserRole(String newRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, newRole);
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  // Clear all auth data (for debugging)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }
}