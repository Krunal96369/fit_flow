import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_scaffold.dart';
import '../../../services/unit_preference_service.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';

/// Screen for editing user profile information
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Constructor
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _displayNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // Additional controllers for imperial measurements
  late TextEditingController _feetController;
  late TextEditingController _inchesController;
  late TextEditingController _poundsController;

  String? _gender;
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  UnitSystem _unitSystem = UnitSystem.metric;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();

    // Initialize imperial measurement controllers
    _feetController = TextEditingController();
    _inchesController = TextEditingController();
    _poundsController = TextEditingController();
  }

  void _initializeFields(UserProfile profile) {
    // Retrieve the current unit system
    final unitSystem = ref.read(unitSystemProvider);

    // Only set the controllers if they're not already set to avoid flicker
    if (_displayNameController.text != profile.displayName) {
      _displayNameController.text = profile.displayName;
    }
    if (_firstNameController.text != (profile.firstName ?? '')) {
      _firstNameController.text = profile.firstName ?? '';
    }
    if (_lastNameController.text != (profile.lastName ?? '')) {
      _lastNameController.text = profile.lastName ?? '';
    }

    // Set measurements based on unit system
    if (profile.height != null) {
      if (unitSystem == UnitSystem.metric) {
        // Set metric height (cm)
        _heightController.text = profile.height!.toStringAsFixed(1);
      } else {
        // Set imperial height (feet and inches)
        final totalInches = profile.height! / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();

        _feetController.text = feet.toString();
        _inchesController.text = inches.toString();
      }
    } else {
      _heightController.text = '';
      _feetController.text = '';
      _inchesController.text = '';
    }

    if (profile.weight != null) {
      if (unitSystem == UnitSystem.metric) {
        // Set metric weight (kg)
        _weightController.text = profile.weight!.toStringAsFixed(1);
      } else {
        // Set imperial weight (pounds)
        final pounds = profile.weight! * 2.20462;
        _poundsController.text = pounds.toStringAsFixed(1);
      }
    } else {
      _weightController.text = '';
      _poundsController.text = '';
    }

    setState(() {
      _gender = profile.gender;
      _dateOfBirth = profile.dateOfBirth;
      _unitSystem = unitSystem;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _poundsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    // Update unit system if it changed externally
    if (_unitSystem != unitSystem) {
      _unitSystem = unitSystem;

      // If we have profile data, update the displayed values
      profileAsync.whenData((profile) {
        if (profile != null) {
          _updateDisplayedMeasurements(profile, unitSystem);
        }
      });
    }

    return AppScaffold(
      title: 'Edit Profile',
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          // Initialize the fields when profile data is available
          _initializeFields(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile photo section
                  _buildProfilePhotoSection(context, profile),
                  const SizedBox(height: 24),

                  // Basic information
                  _buildSectionTitle(context, 'Basic Information'),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Display name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Unit preference
                  _buildSectionTitle(context, 'Measurement Units'),
                  const SizedBox(height: 8),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select your preferred unit system:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<UnitSystem>(
                                  title: const Text('Metric'),
                                  subtitle: const Text('kg, cm'),
                                  value: UnitSystem.metric,
                                  groupValue: _unitSystem,
                                  onChanged: _changeUnitSystem,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<UnitSystem>(
                                  title: const Text('Imperial'),
                                  subtitle: const Text('lb, ft/in'),
                                  value: UnitSystem.imperial,
                                  groupValue: _unitSystem,
                                  onChanged: _changeUnitSystem,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Physical attributes
                  _buildSectionTitle(context, 'Physical Attributes'),
                  const SizedBox(height: 8),

                  // Height input - different based on unit system
                  _unitSystem == UnitSystem.metric
                      ? _buildMetricHeightField()
                      : _buildImperialHeightFields(),

                  const SizedBox(height: 16),

                  // Weight input - different based on unit system
                  _unitSystem == UnitSystem.metric
                      ? _buildMetricWeightField()
                      : _buildImperialWeightField(),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: ['Male', 'Female', 'Other', 'Prefer not to say']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value),
                    hint: const Text('Select gender'),
                  ),
                  const SizedBox(height: 16),

                  // Date of birth
                  InkWell(
                    onTap: _selectDateOfBirth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                            : 'Select date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save Profile'),
                        ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildMetricHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: const InputDecoration(
        labelText: 'Height (cm)',
        hintText: 'e.g. 175.5',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.height),
        helperText: 'Enter your height in centimeters',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final height = double.tryParse(value);
        if (height == null) return 'Enter a valid number';
        if (height < 50 || height > 250) {
          return 'Enter a realistic height (50-250 cm)';
        }
        return null;
      },
    );
  }

  Widget _buildImperialHeightFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _feetController,
            decoration: const InputDecoration(
              labelText: 'Feet',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.height),
              helperText: 'Feet portion of height',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final feet = int.tryParse(value);
              if (feet == null) return 'Enter a valid number';
              if (feet < 1 || feet > 8) {
                return 'Enter a realistic height (1-8 ft)';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _inchesController,
            decoration: const InputDecoration(
              labelText: 'Inches',
              border: OutlineInputBorder(),
              helperText: 'Inches portion of height',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final inches = int.tryParse(value);
              if (inches == null) return 'Enter a valid number';
              if (inches < 0 || inches > 11) return 'Must be 0-11';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        hintText: 'e.g. 70.5',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.monitor_weight),
        helperText: 'Enter your weight in kilograms',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final weight = double.tryParse(value);
        if (weight == null) return 'Enter a valid number';
        if (weight < 30 || weight > 300) {
          return 'Enter a realistic weight (30-300 kg)';
        }
        return null;
      },
    );
  }

  Widget _buildImperialWeightField() {
    return TextFormField(
      controller: _poundsController,
      decoration: const InputDecoration(
        labelText: 'Weight (lb)',
        hintText: 'e.g. 155.5',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.monitor_weight),
        helperText: 'Enter your weight in pounds',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final weight = double.tryParse(value);
        if (weight == null) return 'Enter a valid number';
        if (weight < 66 || weight > 660) {
          return 'Enter a realistic weight (66-660 lb)';
        }
        return null;
      },
    );
  }

  void _changeUnitSystem(UnitSystem? newUnitSystem) {
    if (newUnitSystem == null || newUnitSystem == _unitSystem) return;

    // Save the new unit system preference globally
    ref.read(unitSystemProvider.notifier).setUnitSystem(newUnitSystem);

    // Update the form fields with converted values
    final profileData = ref.read(userProfileProvider);
    profileData.whenData((profile) {
      if (profile != null) {
        _updateDisplayedMeasurements(profile, newUnitSystem);
      }
    });

    setState(() {
      _unitSystem = newUnitSystem;
    });
  }

  void _updateDisplayedMeasurements(
      UserProfile profile, UnitSystem unitSystem) {
    if (profile.height != null) {
      if (unitSystem == UnitSystem.metric) {
        // Convert to metric
        _heightController.text = profile.height!.toStringAsFixed(1);
      } else {
        // Convert to imperial (feet and inches)
        final totalInches = profile.height! / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();

        _feetController.text = feet.toString();
        _inchesController.text = inches.toString();
      }
    }

    if (profile.weight != null) {
      if (unitSystem == UnitSystem.metric) {
        // Convert to metric
        _weightController.text = profile.weight!.toStringAsFixed(1);
      } else {
        // Convert to imperial
        final pounds = profile.weight! * 2.20462;
        _poundsController.text = pounds.toStringAsFixed(1);
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProfilePhotoSection(BuildContext context, UserProfile profile) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Icon(Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.onPrimary)
                    : null,
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 18),
                  color: Theme.of(context).colorScheme.onPrimary,
                  onPressed: _updateProfilePhoto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime today = DateTime.now();
    final DateTime initialDate =
        _dateOfBirth ?? today.subtract(const Duration(days: 365 * 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
    );

    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  Future<void> _updateProfilePhoto() async {
    // This would be implemented to upload a photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo upload - Coming soon')),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileAsync = await ref.read(userProfileProvider.future);
      if (profileAsync == null) {
        throw Exception('Profile not found');
      }

      // Convert input values to metric for storage
      double? heightInCm;
      if (_unitSystem == UnitSystem.metric) {
        // Metric height is already in cm
        if (_heightController.text.isNotEmpty) {
          heightInCm = double.parse(_heightController.text);
        }
      } else {
        // Convert imperial height (feet and inches) to cm
        if (_feetController.text.isNotEmpty) {
          final feet = int.parse(_feetController.text);
          final inches = _inchesController.text.isNotEmpty
              ? int.parse(_inchesController.text)
              : 0;
          final totalInches = (feet * 12) + inches;
          heightInCm = totalInches * 2.54; // Convert inches to cm
        }
      }

      double? weightInKg;
      if (_unitSystem == UnitSystem.metric) {
        // Metric weight is already in kg
        if (_weightController.text.isNotEmpty) {
          weightInKg = double.parse(_weightController.text);
        }
      } else {
        // Convert imperial weight (pounds) to kg
        if (_poundsController.text.isNotEmpty) {
          final pounds = double.parse(_poundsController.text);
          weightInKg = pounds / 2.20462; // Convert pounds to kg
        }
      }

      await ref.read(profileControllerProvider).updateUserProfile(
            userId: profileAsync.id,
            displayName: _displayNameController.text,
            firstName: _firstNameController.text.isEmpty
                ? null
                : _firstNameController.text,
            lastName: _lastNameController.text.isEmpty
                ? null
                : _lastNameController.text,
            height: heightInCm,
            weight: weightInKg,
            dateOfBirth: _dateOfBirth,
            gender: _gender,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
