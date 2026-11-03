import 'package:flutter/material.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'form_widgets.dart';

/// Public legal pages, published with the admin site on Netlify.
abstract final class LegalLinks {
  static const _site = 'https://patastay.netlify.app';
  static final privacy = Uri.parse('$_site/privacy/');
  static final terms = Uri.parse('$_site/terms/');
  static final deleteAccount = Uri.parse('$_site/delete-account/');
}

/// Opens a legal page in the browser, or says where to find it.
Future<void> openLegalPage(BuildContext context, Uri page) async {
  var opened = false;
  try {
    opened = await launchUrl(page, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened && context.mounted) context.showMessage('Could not open the browser. Visit $page');
}

/// "Privacy policy · Terms of use" text links.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(onPressed: () => openLegalPage(context, LegalLinks.privacy), child: const Text('Privacy policy')),
        Text('·', style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText)),
        TextButton(onPressed: () => openLegalPage(context, LegalLinks.terms), child: const Text('Terms of use')),
      ],
    );
  }
}
