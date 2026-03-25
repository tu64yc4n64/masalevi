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
      final credential = await ref
          .read(firebaseAuthServiceProvider)
          .signInWithGoogle();
      await _afterSuccessfulAuth(credential);
    } on StateError catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: error.message,
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
      final credential = await ref
          .read(firebaseAuthServiceProvider)
          .signInWithEmailPassword(email: email.trim(), password: password);
      await _afterSuccessfulAuth(credential);
    } on StateError catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: error.message,
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
      final credential = await ref
          .read(firebaseAuthServiceProvider)
          .registerWithEmailPassword(email: email.trim(), password: password);
      await _afterSuccessfulAuth(credential);
    } on StateError catch (error) {
      state = state.copyWith(
        isSignedIn: false,
        isLoading: false,
        errorMessage: error.message,
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
    await ref
        .read(usersRepositoryApiProvider)
        .ensureUser(uid: credential.user!.uid, email: credential.user?.email);
    state = state.copyWith(
      isSignedIn: true,
      isLoading: false,
      clearError: true,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
