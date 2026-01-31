import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:hiddify/core/core.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy & Terms')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_rounded,
              content: '''
We value your privacy and are committed to protecting your personal data. This application does not collect, store, or share any personal identifiable information (PII) without your explicit consent.

1. **Data Collection**: We do not log your browsing history, traffic data, or DNS queries on our servers. All traffic regular routing is done locally or through the proxy servers you configure.
2. **Crash Reports**: Anonymous crash reports may be sent to help us improve stability if you opt-in.
3. **Permissions**: We only request permissions necessary for the app to function (e.g., VPN Service, Notifications, Camera for QR scanning).
              ''',
            ),
            Gap(24),
            _Section(
              title: 'Terms of Service',
              icon: Icons.description_rounded,
              content: '''
By using this application, you agree to the following terms:

1. **Lawful Use**: You agree to use this application only for lawful purposes. You are responsible for ensuring your use complies with local laws and regulations.
2. **No Warranty**: This software is provided "as is", without warranty of any kind, express or implied.
3. **Liability**: The developers are not liable for any damages arising from the use of this software.
              ''',
            ),
            Gap(24),
            _Section(
              title: 'Security',
              icon: Icons.security_rounded,
              content: '''
This application uses state-of-the-art encryption standards to secure your connection. 
- All local data is stored securely on your device.
- We recommend keeping the application updated to the latest version for the best security.
              ''',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, icon: icon),
        const Gap(8),
        Text(
          content.trim(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}
