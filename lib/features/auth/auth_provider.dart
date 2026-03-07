import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

/// Provides the Authentication Service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Streams the authentication state (logs in/out)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
