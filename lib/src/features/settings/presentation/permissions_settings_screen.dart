import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/permission_service.dart';
import '../../../services/theme/custom_colors.dart';

class PermissionsSettingsScreen extends ConsumerStatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  ConsumerState<PermissionsSettingsScreen> createState() =>
      _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState
    extends ConsumerState<PermissionsSettingsScreen> {
  bool _isLoading = true;
  Map<Permission, bool> _permissionStatus = {};
  final List<PermissionData> _permissionList = [
    PermissionData(
      permission: Permission.notification,
      title: 'Notifications',
      icon: Icons.notifications,
      description: 'Allows us to send workout reminders and important updates',
    ),
    PermissionData(
      permission: Permission.camera,
      title: 'Camera',
      icon: Icons.camera_alt,
      description: 'Used for scanning barcodes and taking progress photos',
    ),
    PermissionData(
      permission: Permission.storage,
      title: 'Storage',
      icon: Icons.sd_storage,
      description: 'Allows saving workout data offline and exporting reports',
    ),
    // You can add more permissions as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    final permissionService = ref.read(permissionServiceProvider);

    // Initialize map with all permissions set to false
    Map<Permission, bool> statusMap = {};

    // Check status for each permission
    for (final permData in _permissionList) {
      final isGranted =
          await permissionService.checkPermission(permData.permission);
      statusMap[permData.permission] = isGranted;
    }

    // Update state with current permissions
    if (mounted) {
      setState(() {
        _permissionStatus = statusMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = CustomColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Permissions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control which features FitFlow can access on your device',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Permissions list
                  ..._permissionList.map((permData) {
                    final isGranted =
                        _permissionStatus[permData.permission] ?? false;
                    return _buildPermissionCard(permData, isGranted);
                  }),

                  const SizedBox(height: 24),

                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: customColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Permissions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you deny permissions, some features may not work correctly. You can always change your permissions in your device settings.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Device Settings'),
                            onPressed: () {
                              ref
                                  .read(permissionServiceProvider)
                                  .openSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Privacy policy link
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          _showPrivacyPolicy();
                        },
                        icon: const Icon(Icons.privacy_tip, size: 18),
                        label: const Text('View Privacy Policy'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard(PermissionData permData, bool isGranted) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = CustomColors.of(context);

    Color iconColor;
    Color iconBackgroundColor;

    if (isGranted) {
      iconColor = customColors.success;
      iconBackgroundColor = customColors.success.withOpacity(0.1);
    } else {
      iconColor = colorScheme.primary;
      iconBackgroundColor = colorScheme.primary.withOpacity(0.1);
    }

    // Check contrast for better accessibility
    final contrastWithBackground = CustomColors.calculateContrastRatio(
        iconColor, Theme.of(context).colorScheme.surface);

    if (!CustomColors.isAccessibleText(iconColor, iconBackgroundColor)) {
      // If contrast is poor, adjust opacity to improve it
      iconBackgroundColor = iconColor.withOpacity(0.2);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Permission icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                permData.icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Permission details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permData.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    permData.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),

            // Status and request button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.cancel,
                      color: isGranted
                          ? customColors.success
                          : customColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGranted ? 'Granted' : 'Denied',
                      style: TextStyle(
                        fontSize: 12,
                        color: isGranted
                            ? customColors.success
                            : customColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _requestPermission(permData.permission),
                  child: Text(isGranted ? 'Review' : 'Enable'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(Permission permission) async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.requestPermission(permission);

    // Reload permission status
    await _loadPermissionStatus();
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a sample privacy policy for the FitFlow app. '
            'In a real app, this would contain the full privacy policy text. '
            'We take your privacy seriously and only collect data necessary '
            'for the app\'s functionality.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class PermissionData {
  final Permission permission;
  final String title;
  final IconData icon;
  final String description;

  PermissionData({
    required this.permission,
    required this.title,
    required this.icon,
    required this.description,
  });
}
