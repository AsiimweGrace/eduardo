import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme.dart';
import '../widgets.dart';
import '../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String _userName = 'Farmer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users').child(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _userName = data['name'] ?? 'Farmer';
        });
      } else if (user.displayName != null) {
        setState(() {
          _userName = user.displayName!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n?.home ?? 'Home',
      currentIndex: 0,
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
          onPressed: () async {
            await _auth.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/auth');
            }
          },
        )
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n?.welcome ?? 'Welcome'} $_userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SmallCard(
                    child: Row(
                      children: [
                        const ProgressRing(
                            value: 0.78, size: 64, label: 'Health'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n?.currentDiagnosis ?? 'Field Health',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('Average across plots',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SmallCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n?.weatherAdvisory ?? 'Weather Risk',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                            value: 0.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryDark),
                            backgroundColor: AppColors.bg),
                        const SizedBox(height: 8),
                        Text('Moderate risk next 48h',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.camera_alt,
                    label: l10n?.scan ?? 'Scan',
                    color: AppColors.primaryDark,
                    onTap: () => Navigator.pushNamed(context, '/scan'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.agriculture,
                    label: 'My Farms',
                    color: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/farms'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.calendar_today,
                    label: l10n?.harvestingAdvice ?? 'Calendar',
                    color: AppColors.accent,
                    textColor: Colors.black87,
                    onTap: () => Navigator.pushNamed(context, '/calendar'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.menu_book,
                    label: l10n?.viewDictionary ?? 'Dictionary',
                    color: AppColors.primaryLight,
                    onTap: () => Navigator.pushNamed(context, '/dictionary'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n?.scanHistory ?? 'Recent Advisories',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return SmallCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.health_and_safety, color: Colors.white),
                    ),
                    title: const Text('Fungicide: Black Sigatoka'),
                    subtitle: const Text('Apply in 3 days — 70% confidence'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/advisory'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
