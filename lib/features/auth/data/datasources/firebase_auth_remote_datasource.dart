import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/auth_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_request.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';
import 'package:fruit_factory_stock/shared/models/user.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseAuthRemoteDataSource({
    required fb.FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Future<AuthResponse> signUp(SignUpRequest request) async {
    try {
      // Validate passwords match
      if (!request.passwordsMatch) {
        throw FirebaseFailure('Passwords do not match');
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseFailure('Failed to create user');
      }

      // Create user document in Firestore
      final user = User(
        uid: firebaseUser.uid,
        name: request.name,
        email: request.email,
        role: request.role,
        preferredLanguage: request.preferredLanguage,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(
            user.toJson(),
          );

      // Get ID token
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        throw FirebaseFailure('Failed to get authentication token');
      }

      _logger.i('User created successfully: ${firebaseUser.uid}');

      return AuthResponse(user: user, token: token);
    } on fb.FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code}', error: e);
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Sign up error', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signIn(LoginRequest request) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseFailure('Failed to sign in user');
      }

      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        throw NotFoundFailure('User profile not found');
      }

      final user = User.fromJson(userDoc.data()!);

      // Get ID token
      final token = await firebaseUser.getIdToken();
      if (token == null) {
        throw FirebaseFailure('Failed to get authentication token');
      }

      // Update last login
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'last_login_at': FieldValue.serverTimestamp(),
      });

      _logger.i('User signed in: ${firebaseUser.uid}');

      return AuthResponse(user: user, token: token);
    } on fb.FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code}', error: e);
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Sign in error', error: e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('User signed out');
    } catch (e) {
      _logger.e('Sign out error', error: e);
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _auth.sendPasswordResetEmail(email: request.email);
      _logger.i('Password reset email sent to: ${request.email}');
    } on fb.FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code}', error: e);
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Reset password error', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthResponse?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _logger.i('No current user');
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        _logger.w('Current user profile not found');
        return null;
      }

      final user = User.fromJson(userDoc.data()!);
      final token = await firebaseUser.getIdToken();

      return AuthResponse(user: user, token: token ?? '');
    } catch (e) {
      _logger.e('Get current user error', error: e);
      return null;
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthFailure('No user logged in');
      }

      await user.sendEmailVerification();
      _logger.i('Verification email sent');
    } catch (e) {
      _logger.e('Email verification error', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String preferredLanguage,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'preferred_language': preferredLanguage,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _logger.i('User profile updated: $userId');
    } catch (e) {
      _logger.e('Update profile error', error: e);
      rethrow;
    }
  }

  /// Map Firebase exceptions to custom failures
  Failure _mapFirebaseException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure('User not found');
      case 'wrong-password':
        return AuthFailure('Wrong password');
      case 'email-already-in-use':
        return AuthFailure('Email already in use');
      case 'weak-password':
        return ValidationFailure('Password is too weak', {'password': 'Password must be at least 6 characters'});
      case 'invalid-email':
        return ValidationFailure('Invalid email', {'email': 'Invalid email format'});
      case 'operation-not-allowed':
        return AuthFailure('Operation not allowed');
      case 'too-many-requests':
        return AuthFailure('Too many requests. Please try again later.');
      default:
        return FirebaseFailure(e.message ?? 'Authentication failed', e.code);
    }
  }
}
