import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/themed_card.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/therapy_context.dart';
import '../../../data/services/profile_service.dart';
import '../providers/profile_provider.dart';
import '../widgets/therapy_context_card.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_display.dart';
import '../widgets/context_modification_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  UserProfile? _profile;
  TherapyContext? _therapyContext;
  ProfileStatus? _profileStatus;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final profileNotifier = ref.read(profileProvider.notifier);
      final therapyContextNotifier = ref.read(therapyContextProvider.notifier);
      final profileStatusNotifier = ref.read(profileStatusProvider.notifier);

      // Load profile data
      _profile = await profileNotifier.getUserProfile();
      print('DEBUG: Profile loaded: $_profile'); // Debug log
      _therapyContext = await therapyContextNotifier.getTherapyContext();
      _profileStatus = await profileStatusNotifier.getProfileStatus();

      print(
        'DEBUG: Profile data loaded - Profile: ${_profile != null}, TherapyContext: ${_therapyContext != null}, Status: ${_profileStatus != null}',
      );
    } catch (e) {
      print('DEBUG: Error loading profile data: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile(Map<String, dynamic> profileData) async {
    try {
      final profileNotifier = ref.read(profileProvider.notifier);
      final updatedProfile = await profileNotifier.createOrUpdateProfile(
        profileData,
      );

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload profile data
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTherapyContext(Map<String, dynamic> contextData) async {
    try {
      final therapyContextNotifier = ref.read(therapyContextProvider.notifier);
      final updatedContext = await therapyContextNotifier.updateTherapyContext(
        contextData,
      );

      setState(() {
        _therapyContext = updatedContext;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Therapy context updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating therapy context: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearTherapyContext() async {
    try {
      final therapyContextNotifier = ref.read(therapyContextProvider.notifier);
      await therapyContextNotifier.clearTherapyContext();

      setState(() {
        _therapyContext = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Therapy context cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing therapy context: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Status Card
            if (_profileStatus != null) _buildProfileStatusCard(),

            const SizedBox(height: 16),

            // Therapy Context Section
            if (_therapyContext != null && _therapyContext!.hasContext)
              _buildTherapyContextSection(),

            const SizedBox(height: 16),

            // Profile Content
            if (_isEditing || _profile == null)
              ProfileForm(
                initialProfile: _profile,
                onSave: _saveProfile,
                onCancel: () => setState(() => _isEditing = false),
              )
            else
              ProfileDisplay(
                profile: _profile!,
                onEdit: () => setState(() => _isEditing = true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatusCard() {
    return ThemedCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _profileStatus!.isComplete ? Icons.check_circle : Icons.info,
                  color:
                      _profileStatus!.isComplete ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _profileStatus!.profileCompleteness / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _profileStatus!.isComplete ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _profileStatus!.completenessText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_profileStatus!.missingFields.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Missing: ${_profileStatus!.missingFields.join(', ')}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTherapyContextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.lightPink),
            const SizedBox(width: 8),
            Text(
              'What I Know About You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TherapyContextCard(
          therapyContext: _therapyContext!,
          onEdit: () => _showContextModificationDialog(),
          onClear: _clearTherapyContext,
        ),
      ],
    );
  }

  void _showContextModificationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ContextModificationDialog(
            therapyContext: _therapyContext!,
            onSave: _updateTherapyContext,
          ),
    );
  }
}
