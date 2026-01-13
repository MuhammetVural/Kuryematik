import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Basit şifre gizle/göster state'i
final passwordObscureProvider = StateProvider<bool>((ref) => true);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _snack(String message, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? Colors.green : null,
      ),
    );
  }

  String _mapAuthError(AuthException e, {required bool isLogin}) {
    final raw = e.message.toLowerCase();

    if (isLogin) {
      if (raw.contains('invalid login credentials')) {
        return 'E-posta veya şifre hatalı.';
      }
      if (raw.contains('email not confirmed') ||
          raw.contains('email_confirmation_required')) {
        return 'E-posta onaylanmamış. Mail kutunu kontrol et.';
      }
      return 'Giriş sırasında hata oluştu. Tekrar dene.';
    } else {
      if (raw.contains('user already registered') ||
          raw.contains('already exists') ||
          raw.contains('duplicate')) {
        return 'Bu e-posta ile zaten hesap var. Giriş yap.';
      }
      return 'Kayıt sırasında hata oluştu. Tekrar dene.';
    }
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _email.text.trim();
    final pass = _pass.text;

    if (!email.contains('@')) {
      _snack('Geçerli bir e-posta gir.');
      return;
    }
    if (pass.length < 6) {
      _snack('Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() => _loading = true);

    final client = Supabase.instance.client;
    try {
      if (_isLogin) {
        await client.auth.signInWithPassword(email: email, password: pass);
        _snack('Giriş başarılı.', ok: true);
      } else {
        await client.auth.signUp(email: email, password: pass);

        // Email confirmation açıksa session oluşmaz, mail ister.
        if (client.auth.currentSession == null) {
          _snack('Kayıt alındı. Mail onayı gerekiyorsa mail kutunu kontrol et.',
              ok: true);
        } else {
          _snack('Kayıt başarılı.', ok: true);
        }

        if (mounted) setState(() => _isLogin = true);
      }
    } on AuthException catch (e) {
      _snack(_mapAuthError(e, isLogin: _isLogin));
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color topColor;
    final Color bottomColor;

    if (isLogin) {
      // Login = yeşil tonları
      topColor = isDark ? const Color(0xFF2E4635) : const Color(0xFFD9F6DB);
      bottomColor = isDark ? const Color(0xFF3B5C46) : const Color(0xFFC9F0CF);
    } else {
      // Signup = pembe tonları
      topColor = isDark ? const Color(0xFF4B2F3B) : const Color(0xFFFFD6E0);
      bottomColor = isDark ? const Color(0xFF5E3C4C) : const Color(0xFFFFC2D0);
    }

    final double topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  );
                  return FadeTransition(opacity: curved, child: child);
                },
                child: _BlobsBackground(
                  key: ValueKey(isLogin ? 'bg-login' : 'bg-signup'),
                  topRightColor: topColor,
                  bottomLeftColor: bottomColor,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        );
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(curved);
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(isLogin ? 'login' : 'signup'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLogin
                                ? 'Devam etmek için hesabına giriş yap.'
                                : 'Yeni bir kurye hesabı oluştur.',
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.72),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _AUTextField(
                            controller: _email,
                            hint: 'E-posta',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 18),
                          _PasswordField(controller: _pass),
                          const SizedBox(height: 24),
                          _PrimaryButton(
                            label: isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            onPressed: _loading ? null : _submit,
                            isLoading: _loading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          isLogin
                              ? 'Hesabın yok mu? Kayıt ol'
                              : 'Hesabın var mı? Giriş yap',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- UI helper widgets (Kuryematik) ----------

class _BlobsBackground extends StatelessWidget {
  const _BlobsBackground({
    super.key,
    required this.topRightColor,
    required this.bottomLeftColor,
  });

  final Color topRightColor;
  final Color bottomLeftColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -40,
            child: _Blob(color: topRightColor, size: 280),
          ),
          Positioned(
            left: -60,
            top: 180,
            child: _Blob(
              color: bottomLeftColor.withValues(alpha: .85),
              size: 260,
            ),
          ),
          Positioned(
            right: -120,
            bottom: -60,
            child: _Blob(color: bottomLeftColor, size: 360),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isLoading
              ? const SizedBox(
            key: ValueKey('btn-spinner'),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(
            label,
            key: const ValueKey('btn-label'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AUTextField extends StatelessWidget {
  const _AUTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final bool obscure;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            width: 0.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _PasswordField extends ConsumerWidget {
  const _PasswordField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obscure = ref.watch(passwordObscureProvider);

    return _AUTextField(
      controller: controller,
      hint: 'Şifre',
      obscure: obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          ref.read(passwordObscureProvider.notifier).state = !obscure;
        },
      ),
    );
  }
}