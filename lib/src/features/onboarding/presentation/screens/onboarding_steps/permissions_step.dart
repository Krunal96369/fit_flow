import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../services/permission_service.dart';

/// Step for requesting and explaining necessary app permissions
class PermissionsStep extends ConsumerStatefulWidget {
  /// Constructor
  const PermissionsStep({super.key});

  @override
  ConsumerState<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<PermissionsStep> {
  // Permission states
  bool _notificationsGranted = false;
  bool _healthDataGranted = false;
  bool _cameraGranted = false;
  bool _storageGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);

    // Check notification permission
    final notificationStatus =
        await permissionService.checkPermission(Permission.notification);

    // Check camera permission
    final cameraStatus =
        await permissionService.checkPermission(Permission.camera);

    // Check storage permission
    final storageStatus =
        await permissionService.checkPermission(Permission.storage);

    // For health data, we're using a placeholder since it requires
    // platform-specific implementations
    final healthStatus = false;

    // Update state with current permissions
    setState(() {
      _notificationsGranted = notificationStatus;
      _healthDataGranted = healthStatus;
      _cameraGranted = cameraStatus;
      _storageGranted = storageStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'App Permissions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'FitFlow needs the following permissions to provide you with the best experience',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 32),

            // Permissions list
            _buildPermissionCard(
              title: 'Notifications',
              icon: Icons.notifications,
              description:
                  'To remind you about workouts, goals, and important updates',
              isGranted: _notificationsGranted,
              onRequest: () =>
                  _requestPermission(Permission.notification, 'notifications'),
            ),

            _buildPermissionCard(
              title: 'Health Data',
              icon: Icons.favorite,
              description:
                  'To access health data like steps, heart rate, and activity',
              isGranted: _healthDataGranted,
              onRequest: () => _showHealthPermissionInfo(),
            ),

            _buildPermissionCard(
              title: 'Camera',
              icon: Icons.camera_alt,
              description:
                  'To scan barcodes for nutrition tracking and progress photos',
              isGranted: _cameraGranted,
              onRequest: () => _requestPermission(Permission.camera, 'camera'),
            ),

            _buildPermissionCard(
              title: 'Storage',
              icon: Icons.sd_storage,
              description: 'To store workout data offline and export reports',
              isGranted: _storageGranted,
              onRequest: () =>
                  _requestPermission(Permission.storage, 'storage'),
            ),

            const SizedBox(height: 32),

            // Privacy policy link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _showPrivacyPolicy();
                },
                icon: const Icon(Icons.privacy_tip, size: 18),
                label: const Text('View Privacy Policy'),
              ),
            ),

            const SizedBox(height: 16),

            // Note about privacy
            Text(
              'You can change these permissions later in your device settings. '
              'We respect your privacy and only use your data as described in our privacy policy.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final successColor = colorScheme.secondary;
    final primaryColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Permission icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isGranted
                    ? successColor.withValues(alpha: 0.1)
                    : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? successColor : primaryColor,
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Request button or granted indicator
            isGranted
                ? Icon(Icons.check_circle, color: successColor)
                : TextButton(
                    onPressed: onRequest,
                    child: const Text('Grant'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(
      Permission permission, String permissionType) async {
    final permissionService = ref.read(permissionServiceProvider);
    final granted = await permissionService.requestPermission(permission);

    setState(() {
      switch (permissionType) {
        case 'notifications':
          _notificationsGranted = granted;
          break;
        case 'camera':
          _cameraGranted = granted;
          break;
        case 'storage':
          _storageGranted = granted;
          break;
      }
    });

    // Show message if permission is permanently denied
    if (!granted) {
      final status = await permission.status;
      if (status.isPermanentlyDenied && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${permissionType.capitalize()} Permission Required'),
            content: Text(
              'To use this feature, you need to enable the $permissionType permission in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  permissionService.openSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showHealthPermissionInfo() async {
    // Show dialog explaining that health permissions will be requested when needed
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Data Access'),
        content: const Text(
          'Health data access will be requested when you start using features that require it. '
          'This typically requires integration with Apple Health on iOS or Google Fit on Android.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
