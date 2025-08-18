import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/themed_card.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../data/models/user_profile.dart';

class ProfileDisplay extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;

  const ProfileDisplay({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        _buildProfileHeader(context),

        const SizedBox(height: 16),

        // Basic Information
        _buildSectionHeader('Basic Information', Icons.person),
        _buildInfoCard([
          _buildInfoRow('Name', profile.displayName),
          _buildInfoRow('Username', profile.username),
          _buildInfoRow(
            'Date of Birth',
            profile.dateOfBirth != null
                ? DateFormat('MMM dd, yyyy').format(profile.dateOfBirth!)
                : null,
          ),
        ]),

        const SizedBox(height: 16),

        // Contact Information
        _buildSectionHeader('Contact Information', Icons.contact_phone),
        _buildInfoCard([
          _buildInfoRow('Phone', profile.phoneNumber),
          _buildInfoRow('Address', profile.address),
          _buildInfoRow('Occupation', profile.occupation),
        ]),

        const SizedBox(height: 16),

        // Emergency Contact
        if (profile.emergencyContact != null) ...[
          _buildSectionHeader('Emergency Contact', Icons.emergency),
          _buildInfoCard([
            _buildInfoRow('Name', profile.emergencyContact!.name),
            _buildInfoRow(
              'Relationship',
              profile.emergencyContact!.relationship,
            ),
            _buildInfoRow('Phone', profile.emergencyContact!.phone),
            if (profile.emergencyContact!.email != null)
              _buildInfoRow('Email', profile.emergencyContact!.email!),
          ]),
          const SizedBox(height: 16),
        ],

        // Medical Information
        if (profile.medicalInfo != null) ...[
          _buildSectionHeader('Medical Information', Icons.medical_services),
          _buildInfoCard([
            if (profile.medicalInfo!.conditions.isNotEmpty)
              _buildInfoRow(
                'Conditions',
                profile.medicalInfo!.conditions.join(', '),
              ),
            if (profile.medicalInfo!.medications.isNotEmpty)
              _buildInfoRow(
                'Medications',
                profile.medicalInfo!.medications.join(', '),
              ),
            if (profile.medicalInfo!.allergies.isNotEmpty)
              _buildInfoRow(
                'Allergies',
                profile.medicalInfo!.allergies.join(', '),
              ),
          ]),
          const SizedBox(height: 16),
        ],

        // Therapy Preferences
        if (profile.therapyPreferences != null) ...[
          _buildSectionHeader('Therapy Preferences', Icons.psychology),
          _buildInfoCard([
            if (profile.therapyPreferences!.communicationStyle != null)
              _buildInfoRow(
                'Communication Style',
                profile.therapyPreferences!.communicationStyle!,
              ),
            if (profile.therapyPreferences!.sessionFrequency != null)
              _buildInfoRow(
                'Session Frequency',
                profile.therapyPreferences!.sessionFrequency!,
              ),
            if (profile.therapyPreferences!.focusAreas.isNotEmpty)
              _buildInfoRow(
                'Focus Areas',
                profile.therapyPreferences!.focusAreas.join(', '),
              ),
            if (profile.therapyPreferences!.goals != null)
              _buildInfoRow('Goals', profile.therapyPreferences!.goals!),
          ]),
          const SizedBox(height: 16),
        ],

        // Profile Statistics
        _buildSectionHeader('Profile Statistics', Icons.analytics),
        _buildInfoCard([
          _buildInfoRow(
            'Profile Created',
            DateFormat('MMM dd, yyyy').format(profile.createdAt),
          ),
          _buildInfoRow(
            'Last Updated',
            DateFormat('MMM dd, yyyy').format(profile.updatedAt),
          ),
          _buildInfoRow(
            'Profile Status',
            profile.isProfileComplete ? 'Complete' : 'Incomplete',
          ),
        ]),

        const SizedBox(height: 24),

        // Edit Button
        SizedBox(
          width: double.infinity,
          child: PrimaryGradientButton(
            onPressed: onEdit,
            child: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return ThemedCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryViolet.withOpacity(0.1),
              child: Text(
                profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryViolet,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          profile.isProfileComplete
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            profile.isProfileComplete
                                ? Colors.green
                                : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      profile.isProfileComplete
                          ? 'Profile Complete'
                          : 'Profile Incomplete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            profile.isProfileComplete
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryViolet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return ThemedCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
