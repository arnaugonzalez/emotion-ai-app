import 'package:flutter/material.dart';

class TermsDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const TermsDialog({
    super.key,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _hasReachedBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Processing Agreement and Privacy Policy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '1. Introduction\n\n'
                      'This Data Processing Agreement ("DPA") forms part of the Terms of Service between you and Emotion AI App. By using our application, you agree to the collection and processing of your personal data as described in this agreement.\n\n'
                      '2. GDPR Compliance\n\n'
                      'We are committed to complying with the General Data Protection Regulation (GDPR). This means we will:\n'
                      '• Process your data lawfully, fairly, and transparently\n'
                      '• Collect data for specified, explicit, and legitimate purposes\n'
                      '• Ensure data is adequate, relevant, and limited to what is necessary\n'
                      '• Keep data accurate and up to date\n'
                      '• Store data only as long as necessary\n'
                      '• Process data securely and protect against unauthorized processing\n\n'
                      '3. Data Sharing with OpenAI\n\n'
                      'As part of our service, we share certain data with OpenAI to provide AI-powered features. This includes:\n'
                      '• Text inputs you provide for emotional analysis\n'
                      '• Anonymized usage patterns\n'
                      '• Feedback and ratings\n\n'
                      'OpenAI processes this data in accordance with their privacy policy and security standards. In exchange for sharing this data, we receive testing tokens that help us improve our service.\n\n'
                      '4. Your Rights\n\n'
                      'Under GDPR, you have the following rights:\n'
                      '• Right to access your data\n'
                      '• Right to rectification\n'
                      '• Right to erasure ("right to be forgotten")\n'
                      '• Right to restrict processing\n'
                      '• Right to data portability\n'
                      '• Right to object\n'
                      '• Rights related to automated decision making\n\n'
                      '5. Data Storage\n\n'
                      'We store your data both locally on your device and in our secure cloud infrastructure. Local storage includes:\n'
                      '• Emotional records\n'
                      '• Breathing patterns and sessions\n'
                      '• User preferences and settings\n\n'
                      '6. Security Measures\n\n'
                      'We implement appropriate technical and organizational measures to ensure data security, including:\n'
                      '• Encryption of data in transit and at rest\n'
                      '• Access controls and authentication\n'
                      '• Regular security assessments\n'
                      '• Incident response procedures\n\n'
                      '7. Token Usage Limitations\n\n'
                      'To ensure fair usage of our AI features:\n'
                      '• Regular users are limited to 300,000 tokens per account\n'
                      '• Usage is monitored and tracked\n'
                      '• Limits may be adjusted based on service demands\n\n'
                      '8. Contact Information\n\n'
                      'For any privacy-related queries or to exercise your rights, contact us at:\n'
                      'privacy@emotionai.app\n\n'
                      '9. Updates to This Agreement\n\n'
                      'We may update this agreement from time to time. You will be notified of any material changes and may be required to accept the updated terms to continue using the service.\n\n'
                      '10. Acceptance\n\n'
                      'By accepting these terms, you acknowledge that you have read and understood this agreement and consent to the collection and processing of your data as described herein.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _hasReachedBottom ? widget.onAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _hasReachedBottom
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                  ),
                  child: const Text('Accept Terms'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
