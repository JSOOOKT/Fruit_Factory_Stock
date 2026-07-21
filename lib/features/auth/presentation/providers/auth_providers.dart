import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase providers
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) {
  return fb.FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthNotifier(auth, firestore);
});

class AuthState {
  final fb.User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final String? factoryId;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.factoryId,
  });

  bool get isAuthenticated => user != null && isInitialized;
  bool get isNotAuthenticated => user == null && isInitialized && !isLoading && error == null;
  bool get hasError => error != null;

  AuthState copyWith({
    fb.User? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    String? factoryId,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      factoryId: factoryId ?? this.factoryId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthNotifier(this._auth, this._firestore) : super(const AuthState()) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserFactoryId(user.uid);
      } else {
        state = state.copyWith(user: user, isInitialized: true, factoryId: null);
      }
    });
  }

  Future<void> _loadUserFactoryId(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final factoryId = data?['factoryId'] ?? data?['factory_id'] as String?;
        state = state.copyWith(
          user: _auth.currentUser,
          isInitialized: true,
          factoryId: factoryId,
        );
      } else {
        state = state.copyWith(
          user: _auth.currentUser,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        user: _auth.currentUser,
        isInitialized: true,
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _loadUserFactoryId(credential.user!.uid);
        state = state.copyWith(
          user: credential.user,
          isLoading: false,
          isInitialized: true,
        );
        return true;
      }
      return false;
    } on fb.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'ไม่พบผู้ใช้นี้ในระบบ';
          break;
        case 'wrong-password':
          errorMessage = 'รหัสผ่านไม่ถูกต้อง';
          break;
        case 'invalid-email':
          errorMessage = 'อีเมลไม่ถูกต้อง';
          break;
        case 'user-disabled':
          errorMessage = 'บัญชีผู้ใช้ถูกระงับการใช้งาน';
          break;
        case 'too-many-requests':
          errorMessage = 'พยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ภายหลัง';
          break;
        default:
          errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'factoryId': null,
          'preferred_language': 'th',
          'active': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        state = state.copyWith(
          user: credential.user,
          isLoading: false,
          isInitialized: true,
          factoryId: null,
        );
        return true;
      }
      return false;
    } on fb.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'invalid-email':
          errorMessage = 'อีเมลไม่ถูกต้อง';
          break;
        case 'weak-password':
          errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
          break;
        default:
          errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await _auth.signOut();
      state = const AuthState(isInitialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'ออกจากระบบล้มเหลว');
    }
  }

  Future<void> updateProfile(String name, String preferredLanguage) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'preferred_language': preferredLanguage,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: 'อัปเดตโปรไฟล์ล้มเหลว');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'เปลี่ยนรหัสผ่านล้มเหลว');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateFactoryId(String factoryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'factoryId': factoryId,
        'updated_at': FieldValue.serverTimestamp(),
      });
      state = state.copyWith(factoryId: factoryId);
    } catch (e) {
      state = state.copyWith(error: 'อัปเดตโรงงานล้มเหลว');
    }
  }
}

// Providers
final currentUserProvider = Provider<fb.User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final currentUserDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final notifier = ref.read(authStateProvider.notifier);
  return await notifier.getUserData(user.uid);
});

final currentFactoryIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).factoryId;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});

final hasFactoryProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).factoryId != null;
});
