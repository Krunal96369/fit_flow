import 'package:flutter/material.dart';

import '../services/theme/app_theme.dart';

class AccessibilityDemoScreen extends StatefulWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  State<AccessibilityDemoScreen> createState() =>
      _AccessibilityDemoScreenState();
}

class _AccessibilityDemoScreenState extends State<AccessibilityDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDarkMode = false; // Default to light mode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Demo'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip:
                isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Contrast', icon: Icon(Icons.contrast)),
            Tab(text: 'Text Scaling', icon: Icon(Icons.text_fields)),
            Tab(text: 'Focus & Touch', icon: Icon(Icons.touch_app)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContrastTab(isDarkMode),
          _buildTextScalingTab(),
          _buildFocusAndTouchTab(),
        ],
      ),
    );
  }

  Widget _buildContrastTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color Contrast Demonstration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            semanticsLabel: 'Color Contrast Demonstration Heading',
          ),
          const SizedBox(height: 8),
          const Text(
            'The WCAG guidelines require a minimum contrast ratio of 4.5:1 for normal text and 3:1 for large text. AAA level requires 7:1 for normal text and 4.5:1 for large text.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ...AppTheme.getSampleColorPairs(isDarkMode).map((pair) {
            final foreground = pair['foreground'] as Color;
            final background = pair['background'] as Color;
            final name = pair['name'] as String;
            final isLargeText = pair['isLargeText'] as bool;

            final contrastRatio =
                AppTheme.calculateContrastRatio(foreground, background);
            final passLevel = AppTheme.getContrastLevel(contrastRatio,
                isLargeText: isLargeText);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: background,
                    child: Text(
                      'Sample text with this color',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                          'Contrast ratio: ${contrastRatio.toStringAsFixed(2)}:1'),
                      const Spacer(),
                      _buildContrastBadge(passLevel),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContrastBadge(String level) {
    Color color;
    switch (level) {
      case 'AAA':
        color = Colors.green;
        break;
      case 'AA':
        color = Colors.blue;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextScalingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Scaling Demonstration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            semanticsLabel: 'Text Scaling Demonstration Heading',
          ),
          const SizedBox(height: 16),
          const Text(
            'This example shows how text scales with the system font size settings. The text below will adjust based on the user\'s device settings.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Example of using MediaQuery to respect text scaling
          Builder(builder: (context) {
            final textScaleFactor = MediaQuery.of(context).textScaleFactor;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Text Scale Factor: ${textScaleFactor.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This is an example of normal text that will scale with the user\'s settings.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is an example of heading text',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is smaller text that should still be readable',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Device Settings'),
            onPressed: () {
              // Ideally, we would navigate to text scaling settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'This would open text scaling settings in a real app'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAndTouchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus and Touch Targets',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            semanticsLabel: 'Focus and Touch Targets Heading',
          ),
          const SizedBox(height: 16),
          const Text(
            'Interactive elements should have touch targets of at least 48x48dp with at least 8dp between targets.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Good example of touch targets
          _buildExampleCard(
            title: 'Good Example',
            description: 'These buttons have sufficient size and spacing',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAccessibleButton(
                  icon: Icons.favorite,
                  label: 'Like',
                  onPressed: () {},
                ),
                _buildAccessibleButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () {},
                ),
                _buildAccessibleButton(
                  icon: Icons.bookmark,
                  label: 'Save',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bad example of touch targets
          _buildExampleCard(
            title: 'Poor Example',
            description: 'These buttons are too small and cramped',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Focus traversal example
          _buildExampleCard(
            title: 'Focus Traversal',
            description: 'Try navigating these fields with the tab key',
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              minWidth: 64,
              minHeight: 48,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 4),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
