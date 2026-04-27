import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../providers/firebase_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/validators.dart';

class EditAdminProfileScreen extends ConsumerStatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  ConsumerState<EditAdminProfileScreen> createState() =>
      _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends ConsumerState<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _initialized = false;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  bool _removePhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not pick image: $e');
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_removePhoto) {
      return '';
    }

    if (_selectedImageBytes == null) {
      return ref.read(userProvider)?.profileImageUrl;
    }

    final storage = ref.read(firebaseStorageProvider);
    final path =
        '${AppConstants.profileImagesPath}/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageRef = storage.ref().child(path);

    await imageRef.putData(
      _selectedImageBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return imageRef.getDownloadURL();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider);
    if (user == null) {
      _showMessage('Please sign in before updating your profile.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageUrl = await _uploadProfileImage(user.userId);

      await ref.read(userServiceProvider).updateUserProfile(
            user.userId,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            profileImageUrl: imageUrl,
            metadata: {
              'city': _cityController.text.trim(),
              'address': _addressController.text.trim(),
            },
          );

      await ref.read(userProvider.notifier).refreshUser();

      if (mounted) {
        _showMessage('Admin profile updated.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (!_initialized && user != null) {
      _initialized = true;
      _nameController.text = user.fullName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _cityController.text = user.metadata['city'] ?? '';
      _addressController.text = user.metadata['address'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving ? const Text('Saving...') : const Text('Save'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor:
                                    AppColors.primaryRed.withAlpha(20),
                                backgroundImage: _selectedImageBytes != null
                                    ? MemoryImage(_selectedImageBytes!)
                                    : (!_removePhoto &&
                                            user.profileImageUrl != null &&
                                            user.profileImageUrl!.isNotEmpty)
                                        ? NetworkImage(user.profileImageUrl!)
                                        : null,
                                child: _selectedImageBytes == null &&
                                        (_removePhoto ||
                                            user.profileImageUrl == null ||
                                            user.profileImageUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.admin_panel_settings,
                                        size: 48,
                                        color: AppColors.primaryRed,
                                      )
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryRed,
                                child: IconButton(
                                  onPressed:
                                      _isSaving ? null : _pickProfileImage,
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _selectedImageBytes = null;
                                      _removePhoto = true;
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Photo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
