import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../services/theme/theme_service.dart';

/// Profile screen with user information and setting options
class ProfileScreen extends ConsumerWidget {
  /// Constructor
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

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

          // Getting actual user data
          final displayName = user.displayName ?? 'FitFlow User';
          final email = user.email ?? 'No email available';
          final photoUrl = user.photoURL;

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
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Icon(Icons.person,
                            size: 50, color: theme.colorScheme.onPrimary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // User name from Firebase
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // User email from Firebase
                  Text(email),
                  const SizedBox(height: 32),
                  // Settings sections
                  _buildSettingSection(
                    context,
                    title: 'Account Settings',
                    items: [
                      _SettingItem(
                        icon: Icons.person,
                        title: 'Edit Profile',
                        onTap: () {
                          // This would be implemented in a future feature
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Edit Profile - Coming soon')),
                          );
                        },
                      ),
                      _SettingItem(
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: () {
                          // This would be implemented in a future feature
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Change Password - Coming soon')),
                          );
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
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
