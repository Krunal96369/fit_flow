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
    return {
      'id': id,
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
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : Timestamp.now(),
    };
  }

  /// Create a profile from a Firestore document map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
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
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create a default profile from Firebase Auth user data
  factory UserProfile.fromFirebaseUser(String uid, String email,
      {String? displayName}) {
    return UserProfile(
      id: uid,
      displayName: displayName ?? email.split('@').first,
      email: email,
      lastUpdated: DateTime.now(),
    );
  }
}
