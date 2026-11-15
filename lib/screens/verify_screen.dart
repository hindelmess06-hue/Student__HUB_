import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shown after sign-up (or sign-in) until the e-mail is verified.
///  * Firebase: the person taps the link in their inbox; we poll for it.
///  * Demo:     the person types a 6-digit code (shown on screen).
/// If the address does not exist, no message ever arrives and the account
/// simply never gets verified, so nobody can get in with a fake address.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  Timer? _poll;
  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _busy = false;
  String? _error;
  String? _info;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (app.auth.usesCodeEntry) {
      if (app.auth.demoCode == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await app.resendVerification();
          } catch (_) {}
        });
      }
    } else {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) {
        app.refreshVerification();
      });
    }
    _cooldown = 30;
    _runCooldown();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldownTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _runCooldown();
  }

  void _runCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await context.read<AppState>().resendVerification();
      if (!mounted) return;
      setState(() => _info = 'A new message was sent.');
      _startCooldown();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _checkLink() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final ok = await context.read<AppState>().refreshVerification();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _error =
            "Not verified yet. Open the link in the email we sent. If nothing arrived, check the spelling of your address.";
      }
    });
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await context.read<AppState>().submitCode(_code.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _error = 'That code is not correct. Try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    final email = app.user?.email ?? '';
    final codeMode = app.auth.usesCodeEntry;

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const _PulsingMail(),
            const SizedBox(height: 28),
            Text('Verify your email',
                style: AppText.display(30, letterSpacing: -0.6)),
            const SizedBox(height: 12),
            Text(
              codeMode
                  ? 'Enter the 6-digit code we would send to'
                  : 'We sent a verification link to',
              textAlign: TextAlign.center,
              style: AppText.body(15, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: AppText.body(16, w: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              codeMode
                  ? 'Only verified UEMF accounts can enter the app.'
                  : 'Open the link on this phone or any device. This screen continues automatically once you are verified.',
              textAlign: TextAlign.center,
              style: AppText.body(13.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 26),

            if (codeMode) ...[
              GlassCard(
                gradient: LinearGradient(colors: [
                  p.a.withValues(alpha: 0.18),
                  p.b.withValues(alpha: 0.10),
                ]),
                child: Row(
                  children: [
                    const Icon(Icons.science_rounded, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Demo inbox',
                              style: AppText.body(12.5,
                                  color: AppColors.warning,
                                  w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            app.auth.demoCode ?? '...',
                            style: AppText.display(26, letterSpacing: 6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.display(28, letterSpacing: 10),
                cursorColor: p.b,
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                  if (v.length == 6) _submitCode();
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: AppText.display(28,
                      letterSpacing: 10, color: AppColors.muted),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: p.b, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Verify',
                loading: _busy,
                onTap: _submitCode,
              ),
            ] else ...[
              GradientButton(
                label: "I've verified my email",
                icon: Icons.mark_email_read_rounded,
                loading: _busy,
                onTap: _checkLink,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Nothing in your inbox? Check spam, and make sure the address is spelled correctly. If the address does not exist, the email can never arrive.",
                        style: AppText.body(12.5,
                            color: AppColors.muted, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: AppText.body(13.5,
                      color: AppColors.danger, height: 1.4)),
            ],
            if (_info != null) ...[
              const SizedBox(height: 14),
              Text(_info!,
                  textAlign: TextAlign.center,
                  style: AppText.body(13.5, color: AppColors.success)),
            ],

            const SizedBox(height: 22),
            TextButton(
              onPressed: _cooldown > 0 ? null : _resend,
              child: Text(
                _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend',
                style: AppText.body(14.5,
                    w: FontWeight.w600,
                    color: _cooldown > 0 ? AppColors.muted : p.b),
              ),
            ),
            TextButton(
              onPressed: () => context.read<AppState>().discardUnverified(),
              child: Text(
                'Wrong email? Start over',
                style: AppText.body(14, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingMail extends StatefulWidget {
  const _PulsingMail();

  @override
  State<_PulsingMail> createState() => _PulsingMailState();
}

class _PulsingMailState extends State<_PulsingMail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 112 + 14 * t,
          height: 112 + 14 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.a.withValues(alpha: 0.10 + 0.08 * t),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: p.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.a.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                size: 40, color: Colors.white),
          ),
        );
      },
    );
  }
}
