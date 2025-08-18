import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/themed_card.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../data/models/user_profile.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile? initialProfile;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const ProfileForm({
    super.key,
    this.initialProfile,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();

  // Emergency contact
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyEmailController = TextEditingController();

  // Medical info
  final _medicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Therapy preferences
  final _communicationStyleController = TextEditingController();
  final _sessionFrequencyController = TextEditingController();
  final _goalsController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  List<String> _focusAreas = [];

  @override
  void initState() {
    super.initState();
    _populateForm();
  }

  void _populateForm() {
    if (widget.initialProfile != null) {
      final profile = widget.initialProfile!;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _usernameController.text = profile.username ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _addressController.text = profile.address ?? '';
      _occupationController.text = profile.occupation ?? '';
      _selectedDateOfBirth = profile.dateOfBirth;

      if (profile.emergencyContact != null) {
        _emergencyNameController.text = profile.emergencyContact!.name;
        _emergencyRelationshipController.text =
            profile.emergencyContact!.relationship;
        _emergencyPhoneController.text = profile.emergencyContact!.phone;
        _emergencyEmailController.text = profile.emergencyContact!.email ?? '';
      }

      if (profile.medicalInfo != null) {
        _medicalConditionsController.text = profile.medicalInfo!.conditions
            .join(', ');
        _medicationsController.text = profile.medicalInfo!.medications.join(
          ', ',
        );
        _allergiesController.text = profile.medicalInfo!.allergies.join(', ');
      }

      if (profile.therapyPreferences != null) {
        _communicationStyleController.text =
            profile.therapyPreferences!.communicationStyle ?? '';
        _sessionFrequencyController.text =
            profile.therapyPreferences!.sessionFrequency ?? '';
        _goalsController.text = profile.therapyPreferences!.goals ?? '';
        _focusAreas = List.from(profile.therapyPreferences!.focusAreas);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    _medicalConditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _communicationStyleController.dispose();
    _sessionFrequencyController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profileData = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'date_of_birth': _selectedDateOfBirth?.toIso8601String(),

        'emergency_contact': {
          'name': _emergencyNameController.text.trim(),
          'relationship': _emergencyRelationshipController.text.trim(),
          'phone': _emergencyPhoneController.text.trim(),
          'email': _emergencyEmailController.text.trim(),
        },

        'medical_info': {
          'conditions':
              _medicalConditionsController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
          'medications':
              _medicationsController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
          'allergies':
              _allergiesController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
        },

        'therapy_preferences': {
          'communication_style': _communicationStyleController.text.trim(),
          'session_frequency': _sessionFrequencyController.text.trim(),
          'focus_areas': _focusAreas,
          'goals': _goalsController.text.trim(),
        },
      };

      widget.onSave(profileData);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information
          _buildSectionHeader('Basic Information', Icons.person),
          ThemedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text:
                                    _selectedDateOfBirth != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(_selectedDateOfBirth!)
                                        : '',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Information
          _buildSectionHeader('Contact Information', Icons.contact_phone),
          ThemedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency Contact
          _buildSectionHeader('Emergency Contact', Icons.emergency),
          ThemedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Contact name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyRelationshipController,
                          decoration: const InputDecoration(
                            labelText: 'Relationship *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Relationship is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Medical Information
          _buildSectionHeader('Medical Information', Icons.medical_services),
          ThemedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _medicalConditionsController,
                    decoration: const InputDecoration(
                      labelText: 'Medical Conditions (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Anxiety, Depression',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicationsController,
                    decoration: const InputDecoration(
                      labelText: 'Current Medications (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Prozac, Xanax',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Penicillin, Latex',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Therapy Preferences
          _buildSectionHeader('Therapy Preferences', Icons.psychology),
          ThemedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _communicationStyleController,
                          decoration: const InputDecoration(
                            labelText: 'Communication Style',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Direct, Gentle',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _sessionFrequencyController,
                          decoration: const InputDecoration(
                            labelText: 'Session Frequency',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Weekly, Bi-weekly',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _goalsController,
                    decoration: const InputDecoration(
                      labelText: 'Therapy Goals',
                      border: OutlineInputBorder(),
                      hintText: 'What do you hope to achieve?',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryGradientButton(
                  onPressed: _saveProfile,
                  child: Text(
                    widget.initialProfile != null
                        ? 'Update Profile'
                        : 'Save Profile',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryViolet, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryViolet,
            ),
          ),
        ],
      ),
    );
  }
}
