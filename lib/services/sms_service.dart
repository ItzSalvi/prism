import 'dart:convert';
import 'package:http/http.dart' as http;

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  // You can use different SMS providers
  // This example uses Twilio, but you can also use:
  // - AWS SNS
  // - Firebase Cloud Messaging
  // - Your own SMS gateway
  // - SIM800L direct integration (requires additional setup)

  // Twilio configuration (replace with your credentials)
  static const String _twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  static const String _twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  static const String _twilioPhoneNumber = 'YOUR_TWILIO_PHONE_NUMBER';
  static const String _twilioApiUrl = 'https://api.twilio.com/2010-04-01/Accounts/$_twilioAccountSid/Messages.json';

  // Send SMS alert for abnormal blood pressure
  Future<bool> sendBloodPressureAlert({
    required String emergencyPhone,
    required String userName,
    required int systolic,
    required int diastolic,
    required int heartRate,
    required DateTime timestamp,
  }) async {
    try {
      String message = _buildAlertMessage(
        userName: userName,
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        timestamp: timestamp,
      );

      return await _sendSMS(
        to: emergencyPhone,
        message: message,
      );
    } catch (e) {
      print('Failed to send SMS alert: $e');
      return false;
    }
  }

  // Build alert message
  String _buildAlertMessage({
    required String userName,
    required int systolic,
    required int diastolic,
    required int heartRate,
    required DateTime timestamp,
  }) {
    String status = _getBloodPressureStatus(systolic, diastolic);
    String timeStr = _formatTimestamp(timestamp);
    
    return '''
🚨 HEALTH ALERT - PRISM App

$userName has recorded abnormal blood pressure:

📊 Blood Pressure: $systolic/$diastolic mmHg
💓 Heart Rate: $heartRate bpm
📅 Time: $timeStr
⚠️ Status: $status

Please check on $userName immediately.

This is an automated alert from the PRISM health monitoring system.
    '''.trim();
  }

  // Get blood pressure status
  String _getBloodPressureStatus(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return "CRISIS - Seek immediate medical attention";
    } else if (systolic >= 140 || diastolic >= 90) {
      return "HIGH - Consult doctor immediately";
    } else if (systolic >= 130 || diastolic >= 80) {
      return "ELEVATED - Monitor closely";
    } else {
      return "NORMAL";
    }
  }

  // Format timestamp
  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  // Send SMS using Twilio
  Future<bool> _sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = to.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+1$cleanPhone'; // Default to US if no country code
      }

      final response = await http.post(
        Uri.parse(_twilioApiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': cleanPhone,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        print('SMS sent successfully to $cleanPhone');
        return true;
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('SMS sending error: $e');
      return false;
    }
  }

  // Alternative: Send SMS using AWS SNS
  Future<bool> sendSMSViaAWS({
    required String phoneNumber,
    required String message,
  }) async {
    // This would require AWS SDK setup
    // Implementation depends on your AWS configuration
    print('AWS SNS SMS implementation would go here');
    return false;
  }

  // Alternative: Send SMS using Firebase Cloud Messaging
  Future<bool> sendSMSViaFCM({
    required String phoneNumber,
    required String message,
  }) async {
    // This would require FCM setup for SMS
    // Implementation depends on your FCM configuration
    print('FCM SMS implementation would go here');
    return false;
  }

  // Test SMS functionality
  Future<bool> testSMS(String phoneNumber) async {
    try {
      String testMessage = '''
🧪 PRISM App Test Message

This is a test message from the PRISM health monitoring system.

If you receive this message, the SMS alert system is working correctly.

Time: ${DateTime.now().toString()}
      '''.trim();

      return await _sendSMS(
        to: phoneNumber,
        message: testMessage,
      );
    } catch (e) {
      print('Test SMS failed: $e');
      return false;
    }
  }
}









