import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/services/firebase/auth/firebase_auth_service.dart';

class AuthState {
  const AuthState({
    required this.isSignedIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isSignedIn;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isSignedIn,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
        isSignedIn: isSignedIn ?? this.isSignedIn,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final authUser = ref.watch(firebaseAuthUserProvider);
    return AuthState(
      isSignedIn: authUser.value != null,
      isLoading: authUser.isLoading,
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      await _afterSuccessfulAuth(credential);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: _messageFor(error),
      );
    } catch (_) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: 'Google girisi basarisiz oldu.',
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await ref.read(firebaseAuthServiceProvider).signInWithEmailPassword(
            email: email.trim(),
            password: password,
          );
      await _afterSuccessfulAuth(credential);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: _messageFor(error),
      );
    } catch (_) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: 'E-posta ile giris basarisiz oldu.',
      );
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await ref.read(firebaseAuthServiceProvider).registerWithEmailPassword(
            email: email.trim(),
            password: password,
          );
      await _afterSuccessfulAuth(credential);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: _messageFor(error),
      );
    } catch (_) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: 'Kayit sirasinda beklenmeyen bir hata olustu.',
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthServiceProvider).signOut();
    state = state.copyWith(isSignedIn: false, clearError: true);
  }

  Future<void> _afterSuccessfulAuth(UserCredential credential) async {
    await ref.read(usersRepositoryApiProvider).ensureUser(
          uid: credential.user!.uid,
          email: credential.user?.email,
        );
    state = state.copyWith(
      isSignedIn: true,
      isLoading: false,
      clearError: true,
    );
  }
}

String _messageFor(FirebaseAuthException error) {
  if (error.code == 'operation-not-allowed') {
    return 'Firebase Console > Authentication > Sign-in method icinde gerekli provider etkin degil.';
  }
  if (error.code == 'invalid-credential') {
    return 'Girilen bilgiler gecersiz gorunuyor.';
  }
  if (error.code == 'invalid-email') {
    return 'E-posta adresi gecersiz.';
  }
  if (error.code == 'email-already-in-use') {
    return 'Bu e-posta ile zaten bir hesap var.';
  }
  if (error.code == 'weak-password') {
    return 'Sifre en az 6 karakter olmali.';
  }
  if (error.code == 'wrong-password' || error.code == 'invalid-password') {
    return 'Sifre hatali.';
  }
  if (error.code == 'user-not-found') {
    return 'Bu e-posta ile kayitli bir hesap bulunamadi.';
  }
  return error.message ?? 'Firebase Auth girisi basarisiz oldu.';
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
