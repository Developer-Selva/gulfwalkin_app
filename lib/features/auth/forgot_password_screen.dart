import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../shared/theme/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();

  int _step     = 0; // 0 = email, 1 = otp + new password
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioProvider).post('/auth/otp/send',
          data: {'email': _emailCtrl.text.trim()});
      setState(() => _step = 1);
    } on DioException catch (e) {
      setState(() => _error = handleDioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_otpCtrl.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_passCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioProvider).post('/auth/password/reset', data: {
        'email':                 _emailCtrl.text.trim(),
        'otp':                   _otpCtrl.text,
        'password':              _passCtrl.text,
        'password_confirmation': _confCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please sign in.')),
      );
      context.go('/login');
    } on DioException catch (e) {
      setState(() => _error = handleDioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _EmailStep(key: const ValueKey(0), onSend: _sendOtp,
                    ctrl: _emailCtrl, loading: _loading, error: _error)
                : _ResetStep(key: const ValueKey(1), onReset: _resetPassword,
                    email: _emailCtrl.text.trim(),
                    otpCtrl: _otpCtrl, passCtrl: _passCtrl, confCtrl: _confCtrl,
                    loading: _loading, error: _error, obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure)),
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Enter email ───────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool loading;
  final String? error;

  const _EmailStep({
    super.key,
    required this.ctrl,
    required this.onSend,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_outlined,
              size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text('Reset your password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address and we\'ll send you a one-time code to reset your password.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
        if (error != null) _ErrorBanner(error!),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : onSend,
          child: loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send OTP'),
        ),
      ],
    );
  }
}

// ── Step 2: OTP + new password ────────────────────────────────────────────────

class _ResetStep extends StatelessWidget {
  final String email;
  final TextEditingController otpCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confCtrl;
  final VoidCallback onReset;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? error;

  const _ResetStep({
    super.key,
    required this.email,
    required this.otpCtrl,
    required this.passCtrl,
    required this.confCtrl,
    required this.onReset,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 32, color: AppColors.success),
        ),
        const SizedBox(height: 20),
        const Text('Enter the code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Code sent to '),
              TextSpan(
                text: email,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (error != null) _ErrorBanner(error!),
        TextFormField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '6-digit OTP',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: passCtrl,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: confCtrl,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onReset(),
          decoration: const InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : onReset,
          child: loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ],
        ),
      );
}
