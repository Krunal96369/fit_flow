import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step for requesting and explaining necessary app permissions
class PermissionsStep extends ConsumerStatefulWidget {
  /// Constructor
  const PermissionsStep({super.key});

  @override
  ConsumerState<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<PermissionsStep> {
  bool _notificationsGranted = false;
  bool _healthDataGranted = false;
  bool _cameraGranted = false;
  bool _storageGranted = false;

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

            const Text(
              'FitFlow needs the following permissions to provide you with the best experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
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
              onRequest: () => _requestPermission('notifications'),
            ),

            _buildPermissionCard(
              title: 'Health Data',
              icon: Icons.favorite,
              description:
                  'To access health data like steps, heart rate, and activity',
              isGranted: _healthDataGranted,
              onRequest: () => _requestPermission('health'),
            ),

            _buildPermissionCard(
              title: 'Camera',
              icon: Icons.camera_alt,
              description:
                  'To scan barcodes for nutrition tracking and progress photos',
              isGranted: _cameraGranted,
              onRequest: () => _requestPermission('camera'),
            ),

            _buildPermissionCard(
              title: 'Storage',
              icon: Icons.sd_storage,
              description: 'To store workout data offline and export reports',
              isGranted: _storageGranted,
              onRequest: () => _requestPermission('storage'),
            ),

            const SizedBox(height: 32),

            // Privacy policy link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Show privacy policy
                  _showPrivacyPolicy();
                },
                icon: const Icon(Icons.privacy_tip, size: 18),
                label: const Text('View Privacy Policy'),
              ),
            ),

            const SizedBox(height: 16),

            // Note about privacy
            const Text(
              'You can change these permissions later in your device settings. '
              'We respect your privacy and only use your data as described in our privacy policy.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
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
              color: Colors.grey.withOpacity(0.1),
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
                    ? successColor.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
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
                          .withOpacity(0.6),
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

  Future<void> _requestPermission(String permissionType) async {
    // This is a mock implementation - in a real app, you would request real permissions
    // Using platform-specific permission handlers

    // Show a confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request ${permissionType.capitalize()} Permission'),
        content: Text(
          'This is a demo of requesting the $permissionType permission. '
          'In a real app, this would trigger the system permission dialog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    // Update the state based on the result
    if (result == true) {
      setState(() {
        switch (permissionType) {
          case 'notifications':
            _notificationsGranted = true;
            break;
          case 'health':
            _healthDataGranted = true;
            break;
          case 'camera':
            _cameraGranted = true;
            break;
          case 'storage':
            _storageGranted = true;
            break;
        }
      });
    }
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
