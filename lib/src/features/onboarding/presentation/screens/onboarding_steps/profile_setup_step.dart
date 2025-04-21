import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to expose the profile form data
final profileFormProvider =
    StateNotifierProvider<ProfileFormNotifier, ProfileFormData>((ref) {
  return ProfileFormNotifier();
});

// Model to hold profile form data
class ProfileFormData {
  final String? displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final String heightUnit;
  final String weightUnit;

  ProfileFormData({
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
  });

  ProfileFormData copyWith({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
  }) {
    return ProfileFormData(
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }

  // Convert height to cm for storage
  double? getHeightInCm() {
    if (height == null) return null;

    // Convert from feet/inches to cm if needed
    if (heightUnit == 'ft') {
      return height! * 30.48; // 1 foot = 30.48 cm
    }
    return height;
  }

  // Convert weight to kg for storage
  double? getWeightInKg() {
    if (weight == null) return null;

    // Convert from pounds to kg if needed
    if (weightUnit == 'lb') {
      return weight! * 0.453592; // 1 pound = 0.453592 kg
    }
    return weight;
  }
}

// Notifier to manage profile form state
class ProfileFormNotifier extends StateNotifier<ProfileFormData> {
  ProfileFormNotifier() : super(ProfileFormData());

  void updateDisplayName(String? name) {
    state = state.copyWith(displayName: name);
  }

  void updateGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void updateDateOfBirth(DateTime? date) {
    state = state.copyWith(dateOfBirth: date);
  }

  void updateHeight(String? heightStr) {
    final height = heightStr != null ? double.tryParse(heightStr) : null;
    state = state.copyWith(height: height);
  }

  void updateWeight(String? weightStr) {
    final weight = weightStr != null ? double.tryParse(weightStr) : null;
    state = state.copyWith(weight: weight);
  }

  void updateHeightUnit(String unit) {
    state = state.copyWith(heightUnit: unit);
  }

  void updateWeightUnit(String unit) {
    state = state.copyWith(weightUnit: unit);
  }
}

/// Step for setting up the user's profile during onboarding
class ProfileSetupStep extends ConsumerStatefulWidget {
  /// Constructor
  const ProfileSetupStep({super.key});

  @override
  ConsumerState<ProfileSetupStep> createState() => _ProfileSetupStepState();
}

class _ProfileSetupStepState extends ConsumerState<ProfileSetupStep> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _displayNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  @override
  void dispose() {
    _displayNameController.dispose();
    _heightController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchExistingProfileData();
  }

  Future<void> _fetchExistingProfileData() async {
    // This would fetch data from Firebase in a real implementation
  }

  // Update the form notifier when text changes
  void _updateFormState() {
    final notifier = ref.read(profileFormProvider.notifier);
    notifier.updateDisplayName(_displayNameController.text.isEmpty
        ? null
        : _displayNameController.text);
    notifier.updateGender(_selectedGender);
    notifier.updateDateOfBirth(_dateOfBirth);

    // Handle height based on unit
    if (_heightUnit == 'cm') {
      notifier.updateHeight(_heightController.text);
    } else {
      // Convert feet and inches to a single feet value
      final feet = double.tryParse(_heightController.text) ?? 0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0;
      final totalFeet = feet + (inches / 12);
      notifier.updateHeight(totalFeet.toString());
    }

    notifier.updateWeight(_weightController.text);
    notifier.updateHeightUnit(_heightUnit);
    notifier.updateWeightUnit(_weightUnit);
  }

  // Update height unit and convert value if needed
  void _updateHeightUnit(String unit) {
    if (_heightUnit == unit) return;

    // Convert value if field is not empty
    if (_heightController.text.isNotEmpty) {
      final double? currentValue = double.tryParse(_heightController.text);
      if (currentValue != null) {
        if (unit == 'cm' && _heightUnit == 'ft') {
          // Convert from feet to cm
          double feet = currentValue;
          double inches = double.tryParse(_heightInchesController.text) ?? 0;
          double totalInches = (feet * 12) + inches;
          double cm = totalInches * 2.54;
          _heightController.text = cm.toStringAsFixed(1);
          _heightInchesController.text = '0';
        } else if (unit == 'ft' && _heightUnit == 'cm') {
          // Convert from cm to feet and inches
          double totalInches = currentValue / 2.54;
          int feet = (totalInches / 12).floor();
          int inches = (totalInches % 12).round();
          _heightController.text = feet.toString();
          _heightInchesController.text = inches.toString();
        }
      }
    } else {
      // Clear both fields
      _heightController.text = '';
      _heightInchesController.text = '';
    }

    setState(() {
      _heightUnit = unit;
      _updateFormState();
    });
  }

  // Update weight unit and convert value if needed
  void _updateWeightUnit(String unit) {
    if (_weightUnit == unit) return;

    // Convert value if field is not empty
    if (_weightController.text.isNotEmpty) {
      final double? currentValue = double.tryParse(_weightController.text);
      if (currentValue != null) {
        double newValue;
        if (unit == 'kg' && _weightUnit == 'lb') {
          // Convert from pounds to kg
          newValue = currentValue * 0.453592;
          _weightController.text = newValue.toStringAsFixed(1);
        } else if (unit == 'lb' && _weightUnit == 'kg') {
          // Convert from kg to pounds
          newValue = currentValue / 0.453592;
          _weightController.text = newValue.toStringAsFixed(1);
        }
      }
    }

    setState(() {
      _weightUnit = unit;
      _updateFormState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Create Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Let us get to know you better to personalize your experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 32),

              // Display name field
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'What should we call you?',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) => _updateFormState(),
              ),

              const SizedBox(height: 24),

              // Gender selection
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _buildGenderOption('Male', Icons.male),
                  const SizedBox(width: 8),
                  _buildGenderOption('Female', Icons.female),
                  const SizedBox(width: 8),
                  _buildGenderOption('Other', Icons.person),
                ],
              ),

              const SizedBox(height: 8),

              // Prefer not to say option
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Not specified';
                    _updateFormState();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        _selectedGender == 'Not specified'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _selectedGender == 'Not specified'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prefer not to say',
                        style: TextStyle(
                          color: _selectedGender == 'Not specified'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select date',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Height input with unit selection
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: _heightUnit == 'ft' ? 2 : 3,
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _heightUnit == 'cm' ? 'Height (cm)' : 'Feet',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.height),
                      ),
                      onChanged: (value) => _updateFormState(),
                    ),
                  ),
                  // Show inches field only when feet is selected
                  if (_heightUnit == 'ft') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _heightInchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Inches',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateFormState(),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Unit selector
                  Container(
                    width: 45,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _updateHeightUnit('cm'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _heightUnit == 'cm'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'cm',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _heightUnit == 'cm'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _heightUnit == 'cm'
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.shade400),
                        Expanded(
                          child: InkWell(
                            onTap: () => _updateHeightUnit('ft'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _heightUnit == 'ft'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ft',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _heightUnit == 'ft'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _heightUnit == 'ft'
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weight input with unit selection
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Weight (${_weightUnit == 'kg' ? 'kg' : 'lb'})',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.monitor_weight),
                      ),
                      onChanged: (value) => _updateFormState(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unit selector
                  Container(
                    width: 45,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _updateWeightUnit('kg'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _weightUnit == 'kg'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'kg',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _weightUnit == 'kg'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _weightUnit == 'kg'
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.shade400),
                        Expanded(
                          child: InkWell(
                            onTap: () => _updateWeightUnit('lb'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _weightUnit == 'lb'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'lb',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _weightUnit == 'lb'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _weightUnit == 'lb'
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hint about privacy
              Text(
                'Your information is private and securely stored.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = gender;
            _updateFormState();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _dateOfBirth ?? DateTime(now.year - 30);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _dateOfBirth = pickedDate;
        _updateFormState();
      });
    }
  }
}
