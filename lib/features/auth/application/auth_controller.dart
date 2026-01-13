import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef Email = String;
typedef Password = String;

class AuthFormState {
  final Email email;
  final Password password;
  final bool isLoading;
  final String? error;

  const AuthFormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
  });

  AuthFormState copyWith({
    Email? email,
    Password? password,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthFormState> {
  AuthController() : super(const AuthFormState());

  final _client = Supabase.instance.client;

  void setEmail(String v) => state = state.copyWith(email: v.trim(), clearError: true);
  void setPassword(String v) => state = state.copyWith(password: v, clearError: true);

  bool _validate() {
    if (state.email.isEmpty || !state.email.contains('@')) {
      state = state.copyWith(error: 'Geçerli bir e-posta gir.');
      return false;
    }
    if (state.password.length < 6) {
      state = state.copyWith(error: 'Şifre en az 6 karakter olmalı.');
      return false;
    }
    return true;
  }

  Future<void> signIn() async {
    if (!_validate()) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _client.auth.signInWithPassword(
        email: state.email,
        password: state.password,
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(error: 'Giriş başarısız.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signUp() async {
    if (!_validate()) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _client.auth.signUp(email: state.email, password: state.password);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(error: 'Kayıt başarısız.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authControllerProvider =
StateNotifierProvider<AuthController, AuthFormState>((ref) => AuthController());