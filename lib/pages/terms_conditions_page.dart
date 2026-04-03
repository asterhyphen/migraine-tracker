import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Acceptance of Terms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'By downloading and using Migraine Tracker, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Use License',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Permission is granted to use this app for personal, non-commercial purposes only.',
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Disclaimer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app is provided "as is" without warranties. We are not medical professionals, and this app is not a substitute for professional medical advice.',
            ),
            const SizedBox(height: 16),
            const Text(
              '4. Limitation of Liability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'In no event shall we be liable for any damages arising out of the use or inability to use this app.',
            ),
            const SizedBox(height: 16),
            const Text(
              '5. Changes to Terms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of the new terms.',
            ),
            const SizedBox(height: 16),
            const Text(
              '6. Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions about these Terms and Conditions, please contact AsterHyphen.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Developer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Developed by AsterHyphen. For more details, visit https://asterhyphen.xyz (redirect URL).',
            ),
          ],
        ),
      ),
    );
  }
}
