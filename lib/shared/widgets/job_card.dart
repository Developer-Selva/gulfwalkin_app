import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/models/job.dart';
import '../theme/app_colors.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onQuickApply;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onBookmark,
    this.onShare,
    this.onQuickApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logo(),
              const SizedBox(width: 12),
              Expanded(child: _info()),
              if (onBookmark != null) _bookmarkBtn(),
            ],
          ),
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
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              placeholder: (_, __) => _logoPlaceholder(),
              errorWidget: (_, __, ___) {
                // Employer logo failed — try the job's own image before giving up.
                if (url == logoUrl && imageUrl != null) {
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _logoPlaceholder(),
                    errorWidget: (_, __, ___) => _logoPlaceholder(),
                  );
                }
                return _logoPlaceholder();
              },
            )
          : _logoPlaceholder(),
    );
  }

  Widget _logoPlaceholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.business, color: AppColors.textHint),
      );

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + posted time ──────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                job.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _postedAgo(job.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),

        // ── Company ──────────────────────────────────────────────────────
        if (job.employer != null) ...[
          const SizedBox(height: 2),
          Text(
            job.employer!.companyName,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 6),

        // ── Location ─────────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${job.location}, ${job.country}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // ── Salary ───────────────────────────────────────────────────────
        if (job.salaryRange != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 13, color: AppColors.secondary),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  job.salaryRange!,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // ── Status chips ─────────────────────────────────────────────────
        if (_isNew(job.createdAt) || _closingDays(job.deadline) != null) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              if (_isNew(job.createdAt))
                const _Chip(label: 'New', color: Color(0xFF2E7D32), icon: Icons.fiber_new_rounded),
              if (_closingDays(job.deadline) case final int days)
                _Chip(
                  label: days == 0 ? 'Closes today' : 'Closes in $days day${days == 1 ? '' : 's'}',
                  color: AppColors.warning,
                  icon: Icons.timer_outlined,
                ),
            ],
          ),
        ],

        // ── Action buttons (Share icon + Quick Apply) ────────────────────
        if (onShare != null || onQuickApply != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (onShare != null) ...[
                SizedBox(
                  width: 36,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onShare,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Icon(Icons.share_outlined,
                        size: 15, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: job.hasApplied
                      ? FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle_outline, size: 13),
                          label: const Text('Applied'),
                          style: FilledButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBackgroundColor:
                                AppColors.secondary.withValues(alpha: 0.15),
                            disabledForegroundColor: AppColors.secondary,
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: onQuickApply,
                          icon: const Icon(Icons.send_rounded, size: 13),
                          label: const Text('Quick Apply'),
                          style: FilledButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _bookmarkBtn() {
    return IconButton(
      onPressed: onBookmark,
      icon: Icon(
        job.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
        color: job.isBookmarked ? AppColors.primary : AppColors.textHint,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  static String _postedAgo(String iso) {
    try {
      final posted = DateTime.parse(iso).toLocal();
      final diff   = DateTime.now().difference(posted);
      if (diff.inHours < 6)  return 'Just now';
      if (diff.inHours < 24) return 'Today';
      if (diff.inDays == 1)  return '1 day ago';
      if (diff.inDays < 7)   return '${diff.inDays} days ago';
      if (diff.inDays < 14)  return '1 week ago';
      if (diff.inDays < 30)  return '${(diff.inDays / 7).floor()} weeks ago';
      if (diff.inDays < 60)  return '1 month ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (_) {
      return '';
    }
  }

  static bool _isNew(String iso) {
    try {
      return DateTime.now().difference(DateTime.parse(iso).toLocal()).inHours < 48;
    } catch (_) {
      return false;
    }
  }

  // Returns days until deadline if within 3 days, otherwise null.
  static int? _closingDays(String? deadline) {
    if (deadline == null) return null;
    try {
      final diff = DateTime.parse(deadline).difference(DateTime.now());
      if (diff.isNegative || diff.inDays > 3) return null;
      return diff.inDays;
    } catch (_) {
      return null;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
