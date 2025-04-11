import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model with extended information beyond Firebase Auth data
class UserProfile {
  /// Unique identifier (should match Firebase Auth UID)
  final String id;

  /// Display name for the user
  final String displayName;

  /// User's email address
  final String email;

  /// URL to the user's profile photo
  final String? photoUrl;

  /// User's first name
  final String? firstName;

  /// User's last name
  final String? lastName;

  /// User's height in cm
  final double? height;

  /// User's weight in kg
  final double? weight;

  /// User's date of birth
  final DateTime? dateOfBirth;

  /// User's gender (optional)
  final String? gender;

  /// When the profile was last updated
  final DateTime? lastUpdated;

  /// When the profile was created
  final DateTime? createdAt;

  /// User preferences
  final Map<String, dynamic>? preferences;

  /// Whether the user is an admin
  final bool isAdmin;

  /// Constructor
  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.firstName,
    this.lastName,
    this.height,
    this.weight,
    this.dateOfBirth,
    this.gender,
    this.lastUpdated,
    this.createdAt,
    this.preferences,
    this.isAdmin = false,
  });

  /// Create a copy of this user profile with the given fields replaced
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? firstName,
    String? lastName,
    double? height,
    double? weight,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? lastUpdated,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
    bool? isAdmin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  /// Calculated BMI based on height and weight
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      // BMI = weight (kg) / height² (m²)
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  /// Calculated age based on date of birth
  int? get age {
    if (dateOfBirth != null) {
      final today = DateTime.now();
      int age = today.year - dateOfBirth!.year;
      if (today.month < dateOfBirth!.month ||
          (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
        age--;
      }
      return age;
    }
    return null;
  }

  /// Convert profile to a map for storage in Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'userId': id, // Using userId to match the existing structure
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'firstName': firstName,
      'lastName': lastName,
      'height': height,
      'weight': weight,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'updatedAt': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
      'isAdmin': isAdmin,
    };

    // Only include preferences if it exists
    if (preferences != null) {
      map['preferences'] = preferences;
    }

    // Only include createdAt when creating a new document, not on updates
    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    return map;
  }

  /// Create a profile from a Firestore document map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['userId'] ?? map['id'] ?? '', // Support both id formats
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      gender: map['gender'],
      lastUpdated: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      preferences: map['preferences'] as Map<String, dynamic>?,
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  /// Create a default profile from Firebase Auth user data
  factory UserProfile.fromFirebaseUser(String uid, String email,
      {String? displayName}) {
    final now = DateTime.now();
    return UserProfile(
      id: uid,
      displayName: displayName ?? email.split('@').first,
      email: email,
      lastUpdated: now,
      createdAt: now,
      preferences: {
        'theme': 'system',
        'notifications': true,
      },
      isAdmin: false,
    );
  }
}
