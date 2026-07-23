import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../shared/theme/app_colors.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otp     = ValueNotifier<String>('');
  bool _loading  = false;
  bool _resending = false;
  String? _error;

  Future<void> _verify() async {
    if (_otp.value.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioProvider).post('/auth/otp/verify', data: {
        'email': widget.email,
        'otp':   _otp.value,
      });
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      setState(() => _error = handleDioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await ref.read(dioProvider).post('/auth/otp/send', data: {'email': widget.email});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New OTP sent to your email')),
      );
    } on DioException catch (e) {
      setState(() => _error = handleDioError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Check your email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Error banner
              if (_error != null) ...[
                Container(
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
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              // 6-box OTP input
              _OtpBoxes(onChanged: (v) => _otp.value = v),
              const SizedBox(height: 32),

              // Verify button
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Verify Code'),
              ),
              const SizedBox(height: 20),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code?",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(width: 4),
                  _resending
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _resend,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Resend',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 6-Box OTP Input ───────────────────────────────────────────────────────────

class _OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpBoxes({required this.onChanged});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _ctrls  = List.generate(6, (_) => TextEditingController());
  final _foci   = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _foci) { f.dispose(); }
    super.dispose();
  }

  String get _value => _ctrls.map((c) => c.text).join();

  void _onChanged(String val, int i) {
    // Handle paste of 6 digits into first box
    if (val.length == 6 && i == 0) {
      for (int j = 0; j < 6; j++) {
        _ctrls[j].text = val[j];
      }
      _foci[5].requestFocus();
      widget.onChanged(_value);
      return;
    }

    if (val.isNotEmpty && i < 5) {
      _foci[i + 1].requestFocus();
    }
    widget.onChanged(_value);
  }

  void _onKey(KeyEvent event, int i) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[i].text.isEmpty &&
        i > 0) {
      _foci[i - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) => _onKey(e, i),
            child: TextFormField(
              controller: _ctrls[i],
              focusNode: _foci[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: i == 0 ? 6 : 1, // allow paste in first box
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              onChanged: (v) => _onChanged(v, i),
            ),
          ),
        );
      }),
    );
  }
}
