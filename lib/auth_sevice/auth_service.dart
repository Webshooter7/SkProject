import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userRoleKey = 'userRole';

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Save login state
  static Future<void> saveLoginState(String email, String role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
  }

  // Clear login state
  static Future<void> clearLoginState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }

  // Get saved user email
  static Future<String?> getSavedUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get saved user role
  static Future<String?> getSavedUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Logout user
  static Future<void> logout() async {
    await _auth.signOut();
    await clearLoginState();
  }

  // Role-based login method
  static Future<bool> loginWithRole({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!userDoc.exists || userDoc['role'] != expectedRole) {
        await logout(); // Force sign out on mismatch
        return false;
      }

      await saveLoginState(email, expectedRole);
      return true;
    } catch (e) {
      return false;
    }
  }
}