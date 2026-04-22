import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/ego_sms_service.dart';
import '../l10n/app_localizations.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final contacts = [
    _ContactItem('Plant Clinic', 'Diagnostic support and plant advice', Icons.local_florist, 'clinic@bananahealth.ai', '+254712345678'),
    _ContactItem('Frost Farms', 'Pest & soil health consultancy', Icons.eco, 'frost@bananahealth.ai', '+254722345678'),
    _ContactItem('Botanic Advisors', 'Crop optimization specialists', Icons.nature, 'info@botanicadv.com', '+254733345678'),
    _ContactItem('GreenNet', 'Field monitoring and advisory', Icons.cloud, 'help@greennet.ai', '+254744345678'),
  ];

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n?.contacts ?? 'Experts',
      showBottomNav: true,
      currentIndex: 2,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
          label: const Text(
            'Logout',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onPressed: _handleLogout,
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Contact Support', style: AppTextStyles.headingMedium),
                const Spacer(),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: AppColors.primaryPale.withValues(alpha: 0.3),
                  ),
                  onPressed: () {},
                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ContactCard(contact: contacts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem {
  final String name;
  final String details;
  final IconData icon;
  final String email;
  final String phone;

  _ContactItem(this.name, this.details, this.icon, this.email, this.phone);
}

class _ContactCard extends StatefulWidget {
  final _ContactItem contact;
  const _ContactCard({required this.contact});

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  final EgoSmsService _smsService = EgoSmsService.instance;
  bool _isSendingSms = false;

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showSmsDialog(BuildContext context) {
    final TextEditingController smsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.bg,
          title: Row(
            children: [
              const Icon(Icons.sms_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Message ${widget.contact.name}', style: AppTextStyles.subtitleSemiBold),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient: ${widget.contact.phone}', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              TextField(
                controller: smsController,
                maxLines: 4,
                decoration: AppDecorations.inputDecoration('Type your message...', Icons.edit_note),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (_isSendingSms)
                const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Sending...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSendingSms ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: _isSendingSms ? null : () async {
                if (smsController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a message')),
                  );
                  return;
                }
                
                setDialogState(() => _isSendingSms = true);
                
                final result = await _smsService.sendSms(
                  number: widget.contact.phone,
                  message: smsController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Send SMS'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.contact.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contact.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(widget.contact.details, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(widget.contact.phone, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _makeCall(widget.contact.phone),
            icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryPale,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _showSmsDialog(context),
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryPale,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
