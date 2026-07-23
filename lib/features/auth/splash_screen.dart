import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1 — logo entrance
  late final AnimationController _entranceCtrl;
  late final Animation<double> _bgCircleScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  // Phase 2 — shimmer sweep
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // White card pops in (0–30 %)
    _bgCircleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Logo fades in (15–50 %)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo springs to full size with elastic overshoot (0–65 %)
    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    // Text slides up and fades in (45–80 %)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
      ),
    );

    // Shimmer sweeps left→right after entrance completes
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _shimmer = Tween<double>(begin: -1.8, end: 2.2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward().then((_) => _shimmerCtrl.forward());
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;

    final auth = ref.read(authProvider).valueOrNull;
    if (auth != null && auth.isAuthenticated) {
      context.go(auth.role == AuthRole.employer ? '/employer' : '/home');
      return;
    }

    final prefs = Hive.box('app_prefs');
    final onboardingDone =
        prefs.get('onboarding_done', defaultValue: false) as bool;
    context.go(onboardingDone ? '/login' : '/onboarding');
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.88),
                const Color(0xFF0D47A1),
              ],
            ),
          ),
          child: SizedBox.expand(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceCtrl, _shimmerCtrl]),
              builder: (_, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated logo ────────────────────────────────────────
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoFade.value.clamp(0.0, 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // White rounded card — scales in independently
                          Transform.scale(
                            scale: _bgCircleScale.value,
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 36,
                                    offset: const Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Logo image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 104,
                              height: 104,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Shimmer sweep overlay
                          ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: SizedBox(
                              width: 136,
                              height: 136,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(_shimmer.value - 0.7, -1),
                                    end: Alignment(_shimmer.value + 0.5, 1),
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.38),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Brand text ────────────────────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _textFade.value.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Gulfwalkin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your career abroad starts here',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
