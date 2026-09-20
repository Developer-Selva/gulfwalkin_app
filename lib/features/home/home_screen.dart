import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/auth/current_user_provider.dart';
import '../../core/models/advertisement.dart';
import '../../core/models/category.dart';
import '../../core/models/employee.dart';
import '../../core/models/job.dart';
import '../../core/models/top_company.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/job_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../jobs/recently_viewed_provider.dart';
import '../notifications/notifications_provider.dart';
import 'home_provider.dart';
import 'recommended_jobs_provider.dart';
import 'top_companies_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
            user != null ? 'Hi, ${user.firstName} 👋' : 'Gulfwalkin',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          loading: () => const Text('Gulfwalkin'),
          error: (_, __) => const Text('Gulfwalkin'),
        ),
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const JobListSkeleton(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(homeDataProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeDataProvider);
            ref.invalidate(currentUserProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileRing(userAsync: userAsync),
              ),
              SliverToBoxAdapter(
                child: _ProfileNudgeCard(userAsync: userAsync),
              ),
              SliverToBoxAdapter(
                child: _SearchBar(),
              ),
              const SliverToBoxAdapter(child: _RecentlyViewedSection()),
              // ── Suggested Jobs (placed high so it's immediately visible)
              const SliverToBoxAdapter(child: _RecommendedJobsSection()),
              if (data.ads.isNotEmpty)
                SliverToBoxAdapter(
                  child: _AdsBanner(ads: data.ads),
                ),
              const SliverToBoxAdapter(child: _StatsStrip()),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Categories',
                  onSeeAll: () => context.go('/jobs'),
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoriesRow(categories: data.categories),
              ),

              // ── Top Companies ─────────────────────────────────────────
              const SliverToBoxAdapter(child: _TopCompaniesSection()),

              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Latest Jobs',
                  onSeeAll: () => context.go('/jobs'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      for (final job in data.recentJobs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: JobCard(
                            job: job,
                            onTap: () => context.push('/jobs/${job.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile completion ring ──────────────────────────────────────────────────

class _ProfileRing extends ConsumerWidget {
  final AsyncValue<Employee?> userAsync;
  const _ProfileRing({required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final score = user.profileScore;
        final pct   = score / 100;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 38,
                lineWidth: 6,
                percent: pct,
                center: Text('$score%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                progressColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile ${user.profileLabel ?? 'Incomplete'}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      score < 100
                          ? 'Complete your profile to get more visibility'
                          : 'Your profile is complete!',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.go('/profile'),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: SkeletonBox(width: double.infinity, height: 90),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/jobs'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textHint),
            SizedBox(width: 10),
            Text('Search jobs, companies...', style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ─── Ads banner carousel ──────────────────────────────────────────────────────

class _AdsBanner extends StatefulWidget {
  final List<Advertisement> ads;
  const _AdsBanner({required this.ads});

  @override
  State<_AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<_AdsBanner> {
  int _current = 0;
  final _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.ads.length,
            itemBuilder: (_, i) {
              final ad = widget.ads[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surfaceVariant,
                ),
                clipBehavior: Clip.antiAlias,
                child: ad.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: ad.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => _adPlaceholder(ad),
                      )
                    : _adPlaceholder(ad),
              );
            },
          ),
        ),
        if (widget.ads.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ads.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _adPlaceholder(Advertisement ad) => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ad.company != null)
              Text(ad.company!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (ad.offerTitle != null)
              Text(ad.offerTitle!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
        ],
      ),
    );
  }
}

// ─── Categories horizontal row ────────────────────────────────────────────────

class _CategoriesRow extends StatelessWidget {
  final List<Category> categories;
  const _CategoriesRow({required this.categories});

  // Fallback color palette when the API doesn't supply a hex color.
  static const _fallbackColors = [
    Color(0xFF1565C0), Color(0xFF00897B), Color(0xFFF57C00),
    Color(0xFF7B1FA2), Color(0xFFC62828), Color(0xFF00838F),
  ];

  static Color _colorFor(String? hex, int index) {
    if (hex != null && hex.startsWith('#')) {
      try {
        return Color(int.parse('0xFF${hex.substring(1)}'));
      } catch (_) {}
    }
    return _fallbackColors[index % _fallbackColors.length];
  }

  // Maps category names to specific Material icons.
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('oil') || n.contains('gas') || n.contains('petro')) { return Icons.local_fire_department_rounded; }
    if (n.contains('engineer') || n.contains('construct')) { return Icons.construction_rounded; }
    if (n.contains('hvac') || n.contains('mep')) { return Icons.hvac_rounded; }
    if (n.contains('information') || n.contains('tech') || n.contains('telecom')) { return Icons.computer_rounded; }
    if (n.contains('medical') || n.contains('health')) { return Icons.local_hospital_rounded; }
    if (n.contains('hospitality') || n.contains('hotel') || n.contains('tourism') || n.contains('travel')) { return Icons.hotel_rounded; }
    if (n.contains('logistic') || n.contains('transport')) { return Icons.local_shipping_rounded; }
    if (n.contains('bank') || n.contains('financial')) { return Icons.account_balance_rounded; }
    if (n.contains('teach') || n.contains('education')) { return Icons.school_rounded; }
    if (n.contains('defense') || n.contains('security')) { return Icons.security_rounded; }
    if (n.contains('retail') || n.contains('hypermarket') || n.contains('showroom')) { return Icons.store_rounded; }
    if (n.contains('production') || n.contains('manufacturing')) { return Icons.factory_rounded; }
    if (n.contains('food') || n.contains('beverage')) { return Icons.restaurant_rounded; }
    if (n.contains('textile') || n.contains('garment')) { return Icons.checkroom_rounded; }
    if (n.contains('automobile') || n.contains('auto')) { return Icons.directions_car_rounded; }
    if (n.contains('agriculture') || n.contains('plantation') || n.contains('farm')) { return Icons.grass_rounded; }
    if (n.contains('mining')) { return Icons.landscape_rounded; }
    if (n.contains('airport') || n.contains('airline')) { return Icons.flight_rounded; }
    if (n.contains('facility')) { return Icons.apartment_rounded; }
    if (n.contains('ship') || n.contains('marine')) { return Icons.directions_boat_rounded; }
    if (n.contains('power') || n.contains('energy') || n.contains('sub-station')) { return Icons.bolt_rounded; }
    if (n.contains('domestic')) { return Icons.home_rounded; }
    return Icons.work_outline_rounded;
  }

  // Shortens long slash-separated names: "Oil & Gas / Petrochemicals" → "Oil & Gas"
  static String _shortLabel(String name) {
    final parts = name.split('/');
    final first = parts.first.trim();
    return first.length <= 14 ? first : '${first.substring(0, 13)}…';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            for (int i = 0; i < categories.length; i++)
              _AnimatedCategoryCard(
                category: categories[i],
                color: _colorFor(categories[i].color, i),
                icon: _iconFor(categories[i].name),
                label: _shortLabel(categories[i].name),
                onTap: () => context.go(
                    '/jobs?category=${Uri.encodeComponent(categories[i].name)}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  final Category category;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AnimatedCategoryCard({
    required this.category,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 10),
          width: 80,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withValues(alpha: 0.18)
                : widget.color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.45 : 0.22),
              width: 1.2,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: widget.color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recommended Jobs section ─────────────────────────────────────────────────

class _RecommendedJobsSection extends ConsumerWidget {
  const _RecommendedJobsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendedJobsProvider);

    return async.when(
      loading: () => _shell(
        context,
        child: const SizedBox(
          height: 156,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SkeletonBox(width: 240, height: 156),
                SizedBox(width: 12),
                SkeletonBox(width: 240, height: 156),
                SizedBox(width: 12),
                SkeletonBox(width: 240, height: 156),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (jobs) {
        if (jobs.isEmpty) return const SizedBox.shrink();
        return _shell(
          context,
          child: SizedBox(
            height: 156,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (int i = 0; i < jobs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _RecommendedJobCard(
                      job: jobs[i],
                      onTap: () => context.push('/jobs/${jobs[i].id}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shell(BuildContext context, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suggested Jobs',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Based on your profile & activity',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _RecommendedJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const _RecommendedJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _logo(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.employer?.companyName ?? job.company ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.category,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${job.location}, ${job.country}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (job.salaryRange != null)
                  Text(
                    job.salaryRange!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    final logoUrl  = job.employer?.logoUrl;
    final imageUrl = job.image1Url;
    final url      = logoUrl ?? imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              width: 36, height: 36, fit: BoxFit.cover,
              errorWidget: (_, __, ___) {
                if (url == logoUrl && imageUrl != null) {
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 36, height: 36, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
                  );
                }
                return _placeholder();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.business, color: AppColors.textHint, size: 18),
      );
}

// ─── Top Companies section ────────────────────────────────────────────────────

class _TopCompaniesSection extends ConsumerWidget {
  const _TopCompaniesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topCompaniesProvider);

    return async.when(
      loading: () => _shell(
        child: const SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SkeletonBox(width: 80, height: 100),
                SizedBox(width: 12),
                SkeletonBox(width: 80, height: 100),
                SizedBox(width: 12),
                SkeletonBox(width: 80, height: 100),
                SizedBox(width: 12),
                SkeletonBox(width: 80, height: 100),
                SizedBox(width: 12),
                SkeletonBox(width: 80, height: 100),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (companies) {
        if (companies.isEmpty) return const SizedBox.shrink();
        return _shell(
          child: SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (int i = 0; i < companies.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _CompanyCard(company: companies[i], context: context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 8, 10),
          child: Text('Top Companies Hiring Now',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        child,
        const SizedBox(height: 4),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final TopCompany company;
  final BuildContext context;
  const _CompanyCard({required this.company, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => context.go('/jobs?company=${Uri.encodeComponent(company.companyName)}'),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: company.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: company.logoUrl!,
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              company.companyName,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '${company.activeJobs} job${company.activeJobs != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Icon(Icons.business,
      color: AppColors.textHint, size: 28);
}

// ─── Stats Strip ──────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1A6BB5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.public_rounded,
                  staticValue: '#1',
                  label: 'Gulf\nJob Portal',
                ),
              ),
              _VDivider(),
              Expanded(
                child: _StatItem(
                  icon: Icons.work_rounded,
                  counterEnd: 1000,
                  label: 'New\nJobs',
                ),
              ),
              _VDivider(),
              Expanded(
                child: _StatItem(
                  icon: Icons.business_rounded,
                  counterEnd: 3000,
                  label: 'Companies\nHiring',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(vertical: 16),
      );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String? staticValue;
  final int counterEnd;
  final String label;

  const _StatItem({
    required this.icon,
    required this.label,
    this.staticValue,
    this.counterEnd = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          if (staticValue != null)
            Text(
              staticValue!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            )
          else
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: counterEnd),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => Text(
                val >= counterEnd
                    ? '${_fmt(counterEnd)}+'
                    : '${_fmt(val)}+',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) => n >= 1000 ? '${n ~/ 1000},000' : '$n';
}

// ─── Profile completion nudge ─────────────────────────────────────────────────

class _ProfileNudgeCard extends StatelessWidget {
  final AsyncValue<Employee?> userAsync;
  const _ProfileNudgeCard({required this.userAsync});

  @override
  Widget build(BuildContext context) {
    return userAsync.whenOrNull(
          data: (user) {
            if (user == null || user.profileScore >= 60) return const SizedBox.shrink();
            // Find first incomplete section to surface a specific action.
            final sections = user.profileSections;
            final first = sections.cast<ProfileSection?>().firstWhere(
              (s) => s != null && s.earned < s.max,
              orElse: () => null,
            );
            if (first == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        first.hint,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Fix now',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            );
          },
        ) ??
        const SizedBox.shrink();
  }
}

// ─── Recently Viewed Jobs ─────────────────────────────────────────────────────

class _RecentlyViewedSection extends ConsumerWidget {
  const _RecentlyViewedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(recentlyViewedProvider);
    if (jobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Recently Viewed',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    ref.read(recentlyViewedProvider.notifier).clear(),
                child: const Text('Clear',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 136,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [for (final job in jobs) _RecentJobCard(job: job)],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentJobCard extends StatelessWidget {
  final Job job;
  const _RecentJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final logoUrl  = job.employer?.logoUrl;
    final imageUrl = job.image1Url;
    final url      = logoUrl ?? imageUrl;
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) {
                            if (url == logoUrl && imageUrl != null) {
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _logoFallback(),
                              );
                            }
                            return _logoFallback();
                          },
                        )
                      : _logoFallback(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.employer?.companyName ?? job.company ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${job.location}, ${job.country}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.business, color: AppColors.textHint, size: 16),
      );
}

