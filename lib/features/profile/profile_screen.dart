import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/employee.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_state.dart';
import 'profile_edit_sheet.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: profileAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeaderCard(profile: profile),
              const SizedBox(height: 12),
              _CompletionCard(profile: profile),
              const SizedBox(height: 12),
              _ResumeCard(profile: profile),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.person_outline_rounded,
                title: 'Basic Information',
                section: ProfileEditSection.basic,
                rows: [
                  _row('Name', profile.fullName),
                  _row('Email', profile.email),
                  _row('Phone', profile.phone),
                  _row('Mobile', profile.mobile),
                  _row('Gender', profile.gender),
                ],
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.work_outline_rounded,
                title: 'Career Profile',
                section: ProfileEditSection.career,
                rows: [
                  _row('Experience', profile.expYears != null ? '${profile.expYears} yrs' : null),
                  _row('Abroad Exp', profile.abroadExp != null ? '${profile.abroadExp} yrs' : null),
                  _row('Positions', profile.positions),
                  _row('Industry', profile.industry),
                  _row('Skills', profile.skills),
                  _row('Expected Salary', profile.expectedSalary),
                ],
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.location_on_outlined,
                title: 'Location',
                section: ProfileEditSection.location,
                rows: [
                  _row('Country', profile.country),
                  _row('State', profile.state),
                  _row('District', profile.district),
                  _row('Address', profile.address),
                ],
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.public_outlined,
                title: 'Work Preferences',
                section: ProfileEditSection.preferences,
                rows: [
                  _row('Work Location', profile.workLocation),
                  _row('Languages', profile.languages),
                  _row('Passport', profile.passport ? 'Yes' : 'No'),
                  _row('Driving Licence', profile.drivingLicence ? 'Yes' : 'No'),
                  _row('CV Searchable', profile.cvSearchable ? 'Yes' : 'No'),
                ],
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.info_outline_rounded,
                title: 'Additional Details',
                section: ProfileEditSection.additional,
                rows: [
                  _row('Date of Birth', profile.dateOfBirth),
                  _row('Education', profile.educationQualification),
                  _row('Marital Status', profile.maritalStatus),
                  _row('Nationality', profile.nationality),
                  _row('Training', profile.training),
                  _row('Certificates', profile.certificates),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String?> _row(String label, String? value) => {label: value};
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends ConsumerWidget {
  final Employee profile;
  const _HeaderCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: profile.photoUrl != null
                    ? CachedNetworkImageProvider(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.firstName.isNotEmpty
                            ? profile.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      )
                    : null,
              ),
              GestureDetector(
                onTap: () => _pickPhoto(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 5),
                Text(
                  '${profile.profileScore}% — ${profile.profileLabel ?? "Incomplete"}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 20, color: AppColors.primary),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    size: 20, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;

    if (!context.mounted) return;
    try {
      await ref
          .read(profileProvider.notifier)
          .uploadPhoto(File(xFile.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }
}

// ── Profile completion card ───────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final Employee profile;
  const _CompletionCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score    = profile.profileScore;
    final sections = profile.profileSections;
    final incomplete = sections.where((s) => s.earned < s.max).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Profile Strength',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$score / 100',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: _scoreColor(score),
            ),
          ),
          if (incomplete.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Complete these sections to improve your score:',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...incomplete.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.hint,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      Text('+${s.max - s.earned} pts',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFF3B82F6);
    if (score >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Resume card ───────────────────────────────────────────────────────────────

class _ResumeCard extends ConsumerWidget {
  final Employee profile;
  const _ResumeCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResume = profile.resumeUrl != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resume / CV',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      hasResume ? 'PDF uploaded' : 'No resume uploaded yet',
                      style: TextStyle(
                          fontSize: 12,
                          color: hasResume
                              ? AppColors.success
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasResume) ...[
                TextButton(
                  onPressed: () =>
                      context.push('/resume', extra: profile.resumeUrl),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View'),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _pickResume(context, ref),
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text(hasResume ? 'Replace' : 'Upload'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickResume(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;
    try {
      await ref
          .read(profileProvider.notifier)
          .uploadResume(File(result.files.single.path!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Resume uploaded! Extracting profile details in the background...'),
            duration: Duration(seconds: 5),
          ),
        );
        // Refresh once immediately so the resume card shows the new file,
        // then again after 10 s to pick up any auto-filled profile fields.
        ref.invalidate(profileProvider);
        Timer(const Duration(seconds: 10), () {
          ref.invalidate(profileProvider);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }
}

// ── Generic section card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final ProfileEditSection section;
  final List<Map<String, String?>> rows;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.section,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final filled = rows.where((r) => r.values.first != null).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProfileEditSheet(section: section),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filled.isEmpty)
            const Text('Not filled yet — tap ✏ to add',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint,
                    fontStyle: FontStyle.italic))
          else
            ...rows.where((r) => r.values.first != null).map((r) {
              final label = r.keys.first;
              final value = r.values.first!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
