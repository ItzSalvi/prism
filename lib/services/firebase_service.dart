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
      QuerySnapshot snapshot = await _firestore
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent measurements: $e');
    }
  }

  // Get abnormal measurements for SMS alerts
  Future<List<Map<String, dynamic>>> getAbnormalMeasurements(String userId, {int days = 7}) async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      QuerySnapshot snapshot = await _firestore
          .collection('measurements')
          .where('userId', isEqualTo: userId)
          .where('isAbnormal', isEqualTo: true)
          .where('timestamp', isGreaterThan: cutoffDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
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
}






