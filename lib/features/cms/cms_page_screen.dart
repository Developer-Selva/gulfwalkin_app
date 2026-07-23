import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_state.dart';

final _cmsPageProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, slug) async {
  final res = await ref.read(dioProvider).get('/cms/$slug');
  return res.data as Map<String, dynamic>;
});

class CmsPageScreen extends ConsumerWidget {
  final String slug;
  const CmsPageScreen({super.key, required this.slug});

  static const _titles = {
    'about':   'About Us',
    'terms':   'Terms & Conditions',
    'privacy': 'Privacy Policy',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title   = _titles[slug] ?? slug;
    final pageAsync = ref.watch(_cmsPageProvider(slug));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: pageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Could not load this page',
          onRetry: () => ref.invalidate(_cmsPageProvider(slug)),
        ),
        data: (page) {
          final content = page['content'] as String? ?? '';
          final cleaned = _stripHtml(content);
          if (cleaned.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.article_outlined,
                          size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Content coming soon',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This page is being prepared.\nCheck back soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              cleaned,
              style: const TextStyle(
                fontSize: 14,
                height: 1.75,
                color: AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'&lt;'), '<')
      .replaceAll(RegExp(r'&gt;'), '>')
      .replaceAll(RegExp(r'&nbsp;'), ' ')
      .trim();
}
