import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../services/theme/theme_service.dart';
import '../../../services/unit_preference_service.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';

/// Profile screen with user information and setting options
class ProfileScreen extends ConsumerWidget {
  /// Constructor
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    final List<Widget> appBarActions = [
      IconButton(
        icon: Icon(
          currentTheme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () {
          ref.read(themeModeProvider.notifier).setThemeMode(
                currentTheme == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
        },
        tooltip: 'Toggle theme',
      ),
    ];

    return AppScaffold(
      title: 'Profile',
      actions: appBarActions,
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return userProfileAsync.when(
            data: (userProfile) {
              if (userProfile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return _buildProfileContent(
                  context, ref, userProfile, unitSystem);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading profile: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    UnitSystem unitSystem,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User photo (custom or default)
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Icon(Icons.person,
                      size: 50, color: theme.colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(height: 16),
            // User name from profile
            Text(
              profile.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // User email from profile
            Text(profile.email),
            const SizedBox(height: 16),

            // User stats section
            if (profile.height != null ||
                profile.weight != null ||
                profile.dateOfBirth != null ||
                profile.gender != null)
              _buildStatsCard(context, profile, unitSystem),

            const SizedBox(height: 24),
            // Settings sections
            _buildSettingSection(
              context,
              title: 'Account Settings',
              items: [
                _SettingItem(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  onTap: () {
                    context.push('/profile/edit');
                  },
                ),
                _SettingItem(
                  icon: Icons.lock,
                  title: 'Change Password',
                  onTap: () {
                    context.push('/change-password');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingSection(
              context,
              title: 'App Settings',
              items: [
                _SettingItem(
                  icon: Icons.dark_mode,
                  title: 'Theme',
                  onTap: () {
                    context.push('/settings/theme');
                  },
                ),
                _SettingItem(
                  icon: Icons.accessibility_new,
                  title: 'Accessibility',
                  onTap: () {
                    context.push('/settings/accessibility');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingSection(
              context,
              title: 'Nutrition',
              items: [
                _SettingItem(
                  icon: Icons.restaurant,
                  title: 'Nutrition Goals',
                  onTap: () {
                    context.push('/profile/nutrition-goals');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingSection(
              context,
              title: 'Data',
              items: [
                _SettingItem(
                  icon: Icons.file_download,
                  title: 'Export Data',
                  onTap: () {
                    context.push('/export');
                  },
                ),
                _SettingItem(
                  icon: Icons.delete,
                  title: 'Delete Account',
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider).signOut();
      if (context.mounted) {
        context.go('/sign-in');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close dialog
              Navigator.of(context).pop();
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion - Coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: items.map((item) {
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: item.isDestructive
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                title: Text(
                  item.title,
                  style: item.isDestructive
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: item.onTap,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
      BuildContext context, UserProfile profile, UnitSystem unitSystem) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            if (profile.height != null)
              unitSystem == UnitSystem.metric
                  ? _buildStatItem(
                      context,
                      icon: Icons.height,
                      label: 'Height',
                      value: '${profile.height!.toStringAsFixed(1)} cm',
                    )
                  : _buildStatItem(
                      context,
                      icon: Icons.height,
                      label: 'Height',
                      value:
                          '${(profile.height! / 2.54 / 12).floor()}\' ${((profile.height! / 2.54) % 12).round()}"',
                    ),
            if (profile.weight != null)
              unitSystem == UnitSystem.metric
                  ? _buildStatItem(
                      context,
                      icon: Icons.monitor_weight,
                      label: 'Weight',
                      value: '${profile.weight!.toStringAsFixed(1)} kg',
                    )
                  : _buildStatItem(
                      context,
                      icon: Icons.monitor_weight,
                      label: 'Weight',
                      value:
                          '${(profile.weight! * 2.20462).toStringAsFixed(1)} lb',
                    ),
            if (profile.bmi != null)
              _buildStatItem(
                context,
                icon: Icons.fitness_center,
                label: 'BMI',
                value: profile.bmi!.toStringAsFixed(1),
              ),
            if (profile.dateOfBirth != null) ...[
              _buildStatItem(
                context,
                icon: Icons.cake,
                label: 'Age',
                value: '${profile.age} years',
              ),
              _buildStatItem(
                context,
                icon: Icons.calendar_today,
                label: 'Birthday',
                value: DateFormat('MMMM d, yyyy').format(profile.dateOfBirth!),
              ),
            ],
            if (profile.gender != null)
              _buildStatItem(
                context,
                icon: Icons.person_outline,
                label: 'Gender',
                value: profile.gender!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}
