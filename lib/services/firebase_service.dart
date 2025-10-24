import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store user profile data
  Future<void> storeUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phoneNumber,
    required String emergencyContact,
    required String emergencyPhone,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'emergencyContact': emergencyContact,
        'emergencyPhone': emergencyPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to store user profile: $e');
    }
  }

  // Store extended user profile data
  Future<void> storeExtendedUserProfile({
    required String userId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime birthDate,
    required int age,
    required String emergencyContact,
    required String emergencyPhone,
    String? physician,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'fullName': '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName',
        'email': email,
        'phoneNumber': phoneNumber,
        'birthDate': birthDate,
        'age': age,
        'emergencyContact': emergencyContact,
        'emergencyPhone': emergencyPhone,
        'physician': physician,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to store extended user profile: $e');
    }
  }

  // Store blood pressure measurement
  Future<String> storeBloodPressureMeasurement({
    required String userId,
    required int systolic,
    required int diastolic,
    required int heartRate,
    required double spo2,
    required DateTime timestamp,
    required bool isAbnormal,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('measurements').add({
        'userId': userId,
        'systolic': systolic,
        'diastolic': diastolic,
        'heartRate': heartRate,
        'spo2': spo2,
        'timestamp': timestamp,
        'isAbnormal': isAbnormal,
        'deviceType': 'ESP8266_MAX30102',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to store measurement: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get recent measurements
  Future<List<Map<String, dynamic>>> getRecentMeasurements(String userId, {int limit = 10}) async {
    try {
      // First get all measurements for the user, then sort in memory to avoid index requirement
      QuerySnapshot snapshot = await _firestore
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> measurements = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by timestamp in descending order (newest first)
      measurements.sort((a, b) {
        DateTime timestampA = a['timestamp'] is DateTime 
            ? a['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(a['timestamp'].millisecondsSinceEpoch);
        DateTime timestampB = b['timestamp'] is DateTime 
            ? b['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(b['timestamp'].millisecondsSinceEpoch);
        return timestampB.compareTo(timestampA);
      });

      // Apply limit
      if (measurements.length > limit) {
        measurements = measurements.take(limit).toList();
      }

      return measurements;
    } catch (e) {
      throw Exception('Failed to get recent measurements: $e');
    }
  }

  // Get abnormal measurements for SMS alerts
  Future<List<Map<String, dynamic>>> getAbnormalMeasurements(String userId, {int days = 7}) async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      // Get all measurements for the user, then filter and sort in memory
      QuerySnapshot snapshot = await _firestore
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> allMeasurements = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter for abnormal measurements within the date range
      List<Map<String, dynamic>> abnormalMeasurements = allMeasurements.where((measurement) {
        bool isAbnormal = measurement['isAbnormal'] == true;
        DateTime timestamp = measurement['timestamp'] is DateTime 
            ? measurement['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(measurement['timestamp'].millisecondsSinceEpoch);
        bool withinDateRange = timestamp.isAfter(cutoffDate);
        return isAbnormal && withinDateRange;
      }).toList();

      // Sort by timestamp in descending order (newest first)
      abnormalMeasurements.sort((a, b) {
        DateTime timestampA = a['timestamp'] is DateTime 
            ? a['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(a['timestamp'].millisecondsSinceEpoch);
        DateTime timestampB = b['timestamp'] is DateTime 
            ? b['timestamp'] 
            : DateTime.fromMillisecondsSinceEpoch(b['timestamp'].millisecondsSinceEpoch);
        return timestampB.compareTo(timestampA);
      });

      return abnormalMeasurements;
    } catch (e) {
      throw Exception('Failed to get abnormal measurements: $e');
    }
  }

  // Update user's emergency contact info
  Future<void> updateEmergencyContact({
    required String userId,
    required String emergencyContact,
    required String emergencyPhone,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emergencyContact': emergencyContact,
        'emergencyPhone': emergencyPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phoneNumber,
    DateTime? birthDate,
    int? age,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (middleName != null) updateData['middleName'] = middleName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (birthDate != null) updateData['birthDate'] = birthDate;
      if (age != null) updateData['age'] = age;

      // Update full name if first or last name changed
      if (firstName != null || lastName != null) {
        String fullName = '';
        if (firstName != null) fullName += firstName;
        if (middleName != null && middleName.isNotEmpty) fullName += ' $middleName';
        if (lastName != null) fullName += ' $lastName';
        updateData['fullName'] = fullName.trim();
      }

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }


  // Update physician
  Future<void> updatePhysician({
    required String userId,
    String? physician,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'physician': physician,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update physician: $e');
    }
  }

  // Delete user account and all associated data
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete user measurements
      QuerySnapshot measurements = await _firestore
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (DocumentSnapshot doc in measurements.docs) {
        await doc.reference.delete();
      }

      // Delete user profile
      await _firestore.collection('users').doc(userId).delete();

      // Delete the Firebase Auth user
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }
}







