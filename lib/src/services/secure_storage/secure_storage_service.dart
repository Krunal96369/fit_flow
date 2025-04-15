import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider for the SecureStorageService
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageServiceImpl();
});

/// Service that handles secure storage of sensitive information
abstract class SecureStorageService {
  /// Store sensitive data securely
  Future<bool> setSecureData(String key, String value);

  /// Retrieve sensitive data
  Future<String?> getSecureData(String key);

  /// Delete sensitive data
  Future<bool> deleteSecureData(String key);

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key);
}

/// Implementation of SecureStorageService that uses Hive encrypted boxes
class SecureStorageServiceImpl implements SecureStorageService {
  // Name for the encrypted box
  static const String _secureBoxName = 'secure_credentials_box';

  // Encryption key for the Hive box
  late final Uint8List _encryptionKey;

  // Flag to track if initialization is complete
  bool _isInitialized = false;

  // Reference to the box once opened
  Box<String>? _secureBox;

  /// Private constructor that enforces the singleton pattern
  SecureStorageServiceImpl._();

  /// Factory constructor that creates or returns the singleton instance
  static final SecureStorageServiceImpl _instance =
      SecureStorageServiceImpl._();

  factory SecureStorageServiceImpl() => _instance;

  /// Initialize the secure storage by opening the encrypted box
  Future<void> _initializeIfNeeded() async {
    if (_isInitialized && _secureBox != null && _secureBox!.isOpen) {
      return;
    }

    try {
      debugPrint('SecureStorage: Initializing secure storage...');
      // Generate encryption key from a fixed password
      // In a production app, you would store this key more securely or derive it from device-specific data
      _encryptionKey = _generateEncryptionKey('fitflow_secure_storage_key');

      // No need to register adapters for primitive types like String
      // Hive handles these natively

      // Open the encrypted box with the encryption key
      _secureBox = await Hive.openBox<String>(
        _secureBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey),
      );

      _isInitialized = true;
      debugPrint(
          'SecureStorage: Initialization successful. Box is open: ${_secureBox?.isOpen}');

      // Log the keys in the box to debug
      final keys = _secureBox?.keys.toList() ?? [];
      debugPrint('SecureStorage: Box contains ${keys.length} keys: $keys');
    } catch (e) {
      debugPrint('SecureStorage: Error initializing secure storage: $e');
      // If initialization fails, we'll try again next time a method is called
    }
  }

  /// Generate a 256-bit encryption key from a password
  Uint8List _generateEncryptionKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  @override
  Future<bool> setSecureData(String key, String value) async {
    try {
      await _initializeIfNeeded();

      if (_secureBox == null || !_secureBox!.isOpen) {
        debugPrint('SecureStorage: Box is not open for setting data');
        return false;
      }

      debugPrint('SecureStorage: Setting data for key: $key');
      await _secureBox!.put(key, value);

      // Force a flush to ensure data is persisted immediately
      await _secureBox!.flush();

      // Verify the data was saved correctly
      final savedValue = _secureBox!.get(key);
      final success = savedValue == value;

      debugPrint('SecureStorage: Data saved successfully: $success');
      return success;
    } catch (e) {
      debugPrint('SecureStorage: Error storing secure data: $e');
      return false;
    }
  }

  @override
  Future<String?> getSecureData(String key) async {
    try {
      await _initializeIfNeeded();

      if (_secureBox == null || !_secureBox!.isOpen) {
        debugPrint('SecureStorage: Box is not open for getting data');
        return null;
      }

      debugPrint('SecureStorage: Getting data for key: $key');
      final value = _secureBox!.get(key);
      debugPrint('SecureStorage: Retrieved value exists: ${value != null}');
      return value;
    } catch (e) {
      debugPrint('SecureStorage: Error retrieving secure data: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteSecureData(String key) async {
    try {
      await _initializeIfNeeded();

      if (_secureBox == null || !_secureBox!.isOpen) {
        debugPrint('SecureStorage: Box is not open for deleting data');
        return false;
      }

      debugPrint('SecureStorage: Deleting data for key: $key');
      await _secureBox!.delete(key);

      // Force a flush to ensure changes are persisted immediately
      await _secureBox!.flush();

      debugPrint('SecureStorage: Data deleted successfully');
      return true;
    } catch (e) {
      debugPrint('SecureStorage: Error deleting secure data: $e');
      return false;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      await _initializeIfNeeded();

      if (_secureBox == null || !_secureBox!.isOpen) {
        debugPrint('SecureStorage: Box is not open for checking key');
        return false;
      }

      debugPrint('SecureStorage: Checking if box contains key: $key');
      final contains = _secureBox!.containsKey(key);
      debugPrint('SecureStorage: Box contains key: $contains');
      return contains;
    } catch (e) {
      debugPrint('SecureStorage: Error checking for secure key: $e');
      return false;
    }
  }

  /// Clear all secure data (useful for testing or logout)
  Future<bool> clearAll() async {
    try {
      await _initializeIfNeeded();

      if (_secureBox == null || !_secureBox!.isOpen) {
        debugPrint('SecureStorage: Box is not open for clearing data');
        return false;
      }

      debugPrint('SecureStorage: Clearing all data');
      await _secureBox!.clear();

      // Force a flush to ensure changes are persisted immediately
      await _secureBox!.flush();

      debugPrint('SecureStorage: All data cleared successfully');
      return true;
    } catch (e) {
      debugPrint('SecureStorage: Error clearing secure data: $e');
      return false;
    }
  }

  /// Force all pending box changes to be written to disk
  Future<void> flushChanges() async {
    try {
      if (_secureBox != null && _secureBox!.isOpen) {
        await _secureBox!.flush();
        debugPrint('SecureStorage: Changes flushed to disk');
      }
    } catch (e) {
      debugPrint('SecureStorage: Error flushing changes: $e');
    }
  }
}
