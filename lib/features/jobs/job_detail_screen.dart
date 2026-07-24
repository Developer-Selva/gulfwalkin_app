import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/models/job.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'job_list_provider.dart';
import 'recently_viewed_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _jobDetailProvider =
    FutureProvider.autoDispose.family<Job, int>((ref, id) async {
  final res = await ref.read(dioProvider).get('/jobs/$id');
  return Job.fromJson(res.data as Map<String, dynamic>);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Strips HTML tags and converts common HTML elements to readable text.
String _htmlToText(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<\/li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\/h[1-6]>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<strong[^>]*>|<b[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<\/strong>|<\/b>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class JobDetailScreen extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool  _applyLoading    = false;
  bool  _bookmarkLoading = false;
  bool? _hasAppliedOverride;
  bool? _bookmarkedOverride;

  Future<void> _apply(Job job) async {
    final applied = _hasAppliedOverride ?? job.hasApplied;
    if (applied || _applyLoading) return;
    setState(() => _applyLoading = true);
    try {
      await ref.read(dioProvider).post('/jobs/${job.id}/apply');
      if (mounted) setState(() => _hasAppliedOverride = true);
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ApplyConfirmationSheet(job: job),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(handleDioError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applyLoading = false);
    }
  }

  Future<void> _toggleBookmark(Job job) async {
    if (_bookmarkLoading) return;
    final bookmarked = _bookmarkedOverride ?? job.isBookmarked;
    setState(() => _bookmarkLoading = true);
    try {
      if (bookmarked) {
        await ref.read(dioProvider).delete('/employee/bookmarks/${job.id}');
      } else {
        await ref.read(dioProvider).post('/employee/bookmarks/${job.id}');
      }
      ref.read(jobListProvider.notifier).toggleBookmark(job.id, !bookmarked);
      if (mounted) setState(() => _bookmarkedOverride = !bookmarked);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(handleDioError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_jobDetailProvider(widget.jobId));

    // Record this job as recently viewed the first time it loads successfully.
    ref.listen<AsyncValue<Job>>(_jobDetailProvider(widget.jobId), (prev, next) {
      if (next case AsyncData(:final value) when prev?.hasValue != true) {
        ref.read(recentlyViewedProvider.notifier).add(value);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: async.whenOrNull(
        data: (job) => _ApplyBar(
          job:     job.copyWith(hasApplied: _hasAppliedOverride ?? job.hasApplied),
          loading: _applyLoading,
          onApply: () => _apply(job),
        ),
      ),
      body: async.when(
        loading: () => const JobListSkeleton(),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_jobDetailProvider(widget.jobId)),
          ),
        ),
        data: (job) => _DetailBody(
          job:             job.copyWith(isBookmarked: _bookmarkedOverride ?? job.isBookmarked),
          bookmarkLoading: _bookmarkLoading,
          onBookmark:      () => _toggleBookmark(job),
        ),
      ),
    );
  }
}

// ─── Detail body ──────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final Job          job;
  final bool         bookmarkLoading;
  final VoidCallback onBookmark;

  const _DetailBody({
    required this.job,
    required this.bookmarkLoading,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_deadlineDays(job.deadline) case final int days) ...[
                  _ClosingSoonBanner(days: days),
                  const SizedBox(height: 12),
                ],
                _JobHeader(job: job),
                const SizedBox(height: 16),
                _QuickInfoRow(job: job),
                const SizedBox(height: 20),
                if (job.description != null) ...[
                  _ContentSection(
                    title: 'Job Description',
                    icon: Icons.description_outlined,
                    child: Text(
                      _htmlToText(job.description!),
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.requirements != null) ...[
                  _ContentSection(
                    title: 'Requirements',
                    icon: Icons.checklist_outlined,
                    child: Text(
                      _htmlToText(job.requirements!),
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.positions != null && job.positions!.isNotEmpty) ...[
                  _ContentSection(
                    title: 'Open Positions',
                    icon: Icons.work_outline,
                    child: Column(
                      children: job.positions!
                          .map((p) => _PositionRow(position: p))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.interviewInfo != null) ...[
                  _ContentSection(
                    title: 'Interview Info',
                    icon: Icons.info_outline,
                    child: Text(
                      _htmlToText(job.interviewInfo!),
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.employer != null) ...[
                  _EmployerCard(employer: job.employer!),
                  const SizedBox(height: 16),
                ],
                if (job.contactPhone != null || job.contactEmail != null) ...[
                  _ContactCard(job: job),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final hasImage = job.image1Url != null;
    return SliverAppBar(
      expandedHeight: hasImage ? 240 : 0,
      pinned:         true,
      elevation:      0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share job',
          onPressed: () => _shareJob(context),
        ),
        bookmarkLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: Icon(
                  job.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: job.isBookmarked ? AppColors.primary : null,
                ),
                onPressed: onBookmark,
              ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'report') _showReportSheet(context, job);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Report Job'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: hasImage
          ? FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openFullScreen(context, job.image1Url!),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: job.image1Url!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.surfaceVariant),
                    ),
                    // Gradient overlay for readability
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black26],
                        ),
                      ),
                    ),
                    // Tap-to-expand hint
                    Positioned(
                      right: 12, bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _openFullScreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImage(imageUrl: imageUrl),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _shareJob(BuildContext context) {
    final company = job.employer?.companyName ?? job.company;
    final buffer = StringBuffer();
    buffer.writeln(job.title);
    if (company != null) buffer.writeln(company);
    buffer.writeln('${job.location}, ${job.country}');
    if (job.salaryRange != null) buffer.writeln(job.salaryRange!);
    buffer.writeln();
    buffer.writeln('Apply on the Gulfwalkin App:');
    buffer.write('https://gulfwalkin.com/jobs/${job.id}');
    SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: job.title),
    );
  }

  void _showReportSheet(BuildContext context, Job job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportJobSheet(jobId: job.id),
    );
  }
}

// ─── Report Job sheet ─────────────────────────────────────────────────────────

class _ReportJobSheet extends ConsumerStatefulWidget {
  final int jobId;
  const _ReportJobSheet({required this.jobId});

  @override
  ConsumerState<_ReportJobSheet> createState() => _ReportJobSheetState();
}

class _ReportJobSheetState extends ConsumerState<_ReportJobSheet> {
  static const _reasons = {
    'fake_spam':      'Fake / Spam job',
    'misleading':     'Misleading information',
    'already_filled': 'Position already filled / closed',
    'inappropriate':  'Inappropriate content',
    'other':          'Other',
  };

  String _selected = 'fake_spam';
  final _detailsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(dioProvider).post(
        '/jobs/${widget.jobId}/report',
        data: {
          'reason':  _selected,
          if (_detailsCtrl.text.trim().isNotEmpty)
            'details': _detailsCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } on DioException catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleDioError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Report Job',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Why are you reporting this job?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          RadioGroup<String>(
            groupValue: _selected,
            onChanged: (v) { if (v != null) setState(() => _selected = v); },
            child: Column(
              children: _reasons.entries.map(
                (e) => InkWell(
                  onTap: () => setState(() => _selected = e.key),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Radio<String>(
                            value: e.key,
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(e.value,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Additional details (optional)',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _JobHeader extends StatelessWidget {
  final Job job;
  const _JobHeader({required this.job});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LogoBox(url: job.employer?.logoUrl ?? job.image1Url),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              if (job.employer != null) ...[
                const SizedBox(height: 4),
                Text(job.employer!.companyName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 8),
              _CategoryBadge(label: job.category),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoBox extends StatelessWidget {
  final String? url;
  const _LogoBox({this.url});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                width: 68, height: 68, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      );

  Widget _placeholder() => Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 30),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _QuickInfoRow extends StatelessWidget {
  final Job job;
  const _QuickInfoRow({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: '${job.location}, ${job.country}',
            color: AppColors.primary,
          ),
          if (job.salaryRange != null) ...[
            const Divider(height: 20),
            _InfoTile(
              icon: Icons.payments_outlined,
              label: 'Salary',
              value: job.salaryRange!,
              color: AppColors.secondary,
            ),
          ],
          const Divider(height: 20),
          _InfoTile(
            icon: Icons.people_outline,
            label: 'Vacancies',
            value: '${job.vacancies} position${job.vacancies != 1 ? 's' : ''} open',
            color: AppColors.primary,
          ),
          if (job.deadline != null) ...[
            const Divider(height: 20),
            _InfoTile(
              icon: Icons.event_outlined,
              label: 'Deadline',
              value: job.deadline!,
              color: AppColors.error,
            ),
          ],
          if (job.workingHours != null) ...[
            const Divider(height: 20),
            _InfoTile(
              icon: Icons.schedule_outlined,
              label: 'Working Hours',
              value: job.workingHours!,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}

class _ContentSection extends StatelessWidget {
  final String    title;
  final IconData  icon;
  final Widget    child;

  const _ContentSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _PositionRow extends StatelessWidget {
  final JobPosition position;
  const _PositionRow({required this.position});

  static const _colors = [
    Color(0xFF1565C0), Color(0xFF00897B), Color(0xFFF57C00),
    Color(0xFF7B1FA2), Color(0xFFC62828), Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[position.category.hashCode.abs() % _colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (position.vacancies != null)
                _pill('${position.vacancies} vacancy', color),
            ],
          ),
          if (position.salaryRange != null) ...[
            const SizedBox(height: 6),
            _pill(position.salaryRange!, color),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      );
}

class _EmployerCard extends StatelessWidget {
  final JobEmployer employer;
  const _EmployerCard({required this.employer});

  @override
  Widget build(BuildContext context) => _ContentSection(
        title: 'About the Employer',
        icon: Icons.business_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: employer.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: employer.logoUrl!,
                          width: 44, height: 44, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _logoPlaceholder(),
                        )
                      : _logoPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employer.companyName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (employer.country != null)
                        Text(employer.country!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if (employer.about != null) ...[
              const SizedBox(height: 12),
              Text(_htmlToText(employer.about!),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.55),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis),
            ],
            if (employer.website != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(employer.website!);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Row(
                  children: [
                    const Icon(Icons.language, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(employer.website!,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13,
                            decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _logoPlaceholder() => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.business, color: AppColors.primary, size: 20),
      );
}

class _ContactCard extends StatelessWidget {
  final Job job;
  const _ContactCard({required this.job});

  @override
  Widget build(BuildContext context) => _ContentSection(
        title: 'Contact',
        icon: Icons.contact_phone_outlined,
        child: Column(
          children: [
            if (job.contactPhone != null)
              _ContactTile(
                icon: Icons.phone_outlined,
                label: job.contactPhone!,
                onTap: () => launchUrl(Uri.parse('tel:${job.contactPhone}')),
              ),
            if (job.contactPhone != null && job.contactEmail != null)
              const SizedBox(height: 8),
            if (job.contactEmail != null)
              _ContactTile(
                icon: Icons.email_outlined,
                label: job.contactEmail!,
                onTap: () => launchUrl(Uri.parse('mailto:${job.contactEmail}')),
              ),
          ],
        ),
      );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
            ],
          ),
        ),
      );
}

// ─── Apply bar ────────────────────────────────────────────────────────────────

class _ApplyBar extends StatelessWidget {
  final Job job;
  final bool loading;
  final VoidCallback onApply;

  const _ApplyBar({required this.job, required this.loading, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final applied = job.hasApplied;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: applied
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                  label: const Text('Already Applied',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.success),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor:     Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Apply Now',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Full-screen image ────────────────────────────────────────────────────────

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}

// ─── Apply confirmation sheet ─────────────────────────────────────────────────

class _ApplyConfirmationSheet extends StatefulWidget {
  final Job job;
  const _ApplyConfirmationSheet({required this.job});

  @override
  State<_ApplyConfirmationSheet> createState() => _ApplyConfirmationSheetState();
}

class _ApplyConfirmationSheetState extends State<_ApplyConfirmationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.job.employer?.companyName ?? widget.job.company;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 8, 24, 24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Animated checkmark
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Applied Successfully!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.job.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (company != null) ...[
            const SizedBox(height: 3),
            Text(company,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),

          // Info pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Your profile has been sent to the employer.',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // CTA — view applications
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/applications');
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View My Applications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),

          // CTA — find more jobs
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Find More Jobs',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Closing-soon helpers ─────────────────────────────────────────────────────

// Returns days remaining if deadline is within 3 days (0 = today), else null.
int? _deadlineDays(String? deadline) {
  if (deadline == null) return null;
  try {
    final diff = DateTime.parse(deadline).difference(DateTime.now());
    if (diff.isNegative || diff.inDays > 3) return null;
    return diff.inDays;
  } catch (_) {
    return null;
  }
}

class _ClosingSoonBanner extends StatelessWidget {
  final int days;
  const _ClosingSoonBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    final label = days == 0 ? 'Closes today!' : 'Closing in $days day${days == 1 ? '' : 's'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Text(
            'Apply now before it\'s gone',
            style: TextStyle(color: AppColors.warning, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
