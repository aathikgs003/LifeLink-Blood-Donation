import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../providers/firebase_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/validators.dart';

class EditDonorProfileScreen extends ConsumerStatefulWidget {
  const EditDonorProfileScreen({super.key});

  @override
  ConsumerState<EditDonorProfileScreen> createState() =>
      _EditDonorProfileScreenState();
}

class _EditDonorProfileScreenState
    extends ConsumerState<EditDonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  BloodGroup _selectedBloodGroup = BloodGroup.oPositive;
  bool _initialized = false;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  bool _removePhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
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
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final weight = double.parse(_weightController.text.trim());
      final city = _cityController.text.trim();
      final address = _addressController.text.trim();
      final imageUrl = await _uploadProfileImage(user.userId);

      await ref.read(userServiceProvider).updateUserProfile(
        user.userId,
        fullName: name,
        profileImageUrl: imageUrl,
        metadata: {
          'bloodGroup': _selectedBloodGroup.displayName,
          'city': city,
          'age': age.toString(),
          'weight': weight.toString(),
          'address': address,
        },
      );

      final donor =
          await ref.read(donorServiceProvider).getDonorProfile(user.userId);
      if (donor != null) {
        await ref.read(donorServiceProvider).updateDonorProfile(
              donor.copyWith(
                name: name,
                bloodGroup: _selectedBloodGroup,
                city: city,
                address: address,
                age: age,
                weight: weight,
                profileImageUrl: imageUrl,
                updatedAt: DateTime.now(),
              ),
            );
      }

      await ref.read(userProvider.notifier).refreshUser();

      if (mounted) {
        _showMessage('Profile updated.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage('Could not update profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (!_initialized && user != null) {
      _initialized = true;
      _nameController.text = user.fullName ?? '';
      _ageController.text = user.metadata['age'] ?? '';
      _weightController.text = user.metadata['weight'] ?? '';
      _cityController.text = user.metadata['city'] ?? '';
      _addressController.text = user.metadata['address'] ?? '';
      _selectedBloodGroup = BloodGroup.fromString(
          user.metadata['bloodGroup'] ?? BloodGroup.oPositive.name);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                                radius: 50,
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
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              CircleAvatar(
                                backgroundColor: AppColors.primaryRed,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt,
                                      size: 18, color: Colors.white),
                                  onPressed:
                                      _isSaving ? null : _pickProfileImage,
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
                    const SizedBox(height: 32),
                    _sectionHeader('Personal Details'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Age'),
                            validator: Validators.validateAge,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Weight (kg)'),
                            validator: Validators.validateWeight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Blood Group'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: BloodGroup.values
                          .map((bg) => ChoiceChip(
                                label: Text(bg.displayName),
                                selected: _selectedBloodGroup == bg,
                                onSelected: (val) =>
                                    setState(() => _selectedBloodGroup = bg),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Location'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city)),
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
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

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
