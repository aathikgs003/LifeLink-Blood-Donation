import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _criticalAlerts = true;
  bool _twoFactorAuth = false;
  bool _auditAlerts = true;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (!_initialized && user != null) {
      _initialized = true;
      _pushNotifications = _metadataBool(user.metadata['adminPushNotifications'], true);
      _emailNotifications = _metadataBool(user.metadata['adminEmailNotifications'], true);
      _criticalAlerts = _metadataBool(user.metadata['adminCriticalAlerts'], true);
      _twoFactorAuth = _metadataBool(user.metadata['adminTwoFactorAuth'], false);
      _auditAlerts = _metadataBool(user.metadata['adminAuditAlerts'], true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          TextButton(
            onPressed: user == null || _isSaving ? null : _saveSettings,
            child: _isSaving ? const Text('Saving...') : const Text('Save'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _section('Account'),
                _tile(Icons.person_outline, 'My Profile',
                    () => context.push(AppRoutes.adminProfile)),
                _tile(Icons.edit_outlined, 'Edit Profile',
                    () => context.push(AppRoutes.editAdminProfile)),
                _tile(Icons.lock_reset_outlined, 'Change Password',
                    () => _sendPasswordReset(user.email)),

                _section('Notifications'),
                _switchTile('Push Notifications', _pushNotifications,
                    (v) => setState(() => _pushNotifications = v)),
                _switchTile('Email Notifications', _emailNotifications,
                    (v) => setState(() => _emailNotifications = v)),
                _switchTile('Critical Alerts', _criticalAlerts,
                    (v) => setState(() => _criticalAlerts = v)),

                _section('Security'),
                _switchTile('Two-factor Authentication', _twoFactorAuth,
                    (v) => setState(() => _twoFactorAuth = v)),
                _switchTile('Audit Alert Notifications', _auditAlerts,
                    (v) => setState(() => _auditAlerts = v)),

                _section('Quick Access'),
                _tile(Icons.people_outline, 'User Management',
                    () => context.push(AppRoutes.userManagement)),
                _tile(Icons.verified_user_outlined, 'Donor Verification',
                    () => context.push(AppRoutes.donorVerification)),
                _tile(Icons.monitor_heart_outlined, 'Request Monitoring',
                    () => context.push(AppRoutes.requestMonitoring)),
                _tile(Icons.analytics_outlined, 'Analytics',
                    () => context.push(AppRoutes.analytics)),

                _section('Support'),
                _tile(Icons.notifications_active_outlined, 'Notification Center',
                  () => context.push(AppRoutes.adminNotifications)),
                _tile(Icons.help_outline, 'Help & Support', () {
                  _showInfoDialog(
                    'Help & Support',
                    'For critical support, use the Notification Center or contact the LifeLink support team from your registered admin email.',
                  );
                }),
                _tile(Icons.info_outline, 'About LifeLink', () {
                  _showInfoDialog(
                    'About LifeLink',
                    'LifeLink connects blood donors and requesters in emergencies. Admin settings are synced to Firestore for this account.',
                  );
                }),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 8),
                _tile(Icons.logout, 'Logout', () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.splash);
                }, isDanger: true),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Future<void> _saveSettings() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userServiceProvider).updateUserProfile(
            user.userId,
            metadata: {
              'adminPushNotifications': _pushNotifications.toString(),
              'adminEmailNotifications': _emailNotifications.toString(),
              'adminCriticalAlerts': _criticalAlerts.toString(),
              'adminTwoFactorAuth': _twoFactorAuth.toString(),
              'adminAuditAlerts': _auditAlerts.toString(),
            },
          );

      await ref.read(userProvider.notifier).refreshUser();
      if (mounted) {
        _showMessage('Admin settings saved to Firestore.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not save settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        _showMessage('Password reset link sent to $email');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not send reset link: $e');
      }
    }
  }

  bool _metadataBool(String? value, bool defaultValue) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryRed,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap,
      {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDanger ? AppColors.error : AppColors.textTertiaryDark),
      title: Text(
        title,
        style: TextStyle(color: isDanger ? AppColors.error : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeThumbColor: AppColors.primaryRed,
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
