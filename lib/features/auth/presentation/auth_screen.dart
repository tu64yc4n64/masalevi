import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/auth/firebase_auth_service.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/theme/widgets/masal_primary_button.dart';
import '../application/auth_controller.dart';

enum _AuthMode { signIn, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailValid = email.contains('@') && email.contains('.');
    final passwordValid = password.length >= 6;
    final canSubmit = emailValid && passwordValid && !authState.isLoading;

    return MasalPage(
      title: 'Giriş',
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Masal Evi için Google hesabinla ya da e-posta adresinle giris yap.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SegmentedButton<_AuthMode>(
                  segments: const [
                    ButtonSegment<_AuthMode>(
                      value: _AuthMode.signIn,
                      label: Text('Giris'),
                    ),
                    ButtonSegment<_AuthMode>(
                      value: _AuthMode.register,
                      label: Text('Kayit Ol'),
                    ),
                  ],
                  selected: <_AuthMode>{_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'ornek@mail.com',
                    helperText: email.isEmpty || emailValid
                        ? null
                        : 'Gecerli bir e-posta gir',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  onChanged: (_) => setState(() {}),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Sifre',
                    helperText: password.isEmpty || passwordValid
                        ? null
                        : 'Sifre en az 6 karakter olmali',
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: MasalPrimaryButton(
                    height: 52,
                    borderRadius: 16,
                    label: authState.isLoading
                        ? 'Baglaniyor...'
                        : _mode == _AuthMode.signIn
                        ? 'E-posta ile Giris Yap'
                        : 'Kayit Ol',
                    onPressed: canSubmit
                        ? () async {
                            if (_mode == _AuthMode.signIn) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithEmail(
                                    email: email,
                                    password: password,
                                  );
                            } else {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .registerWithEmail(
                                    email: email,
                                    password: password,
                                  );
                            }
                            if (!mounted) return;
                            await _handleAfterAuth();
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle();
                            if (!mounted) return;
                            await _handleAfterAuth();
                          },
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Google ile Devam'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Anonymous giris kaldirildi. Bu ekranda sadece Google ve e-posta ile kayitli hesaplar kullanilir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textBase.withValues(alpha: 0.7),
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authState.errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAfterAuth() async {
    final updatedState = ref.read(authControllerProvider);
    if (updatedState.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(updatedState.errorMessage!)));
      return;
    }

    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) {
      context.go('/auth');
      return;
    }

    final children = await ref
        .read(childrenRepositoryApiProvider)
        .getChildren(userId: user.uid);
    if (!mounted) return;

    if (children.isEmpty) {
      context.go('/child_setup');
      return;
    }

    ref
        .read(selectedChildIdProvider.notifier)
        .setSelectedChildId(children.first.childId);
    context.go('/home');
  }
}
