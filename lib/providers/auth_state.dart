import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String userEmail;
  final String userName;
  final String profileImageUrl;
  final String languageCode;
  final String phoneNumber;
  final String role;
  final bool isInitializing;
  final bool isSettingLoading;

  AuthState({
    required this.isAuthenticated,
    required this.userEmail,
    required this.userName,
    this.profileImageUrl = '',
    required this.languageCode,
    this.phoneNumber = '',
    this.role = 'Admin',
    this.isInitializing = true,
    this.isSettingLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? userName,
    String? profileImageUrl,
    String? languageCode,
    String? phoneNumber,
    String? role,
    bool? isInitializing,
    bool? isSettingLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      languageCode: languageCode ?? this.languageCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isInitializing: isInitializing ?? this.isInitializing,
      isSettingLoading: isSettingLoading ?? this.isSettingLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _fbService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;

  AuthNotifier()
      : super(AuthState(
          isAuthenticated: false,
          userEmail: '',
          userName: '',
          profileImageUrl: '',
          languageCode: 'en',
          phoneNumber: '',
          role: 'Admin',
          isInitializing: true,
          isSettingLoading: false,
        )) {
    _initAuthListener();
  }

  void _initAuthListener() async {
    final prefs = await SharedPreferences.getInstance();
    final localLang = prefs.getString('languageCode') ?? 'en';
    state = state.copyWith(languageCode: localLang);

    _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = AuthState(
          isAuthenticated: false,
          userEmail: '',
          userName: '',
          profileImageUrl: '',
          languageCode: state.languageCode,
          phoneNumber: '',
          role: 'Admin',
          isInitializing: false,
          isSettingLoading: false,
        );
      } else {
        // Fetch additional profile data & settings from Firestore
        String name = user.displayName ?? 'Sri Siva Gayathri User';
        String email = user.email ?? '';
        String photoUrl = user.photoURL ?? '';
        String phone = user.phoneNumber ?? '';
        String role = 'Admin';
        String lang = state.languageCode;

        try {
          final userDoc = await _fbService.getUserProfile(user.uid);
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            name = data['name'] ?? name;
            email = data['email'] ?? email;
            phone = data['phoneNumber'] ?? phone;
            role = data['role'] ?? role;
            photoUrl = data['profileImage'] ?? photoUrl;
          } else {
            // Create default document if not existing
            await _fbService.saveUserProfile(user.uid, {
              'uid': user.uid,
              'name': name,
              'email': email,
              'phoneNumber': phone,
              'role': role,
              'profileImage': photoUrl,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print("Error retrieving user profile from Firestore: $e");
        }

        try {
          final settingsDoc = await _fbService.getSettings(user.uid);
          if (settingsDoc.exists && settingsDoc.data() != null) {
            final data = settingsDoc.data()!;
            lang = data['languageCode'] ?? lang;
            final remoteDarkMode = data['isDarkMode'] as bool?;
            
            if (remoteDarkMode != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', remoteDarkMode);
            }
          }
        } catch (e) {
          print("Error retrieving settings from Firestore: $e");
        }

        state = AuthState(
          isAuthenticated: true,
          userEmail: email,
          userName: name,
          profileImageUrl: photoUrl,
          languageCode: lang,
          phoneNumber: phone,
          role: role,
          isInitializing: false,
          isSettingLoading: false,
        );
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isSettingLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      state = state.copyWith(isSettingLoading: false);
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isSettingLoading: true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Save profile immediately
        await _fbService.saveUserProfile(user.uid, {
          'uid': user.uid,
          'name': name,
          'email': email.trim(),
          'phoneNumber': phoneNumber,
          'role': 'Admin',
          'profileImage': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      state = state.copyWith(isSettingLoading: false);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isSettingLoading: true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(isSettingLoading: false);
    } catch (e) {
      state = state.copyWith(isSettingLoading: false);
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isSettingLoading: true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        state = state.copyWith(isSettingLoading: false);
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print("Google Sign-In failed: $e");
      state = state.copyWith(isSettingLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Google signout error: $e");
    }
    try {
      await _auth.signOut();
    } catch (e) {
      print("Firebase signout error: $e");
    }
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    state = state.copyWith(languageCode: code);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _fbService.saveSettings(user.uid, {'languageCode': code});
      } catch (e) {
        print("Error saving language setting to Firestore: $e");
      }
    }
  }

  Future<void> syncDarkModeSetting(bool isDarkMode) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _fbService.saveSettings(user.uid, {'isDarkMode': isDarkMode});
      } catch (e) {
        print("Error saving dark mode setting to Firestore: $e");
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
