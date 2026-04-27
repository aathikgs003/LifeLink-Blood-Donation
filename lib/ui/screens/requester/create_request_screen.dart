import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/enums.dart';
import '../../../models/request/blood_request_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/validators.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _hospitalNameController = TextEditingController();
  final _hospitalPhoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();

  int _currentStep = 0;
  BloodGroup _selectedBloodGroup = BloodGroup.oPositive;
  UrgencyLevel _selectedUrgency = UrgencyLevel.normal;
  String _selectedRelation = 'Self';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _unitsController.dispose();
    _hospitalNameController.dispose();
    _hospitalPhoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) {
      _showMessage('Please sign in before creating a request.');
      return;
    }

    setState(() => _isSubmitting = true);
    final now = DateTime.now();

    try {
      final request = BloodRequestModel(
        requestId: now.millisecondsSinceEpoch.toString(),
        userId: user.userId,
        patientName: _patientNameController.text.trim(),
        patientAge: int.parse(_ageController.text.trim()),
        bloodGroupRequired: _selectedBloodGroup,
        unitsRequired: int.parse(_unitsController.text.trim()),
        hospitalName: _hospitalNameController.text.trim(),
        hospitalPhone: _hospitalPhoneController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        urgencyLevel: _selectedUrgency,
        contactNumber: _contactNumberController.text.trim(),
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        metadata: {'relation': _selectedRelation},
      );

      await ref.read(requestServiceProvider).createRequest(request);

      if (mounted) {
        _showMessage('Blood request submitted.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage('Could not submit request: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Blood Request')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _isSubmitting
              ? null
              : () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _handleSubmit();
                  }
                },
          onStepCancel: _isSubmitting
              ? null
              : () {
                  if (_currentStep > 0) setState(() => _currentStep--);
                },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    onPressed: details.onStepContinue,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _currentStep == 2 ? 'Submit Request' : 'Continue'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Patient Info'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _patientNameController,
                    decoration: const InputDecoration(
                        labelText: 'Patient Name',
                        prefixIcon: Icon(Icons.person)),
                    validator: Validators.validateFullName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                        labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                    keyboardType: TextInputType.number,
                    validator: _requiredPositiveInt,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelation,
                    decoration: const InputDecoration(labelText: 'Relation'),
                    items: ['Self', 'Family', 'Friend', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRelation = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Blood Requirements'),
              isActive: _currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Blood Group',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
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
                  TextFormField(
                    controller: _unitsController,
                    decoration: const InputDecoration(
                        labelText: 'Units Required',
                        prefixIcon: Icon(Icons.bloodtype)),
                    keyboardType: TextInputType.number,
                    validator: _requiredPositiveInt,
                  ),
                  const SizedBox(height: 24),
                  const Text('Urgency Level',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: UrgencyLevel.values
                        .map((urgency) => ChoiceChip(
                              label: Text(urgency.displayName),
                              selected: _selectedUrgency == urgency,
                              onSelected: (val) => setState(
                                  () => _selectedUrgency = urgency),
                              selectedColor:
                                  urgency == UrgencyLevel.critical
                                      ? AppColors.error
                                      : (urgency == UrgencyLevel.urgent
                                          ? AppColors.warning
                                          : AppColors.success),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Hospital Details'),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  TextFormField(
                    controller: _hospitalNameController,
                    decoration: const InputDecoration(
                        labelText: 'Hospital Name',
                        prefixIcon: Icon(Icons.local_hospital)),
                    validator: _requiredText,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hospitalPhoneController,
                    decoration: const InputDecoration(
                        labelText: 'Hospital Phone',
                        prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: _requiredPhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(
                        labelText: 'Your Contact Number',
                        prefixIcon: Icon(Icons.contact_phone)),
                    keyboardType: TextInputType.phone,
                    validator: _requiredPhone,
                  ),
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
                    decoration:
                        const InputDecoration(labelText: 'Full Address'),
                    maxLines: 2,
                    validator: _requiredText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid number';
    return null;
  }

  String? _requiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return Validators.validatePhone(value);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
