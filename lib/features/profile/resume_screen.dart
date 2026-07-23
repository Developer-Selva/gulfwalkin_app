import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../shared/theme/app_colors.dart';

class ResumeScreen extends StatefulWidget {
  final String? resumeUrl;
  const ResumeScreen({super.key, this.resumeUrl});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _loading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final url = widget.resumeUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resume',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: url == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No resume uploaded yet',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : Stack(
              // StackFit.expand gives SfPdfViewer bounded constraints on the
              // first layout pass, preventing its internal RenderTransform from
              // firing the 'hasSize' assertion before it has been laid out.
              fit: StackFit.expand,
              children: [
                SfPdfViewer.network(
                  url,
                  onDocumentLoaded: (_) => setState(() => _loading = false),
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _loading = false;
                      _error = details.description;
                    });
                  },
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          const Text(
                            'Could not load PDF',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _loading = true;
                              _error = null;
                            }),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
