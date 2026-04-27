import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class RequesterSettingsScreen extends ConsumerStatefulWidget {
  const RequesterSettingsScreen({super.key});

  @override
  ConsumerState<RequesterSettingsScreen> createState() =>
      _RequesterSettingsScreenState();
}

class _RequesterSettingsScreenState extends ConsumerState<RequesterSettingsScreen> {
  bool _pushNotifications = true;
  bool _emergencyAlerts = true;
  bool _requestUpdates = true;
  bool _shareContact = true;
  bool _showProfile = true;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (!_initialized && user != null) {
      _initialized = true;
      _pushNotifications =
          _metadataBool(user.metadata['requesterPushNotifications'], true);
      _emergencyAlerts =
          _metadataBool(user.metadata['requesterEmergencyAlerts'], true);
      _requestUpdates =
          _metadataBool(user.metadata['requesterRequestUpdates'], true);
      _shareContact =
          _metadataBool(user.metadata['requesterShareContact'], true);
      _showProfile =
          _metadataBool(user.metadata['requesterShowProfile'], true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requester Settings'),
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
                    () => context.push(AppRoutes.requesterProfile)),
                _tile(Icons.edit_outlined, 'Edit Profile',
                    () => context.push(AppRoutes.editRequesterProfile)),
                _tile(Icons.history_outlined, 'Request History',
                    () => context.push(AppRoutes.requestHistory)),
                _tile(Icons.lock_reset_outlined, 'Change Password',
                    () => _sendPasswordReset(user.email)),

                _section('Notifications'),
                _switchTile('Push Notifications', _pushNotifications,
                    (v) => setState(() => _pushNotifications = v)),
                _switchTile('Emergency Alerts', _emergencyAlerts,
                    (v) => setState(() => _emergencyAlerts = v)),
                _switchTile('Request Status Updates', _requestUpdates,
                    (v) => setState(() => _requestUpdates = v)),

                _section('Privacy'),
                _switchTile('Share Contact With Accepted Donors', _shareContact,
                    (v) => setState(() => _shareContact = v)),
                _switchTile('Show Profile To Donors', _showProfile,
                    (v) => setState(() => _showProfile = v)),

                _section('Quick Access'),
                _tile(Icons.add_circle_outline, 'Create New Request',
                    () => context.push(AppRoutes.createRequest)),
                _tile(Icons.pending_actions_outlined, 'Active Requests',
                    () => context.push(AppRoutes.activeRequests)),
                _tile(Icons.notifications_active_outlined,
                    'Notification Center',
                    () => context.push(AppRoutes.notificationCenter)),

                _section('Support'),
                _tile(Icons.help_outline, 'Help & Support', () {
                  _showInfoDialog(
                    'Help & Support',
                    'For urgent blood support, use the request details page and contact accepted donors directly.',
                  );
                }),
                _tile(Icons.info_outline, 'About LifeLink', () {
                  _showInfoDialog(
                    'About LifeLink',
                    'LifeLink helps requesters and donors coordinate blood support in real time.',
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
              'requesterPushNotifications': _pushNotifications.toString(),
              'requesterEmergencyAlerts': _emergencyAlerts.toString(),
              'requesterRequestUpdates': _requestUpdates.toString(),
              'requesterShareContact': _shareContact.toString(),
              'requesterShowProfile': _showProfile.toString(),
            },
          );

      await ref.read(userProvider.notifier).refreshUser();
      if (mounted) {
        _showMessage('Requester settings saved to Firestore.');
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