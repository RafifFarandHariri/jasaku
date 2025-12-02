import 'package:flutter/foundation.dart';
import 'package:jasaku_app/models/user_model.dart';
import 'package:jasaku_app/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // Check login status saat app start
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await AuthService.getUserData();
      _user = userData;
    } catch (e) {
      print('Error checking login status: $e');
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<void> login(User user) async {
    try {
      await AuthService.saveLoginData(user);
      _user = user;
      notifyListeners();
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await AuthService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUser(User user) async {
    try {
      await AuthService.updateUserData(user);
      _user = user;
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Update user role (misal dari customer ke provider)
  Future<void> updateUserRole(String newRole) async {
    try {
      if (_user != null) {
        final updatedUser = User(
          id: _user!.id,
          nrp: _user!.nrp,
          nama: _user!.nama,
          email: _user!.email,
          phone: _user!.phone,
          profileImage: _user!.profileImage,
          role: newRole,
          isVerifiedProvider: _user!.isVerifiedProvider,
          providerSince: _user!.providerSince,
          providerDescription: _user!.providerDescription,
        );
        
        await AuthService.updateUserRole(newRole);
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Clear all data (for debugging)
  Future<void> clearAllData() async {
    try {
      await AuthService.clearAllData();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }
}