import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../services/auth_service.dart';
import '../services/email_rules.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signup = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  int _strength(String s) {
    var n = 0;
    if (s.length >= 8) n++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) n++;
    if (RegExp(r'\d').hasMatch(s)) n++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) n++;
    return n;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    final emailIssue = EmailRules.validate(_email.text);
    final pass = _pass.text;

    if (_signup && _name.text.trim().length < 2) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (emailIssue != null) {
      setState(() => _error = emailIssue);
      return;
    }
    if (_signup) {
      if (pass.length < 8 ||
          !RegExp(r'[A-Za-z]').hasMatch(pass) ||
          !RegExp(r'\d').hasMatch(pass)) {
        setState(() =>
            _error = 'Password needs 8+ characters with letters and a number.');
        return;
      }
      if (pass != _pass2.text) {
        setState(() => _error = 'The two passwords do not match.');
        return;
      }
    } else if (pass.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }

    setState(() => _busy = true);
    final app = context.read<AppState>();
    final email = EmailRules.normalize(_email.text);
    try {
      if (_signup) {
        await app.signUp(_name.text.trim(), email, pass);
      } else {
        await app.signIn(email, pass);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final issue = EmailRules.validate(_email.text);
    if (issue != null) {
      setState(() => _error = 'Type your UEMF email above first. $issue');
      return;
    }
    try {
      await context.read<AppState>().resetPassword(EmailRules.normalize(_email.text));
      if (!mounted) return;
      toast(
        context,
        AppConfig.useFirebase
            ? 'If an account exists, a reset link is on its way.'
            : 'Demo mode: no real email is sent.',
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final touched = _email.text.trim().isNotEmpty;
    final issue = EmailRules.validate(_email.text);
    final strength = _strength(_pass.text);

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: p.gradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: p.a.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded,
                    size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              index: 1,
              child: Text('Welcome to', style: AppText.body(16, color: AppColors.muted)),
            ),
            FadeSlideIn(
              index: 1,
              child: GradientText(
                AppConfig.appName,
                style: AppText.display(44, letterSpacing: -1.2, height: 1.05),
              ),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              index: 2,
              child: Text(
                'Announcements, events and clubs of ${AppConfig.universityShort}, all in one place.',
                style: AppText.body(15, color: AppColors.muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 28),

            // Login / Sign up switch
            FadeSlideIn(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _SegButton(
                      label: 'Sign in',
                      selected: !_signup,
                      onTap: () => setState(() {
                        _signup = false;
                        _error = null;
                      }),
                    ),
                    _SegButton(
                      label: 'Create account',
                      selected: _signup,
                      onTap: () => setState(() {
                        _signup = true;
                        _error = null;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  if (_signup) ...[
                    AppField(
                      controller: _name,
                      hint: 'Full name',
                      icon: Icons.person_rounded,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            AppField(
              controller: _email,
              hint: 'name@${AppConfig.allowedDomains.first}',
              icon: Icons.mail_rounded,
              keyboard: TextInputType.emailAddress,
              action: TextInputAction.next,
              onChanged: (_) => setState(() => _error = null),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Padding(
                key: ValueKey(touched ? (issue ?? 'ok') : 'hint'),
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      !touched
                          ? Icons.info_outline_rounded
                          : (issue == null
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded),
                      size: 16,
                      color: !touched
                          ? AppColors.muted
                          : (issue == null ? AppColors.success : AppColors.danger),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        !touched
                            ? 'Use your official UEMF email address.'
                            : (issue ?? 'UEMF email recognised.'),
                        style: AppText.body(
                          12.5,
                          color: !touched
                              ? AppColors.muted
                              : (issue == null
                                  ? AppColors.success
                                  : AppColors.danger),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            AppField(
              controller: _pass,
              hint: 'Password',
              icon: Icons.lock_rounded,
              obscure: _obscure,
              action: _signup ? TextInputAction.next : TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) {
                if (!_signup) _submit();
              },
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),

            if (_signup) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i < strength
                              ? (strength <= 1
                                  ? AppColors.danger
                                  : strength == 2
                                      ? AppColors.warning
                                      : AppColors.success)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AppField(
                controller: _pass2,
                hint: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                action: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppText.body(13.5,
                                    color: AppColors.danger, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 22),
            GradientButton(
              label: _signup ? 'Create account' : 'Sign in',
              loading: _busy,
              onTap: _submit,
            ),

            if (!_signup) ...[
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: _forgotPassword,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Forgot password?',
                      style: AppText.body(14, w: FontWeight.w600, color: p.b),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 22),
            if (!AppConfig.useFirebase)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.science_rounded,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo mode: accounts live on this phone and no real email is sent. Connect Firebase for real email verification (see README).',
                        style: AppText.body(12.5,
                            color: AppColors.warning, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Only @${AppConfig.allowedDomains.first} accounts can join.',
                    style: AppText.body(12.5, color: AppColors.muted),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? p.gradient : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: AppText.body(
              14.5,
              w: FontWeight.w700,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
