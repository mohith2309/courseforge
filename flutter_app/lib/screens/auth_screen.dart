import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

/// Minimal Google "G" mark (no asset needed).
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: const Text('G',
          style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              height: 1.1)),
    );
  }
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _busy = false;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _googleBusy = false;

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    final err = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google')),
      );
      context.pop();
    } else if (err != 'cancelled') {
      setState(() => _error = err);
    }
  }

  Future<void> _submit() async {
    final api = ref.read(apiClientProvider);
    if (!api.isConfigured) {
      setState(() => _error =
          'No backend configured. Run server/ and launch with '
          '--dart-define=BACKEND_URL=http://localhost:8788');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authProvider.notifier);
    final err = _isLogin
        ? await auth.login(_email.text.trim(), _password.text)
        : await auth.register(
            _email.text.trim(), _password.text, _name.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Signed in' : 'Account created')),
      );
      context.pop();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backendOn = ref.watch(apiClientProvider).isConfigured;
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign in' : 'Create account')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          const SizedBox(height: Gap.sm),
          const CourseThumb(emoji: '🔨', size: 56),
          const SizedBox(height: Gap.md),
          Text(
            _isLogin ? 'Welcome back' : 'Join CourseForge',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Accounts are optional — you only need one to publish a course.',
            style: TextStyle(color: context.muted),
          ),
          const SizedBox(height: Gap.lg),

          // Primary: Continue with Google (Firebase). Works without the backend.
          OutlinedButton(
            onPressed: _googleBusy ? null : _google,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: context.isDark ? null : Colors.white,
              side: BorderSide(color: context.border),
            ),
            child: _googleBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleG(),
                      const SizedBox(width: Gap.sm),
                      Text('Continue with Google',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: context.fg)),
                    ],
                  ),
          ),
          const SizedBox(height: Gap.md),
          Row(children: [
            Expanded(child: Divider(color: context.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
              child: Text('or', style: TextStyle(color: context.muted)),
            ),
            Expanded(child: Divider(color: context.border)),
          ]),
          const SizedBox(height: Gap.md),

          if (!backendOn)
            Container(
              padding: const EdgeInsets.all(Gap.md),
              margin: const EdgeInsets.only(bottom: Gap.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(
                'Backend not connected. Start server/ and run the app with '
                '--dart-define=BACKEND_URL=http://localhost:8788 to enable accounts.',
                style: const TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
          if (!_isLogin) ...[
            const Text('Name'),
            const SizedBox(height: 6),
            TextField(controller: _name),
            const SizedBox(height: Gap.md),
          ],
          const Text('Email'),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          const SizedBox(height: Gap.md),
          const Text('Password'),
          const SizedBox(height: 6),
          TextField(controller: _password, obscureText: true),
          if (_error != null) ...[
            const SizedBox(height: Gap.md),
            Text(_error!, style: const TextStyle(color: AppColors.destructive)),
          ],
          const SizedBox(height: Gap.lg),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isLogin ? 'Sign in' : 'Create account'),
          ),
          const SizedBox(height: Gap.sm),
          TextButton(
            onPressed: () => setState(() {
              _isLogin = !_isLogin;
              _error = null;
            }),
            child: Text(_isLogin
                ? 'New here? Create an account'
                : 'Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}
