import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:lifelink_blood/config/theme.dart';
import 'package:lifelink_blood/config/routes.dart';
import 'package:lifelink_blood/models/enums.dart';
import 'package:lifelink_blood/models/donor/donor_model.dart';
import 'package:lifelink_blood/providers/firebase_providers.dart';
import 'package:lifelink_blood/providers/user_provider.dart';
import 'package:lifelink_blood/providers/service_providers.dart';
import 'package:lifelink_blood/utils/validators.dart';

class DonorProfileSetupScreen extends ConsumerStatefulWidget {
  const DonorProfileSetupScreen({super.key});

  @override
  ConsumerState<DonorProfileSetupScreen> createState() => _DonorProfileSetupScreenState();
}

class _DonorProfileSetupScreenState extends ConsumerState<DonorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _cityController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  BloodGroup _selectedBloodGroup = BloodGroup.oPositive;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;

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
      setState(() => _selectedImageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImageBytes == null) return null;

    final storage = ref.read(firebaseStorageProvider);
    final path =
        'profile_images/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final refPath = storage.ref().child(path);

    await refPath.putData(
      _selectedImageBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return refPath.getDownloadURL();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(userProvider);
        if (user == null) return;

        final imageUrl = await _uploadProfileImage(user.userId);

        // Create donor record only if the user is a donor
        if (user.role == UserRole.donor) {
          final donor = DonorModel(
            donorId: user.userId, // Using userId as donorId for simplicity
            userId: user.userId,
            name: _nameController.text.trim(),
            email: user.email,
            phone: _phoneController.text.trim(),
            bloodGroup: _selectedBloodGroup,
            rhFactor: RhFactor.positive, // Default or add selector
            city: _cityController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            weight: double.parse(_weightController.text.trim()),
            profileImageUrl: imageUrl,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await ref.read(donorServiceProvider).createDonorProfile(donor);
        }

        // Update user profile status
        await ref.read(userServiceProvider).updateUserProfile(
          user.userId,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          profileImageUrl: imageUrl,
          profileCompleted: true,
          metadata: {
            if (user.role == UserRole.donor) 'bloodGroup': _selectedBloodGroup.displayName,
            'city': _cityController.text.trim(),
          },
        );

        // This would typically also create the Donor record in a real repository
        // For now, updating the user state is enough to pass the Splash check
        
        if (mounted) {
          if (user.role == UserRole.admin) {
            context.go(AppRoutes.adminHome);
          } else if (user.role == UserRole.requester) {
            context.go(AppRoutes.requesterHome);
          } else {
            context.go(AppRoutes.donorHome);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isDonor = user?.role == UserRole.donor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primaryRed.withAlpha(20),
                      backgroundImage: _selectedImageBytes != null
                          ? MemoryImage(_selectedImageBytes!)
                          : null,
                      child: _selectedImageBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.primaryRed,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryRed,
                      child: IconButton(
                        onPressed: _isLoading ? null : _pickProfileImage,
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Add Profile Photo',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Almost there! We need a few more details to set up your account.',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryRed.withAlpha(60)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.primaryRed, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dashboard access is locked until all required profile fields are saved. You can log out anytime.',
                        style: TextStyle(
                          color: AppColors.primaryRedDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
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
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              if (isDonor) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('Blood Group', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: BloodGroup.values.map((bg) {
                    final isSelected = _selectedBloodGroup == bg;
                    return ChoiceChip(
                      label: Text(bg.displayName),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedBloodGroup = bg),
                      selectedColor: AppColors.primaryRed.withAlpha(51),
                      checkmarkColor: AppColors.primaryRed,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
