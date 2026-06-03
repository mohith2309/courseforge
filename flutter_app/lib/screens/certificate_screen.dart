import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// In-app certificate. The planned `generateCertificate` Cloud Function would
/// render this to PDF server-side and email it; here we present the verifiable
/// credential with a QR that encodes its verification URL.
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final certId =
        'CF-${course.id.toUpperCase()}-${DateTime.now().year}';
    final verifyUrl = 'https://courseforge.app/verify/$certId';
    final date = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Container(
            padding: const EdgeInsets.all(Gap.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium,
                    size: 56, color: AppColors.accent),
                const SizedBox(height: Gap.sm),
                const Text('CERTIFICATE OF COMPLETION',
                    style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
                const SizedBox(height: Gap.lg),
                const Text('This certifies that',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: Gap.sm),
                const Text('CourseForge Learner',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: Gap.md),
                const Text('has successfully completed',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: Gap.sm),
                Text(course.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark)),
                const SizedBox(height: Gap.lg),
                QrImageView(
                  data: verifyUrl,
                  size: 110,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: Gap.sm),
                Text(certId,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                Text(
                  'Issued ${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'PDF export runs via the certificate Cloud Function in production.')),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shared to LinkedIn (demo).')),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
