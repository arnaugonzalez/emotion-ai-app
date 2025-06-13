import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/pin_code_screen.dart';
import '../terms/terms_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  final _jobController = TextEditingController();
  final _countryController = TextEditingController();
  String? _selectedPersonalityType;
  String? _selectedRelaxationTime;
  String? _selectedSelfcareFrequency;
  final List<String> _selectedRelaxationTools = [];
  bool? _hasPreviousMentalHealthAppExperience;
  String? _selectedTherapyChatHistoryPreference;
  bool _isLoading = false;
  bool _hasAcceptedTerms = false;
  bool _hasPinCode = false;

  final List<String> _personalityTypes = [
    'INTJ',
    'INTP',
    'ENTJ',
    'ENTP',
    'INFJ',
    'INFP',
    'ENFJ',
    'ENFP',
    'ISTJ',
    'ISFJ',
    'ESTJ',
    'ESFJ',
    'ISTP',
    'ISFP',
    'ESTP',
    'ESFP',
    'Not Sure',
  ];

  final List<String> _relaxationTimeOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Various times',
  ];

  final List<String> _selfcareFrequencyOptions = [
    'Multiple times a day',
    'Once a day',
    'Multiple times a week',
    'Once a week',
    'Rarely',
    'Almost never',
  ];

  final List<String> _relaxationToolOptions = [
    'Breathing exercises',
    'Binaural sounds',
    'Chatbot therapy',
    'Emotional calendar',
    'Meditation',
    'Exercise',
    'Reading',
    'Nature walks',
    'Music',
    'Creative activities',
  ];

  final List<String> _therapyChatHistoryOptions = [
    'Last week',
    'Last month',
    'No history needed',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _ageController.text = prefs.getString('user_age') ?? '';
      _selectedGender = prefs.getString('user_gender');
      _jobController.text = prefs.getString('user_job') ?? '';
      _countryController.text = prefs.getString('user_country') ?? '';
      _selectedPersonalityType = prefs.getString('user_personality_type');
      _selectedRelaxationTime = prefs.getString('user_relaxation_time');
      _selectedSelfcareFrequency = prefs.getString('user_selfcare_frequency');
      _hasAcceptedTerms = prefs.getBool('has_accepted_terms') ?? false;
      _hasPinCode = prefs.getString('user_pin_code') != null;

      if (prefs.getStringList('user_relaxation_tools') != null) {
        _selectedRelaxationTools.clear();
        _selectedRelaxationTools.addAll(
          prefs.getStringList('user_relaxation_tools')!,
        );
      }

      _hasPreviousMentalHealthAppExperience = prefs.getBool(
        'user_has_previous_mental_health_app_experience',
      );
      _selectedTherapyChatHistoryPreference = prefs.getString(
        'user_therapy_chat_history_preference',
      );
    });
  }

  Future<void> _launchPersonalityTestUrl() async {
    final uri = Uri.parse(
      'https://www.16personalities.com/free-personality-test',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open personality test website'),
          ),
        );
      }
    }
  }

  Future<void> _showTermsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => TermsDialog(
            onAccept: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_accepted_terms', true);
              if (!mounted) return;
              setState(() {
                _hasAcceptedTerms = true;
              });
              Navigator.of(context).pop();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
    );
  }

  Future<void> _setupPinCode() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinCodeScreen(isSettingUp: true),
      ),
    );

    if (result == true) {
      setState(() {
        _hasPinCode = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Check for terms and conditions first
      if (!_hasAcceptedTerms) {
        await _showTermsDialog();
        // If still not accepted after showing dialog, return
        if (!_hasAcceptedTerms) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please accept the terms and conditions to continue',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Check for PIN code
      if (!_hasPinCode) {
        await _setupPinCode();
        // If still not set after showing screen, return
        if (!_hasPinCode) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please set up a PIN code to continue'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final age = int.tryParse(_ageController.text);

        final profile = UserProfile(
          name: _nameController.text,
          age: age,
          gender: _selectedGender,
          job: _jobController.text,
          country: _countryController.text,
          personalityType: _selectedPersonalityType,
          relaxationTime: _selectedRelaxationTime,
          selfcareFrequency: _selectedSelfcareFrequency,
          relaxationTools:
              _selectedRelaxationTools.isEmpty
                  ? null
                  : _selectedRelaxationTools,
          hasPreviousMentalHealthAppExperience:
              _hasPreviousMentalHealthAppExperience,
          therapyChatHistoryPreference: _selectedTherapyChatHistoryPreference,
        );

        await ref.read(userProfileProvider.notifier).updateProfile(profile);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_age', age?.toString() ?? '');
        await prefs.setString('user_gender', _selectedGender ?? '');
        await prefs.setString('user_job', _jobController.text);
        await prefs.setString('user_country', _countryController.text);
        await prefs.setString(
          'user_personality_type',
          _selectedPersonalityType ?? '',
        );
        await prefs.setString(
          'user_relaxation_time',
          _selectedRelaxationTime ?? '',
        );
        await prefs.setString(
          'user_selfcare_frequency',
          _selectedSelfcareFrequency ?? '',
        );

        if (_selectedRelaxationTools.isNotEmpty) {
          await prefs.setStringList(
            'user_relaxation_tools',
            _selectedRelaxationTools,
          );
        } else {
          await prefs.remove('user_relaxation_tools');
        }

        await prefs.setBool(
          'user_has_previous_mental_health_app_experience',
          _hasPreviousMentalHealthAppExperience ?? false,
        );
        await prefs.setString(
          'user_therapy_chat_history_preference',
          _selectedTherapyChatHistoryPreference ?? 'keep',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Profile Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Male', 'Female', 'Non-binary', 'Prefer not to say'].map(
                        (String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        },
                      ).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jobController,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your occupation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Additional profile sections
                const Text(
                  'Additional Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Personality Type field with help icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPersonalityType,
                        decoration: const InputDecoration(
                          labelText: '16 Personality Type',
                          border: OutlineInputBorder(),
                          helperText: 'Select your MBTI personality type',
                        ),
                        items:
                            _personalityTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPersonalityType = newValue;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'Learn about personality types',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('16 Personality Types'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'The 16 personality types test tells you which celebrities you\'re most like! It\'s a popular psychology framework to understand different personality traits.',
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text(
                                        'Take the test here, it\'s free!',
                                      ),
                                      onPressed: _launchPersonalityTestUrl,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Relaxation time preference
                DropdownButtonFormField<String>(
                  value: _selectedRelaxationTime,
                  decoration: const InputDecoration(
                    labelText: 'What time of day do you tend to relax?',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _relaxationTimeOptions.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRelaxationTime = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Self-care frequency
                DropdownButtonFormField<String>(
                  value: _selectedSelfcareFrequency,
                  decoration: const InputDecoration(
                    labelText: 'How often do you take time for yourself?',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _selfcareFrequencyOptions.map((String frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSelfcareFrequency = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Relaxation tools
                const Text(
                  'What tools help you relax? (Select all that apply)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _relaxationToolOptions.map((tool) {
                        final isSelected = _selectedRelaxationTools.contains(
                          tool,
                        );
                        return FilterChip(
                          label: Text(tool),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRelaxationTools.add(tool);
                              } else {
                                _selectedRelaxationTools.remove(tool);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),

                // Previous mental health app experience
                const Text(
                  'Have you ever used a mental health app before?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Yes'),
                        value: true,
                        groupValue: _hasPreviousMentalHealthAppExperience,
                        onChanged: (value) {
                          setState(() {
                            _hasPreviousMentalHealthAppExperience = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('No'),
                        value: false,
                        groupValue: _hasPreviousMentalHealthAppExperience,
                        onChanged: (value) {
                          setState(() {
                            _hasPreviousMentalHealthAppExperience = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Therapy chat history preference
                const Text(
                  'For AI therapy conversations, what context would you prefer?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Column(
                  children:
                      _therapyChatHistoryOptions.map((option) {
                        return RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: _selectedTherapyChatHistoryPreference,
                          onChanged: (value) {
                            setState(() {
                              _selectedTherapyChatHistoryPreference = value;
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                ListTile(
                  title: const Text('Terms and Conditions'),
                  subtitle: Text(
                    _hasAcceptedTerms
                        ? 'Accepted'
                        : 'Please accept the terms and conditions',
                  ),
                  trailing: Icon(
                    _hasAcceptedTerms
                        ? Icons.check_circle
                        : Icons.arrow_forward,
                    color: _hasAcceptedTerms ? Colors.green : null,
                  ),
                  onTap: _showTermsDialog,
                ),
                const Divider(),
                ListTile(
                  title: const Text('PIN Code'),
                  subtitle: Text(
                    _hasPinCode ? 'Set' : 'Please set up a PIN code',
                  ),
                  trailing: Icon(
                    _hasPinCode ? Icons.check_circle : Icons.arrow_forward,
                    color: _hasPinCode ? Colors.green : null,
                  ),
                  onTap: _setupPinCode,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save Profile'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
