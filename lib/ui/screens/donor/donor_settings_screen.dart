import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink_blood/config/routes.dart';
import 'package:lifelink_blood/config/theme.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/providers/user_provider.dart';

class DonorSettingsScreen extends ConsumerStatefulWidget {
  const DonorSettingsScreen({super.key});

  @override
  ConsumerState<DonorSettingsScreen> createState() =>
      _DonorSettingsScreenState();
}

class _DonorSettingsScreenState extends ConsumerState<DonorSettingsScreen> {
  bool _pushNotifications = true;
  bool _emergencyAlerts = true;
  bool _reminders = false;
  bool _showPhoneNumber = true;
  bool _profileVisible = true;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (!_initialized && user != null) {
      _initialized = true;
      _pushNotifications = _metadataBool(
          user.metadata['donorPushNotifications'], true);
      _emergencyAlerts =
          _metadataBool(user.metadata['donorEmergencyAlerts'], true);
      _reminders = _metadataBool(user.metadata['donorReminders'], false);
      _showPhoneNumber =
          _metadataBool(user.metadata['donorShowPhoneNumber'], true);
      _profileVisible =
          _metadataBool(user.metadata['donorProfileVisible'], true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: user == null || _isSaving ? null : _saveAllPreferences,
            child: _isSaving ? const Text('Saving...') : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        children: [
          _section('Account'),
          _tile(Icons.person_outline, 'Edit Profile',
              () => context.push(AppRoutes.editDonorProfile)),
          _tile(Icons.favorite_outline, 'Blood Drives',
              () => context.push(AppRoutes.donorBloodDrives)),
          _tile(Icons.notifications_none, 'Notification Center',
              () => context.push(AppRoutes.notificationCenter)),
          _tile(Icons.lock_outline, 'Change Password',
              () => context.push(AppRoutes.forgotPassword)),
          _tile(
              Icons.verified_user_outlined,
              'Verification Status',
              () => _showMessage(
                  'Your donor verification is marked as verified.'),
              trailing: 'Verified'),
          _section('Notifications'),
          _switchTile('Push Notifications', _pushNotifications,
              (value) => _updatePreference('donorPushNotifications', () {
                _pushNotifications = value;
                })),
          _switchTile('Emergency Alerts', _emergencyAlerts,
              (value) => _updatePreference('donorEmergencyAlerts', () {
                _emergencyAlerts = value;
                })),
          _switchTile('Reminders', _reminders,
              (value) => _updatePreference('donorReminders', () {
                _reminders = value;
                })),
          _section('Privacy'),
          _tile(Icons.visibility_off_outlined, 'Profile Visibility',
              () => _toggleProfileVisibility(),
              trailing: _profileVisible ? 'Public' : 'Hidden'),
          _tile(
              Icons.phone_paused_outlined,
              'Show Phone Number',
              () => _togglePhoneVisibility(),
              trailing: _showPhoneNumber ? 'Visible' : 'Hidden'),
          _section('Other'),
          _tile(
              Icons.help_outline,
              'Help & Support',
              () => _showInfoDialog('Help & Support',
                  'For urgent help, contact LifeLink support from your registered email.')),
          _tile(
              Icons.info_outline,
              'About LifeLink',
              () => _showInfoDialog('About LifeLink',
                  'LifeLink connects blood donors with requesters during emergencies.')),
          _tile(Icons.logout, 'Logout', () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) {
              context.go(AppRoutes.splash);
            }
          }, isDanger: true),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed)),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap,
      {String? trailing, bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDanger ? AppColors.error : AppColors.textTertiaryDark),
      title: Text(title,
          style: TextStyle(color: isDanger ? AppColors.error : null)),
      trailing: trailing != null
          ? Text(trailing,
              style: const TextStyle(color: AppColors.textTertiaryDark))
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _switchTile(String title, bool val, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: val,
      onChanged: _isSaving ? null : onChanged,
      activeThumbColor: AppColors.primaryRed,
    );
  }

  Future<void> _updatePreference(String key, VoidCallback updateState) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      updateState();
      _isSaving = true;
    });

    try {
      await ref.read(userServiceProvider).updateUserProfile(
            user.userId,
            metadata: {
              key: _getPreferenceValue(key).toString(),
            },
          );
      await ref.read(userProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) _showMessage('Could not save setting: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAllPreferences() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userServiceProvider).updateUserProfile(
            user.userId,
            metadata: {
              'donorPushNotifications': _pushNotifications.toString(),
              'donorEmergencyAlerts': _emergencyAlerts.toString(),
              'donorReminders': _reminders.toString(),
              'donorProfileVisible': _profileVisible.toString(),
              'donorShowPhoneNumber': _showPhoneNumber.toString(),
            },
          );
      await ref.read(userProvider.notifier).refreshUser();
      if (mounted) _showMessage('Settings saved.');
    } catch (e) {
      if (mounted) _showMessage('Could not save settings: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleProfileVisibility() {
    _updatePreference('donorProfileVisible', () {
      _profileVisible = !_profileVisible;
    });
  }

  void _togglePhoneVisibility() {
    _updatePreference('donorShowPhoneNumber', () {
      _showPhoneNumber = !_showPhoneNumber;
    });
  }

  bool _metadataBool(String? value, bool defaultValue) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  dynamic _getPreferenceValue(String key) {
    switch (key) {
      case 'donorPushNotifications':
        return _pushNotifications;
      case 'donorEmergencyAlerts':
        return _emergencyAlerts;
      case 'donorReminders':
        return _reminders;
      case 'donorProfileVisible':
        return _profileVisible;
      case 'donorShowPhoneNumber':
        return _showPhoneNumber;
      default:
        return false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
              child: const Text('Close')),
        ],
      ),
    );
  }
}
