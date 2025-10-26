import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/wifi_service.dart';
import '../services/sms_service.dart';
import '../providers/auth_provider.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  _MeasurementScreenState createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> with SingleTickerProviderStateMixin {
  final WiFiDeviceManager _wifiService = WiFiDeviceManager();
  final FirebaseService _firebaseService = FirebaseService();
  final SMSService _smsService = SMSService();
  
  bool _isScanning = false;
  bool _hasData = false;
  bool _isSaving = false;
  bool _hasSavedMeasurement = false;
  int _scanProgress = 0;
  
  // Real sensor data from ESP8266
  int _systolic = 0;
  int _diastolic = 0;
  int _heartRate = 0;
  double _spo2 = 0.0;
  String _status = "Connect to ESP8266 device first";
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _setupWiFiListeners();
  }

  void _setupWiFiListeners() {
    _wifiService.statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });

    _wifiService.dataStream.listen((data) {
      setState(() {
        _systolic = data['systolic'] ?? 0;
        _diastolic = data['diastolic'] ?? 0;
        _heartRate = data['heartRate'] ?? 0;
        _spo2 = data['spo2'] ?? 0.0;
        
        // Check if we have valid data
        if (_systolic > 0 && _diastolic > 0) {
          _hasData = true;
        }
      });
    });

    _wifiService.scanProgressStream.listen((progress) {
      setState(() {
        _scanProgress = progress;
      });
      
      // When scan is complete (30 seconds), save the measurement
      if (progress >= 30 && _hasData && !_isSaving && !_hasSavedMeasurement) {
        _isScanning = false;
        _animationController.stop();
        _saveMeasurement();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Don't dispose WiFi service here - it's a singleton that should persist
    super.dispose();
  }

  void _startScanning() async {
    // First check if we're connected to a device
    if (!_wifiService.isConnected) {
      setState(() {
        _status = "Please connect to ESP8266 device first";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please go to Device Scan screen and connect to your ESP8266 device first')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Starting measurement... Place finger on sensor";
      _hasData = false;
      _hasSavedMeasurement = false;
      _systolic = 0;
      _diastolic = 0;
      _heartRate = 0;
      _spo2 = 0.0;
    });
    
    _animationController.repeat(reverse: true);
    
    try {
      await _wifiService.startSensorScan();
    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = "Failed to start scan: $e";
      });
      _animationController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start scan: $e')),
      );
    }
  }

  void _stopScanning() async {
    setState(() {
      _isScanning = false;
      _status = "Stopping scan...";
    });
    _animationController.stop();
    
    try {
      await _wifiService.stopSensorScan();
      setState(() {
        _status = "Scan stopped";
      });
    } catch (e) {
      setState(() {
        _status = "Error stopping scan: $e";
      });
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = false;
      _hasData = false;
      _isSaving = false;
      _hasSavedMeasurement = false;
      _status = _wifiService.isConnected ? "Ready to scan" : "Connect to ESP8266 device first";
      _systolic = 0;
      _diastolic = 0;
      _heartRate = 0;
      _spo2 = 0.0;
    });
    _animationController.stop();
  }

  Future<void> _saveMeasurement() async {
    if (_systolic == 0 || _diastolic == 0) return;

    setState(() {
      _isSaving = true;
      _status = "Saving measurement...";
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Determine if blood pressure is abnormal
      bool isAbnormal = _wifiService.isAbnormalBloodPressure(_systolic, _diastolic);

      // Save to Firebase
      await _firebaseService.storeBloodPressureMeasurement(
        userId: userId,
        systolic: _systolic,
        diastolic: _diastolic,
        heartRate: _heartRate,
        spo2: _spo2,
        timestamp: DateTime.now(),
        isAbnormal: isAbnormal,
      );

      // Check if abnormal and send SMS
      if (isAbnormal) {
        await _sendAbnormalAlert();
      }

      setState(() {
        _isSaving = false;
        _hasSavedMeasurement = true;
        _status = "Measurement saved successfully!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Measurement saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _isSaving = false;
        _status = "Failed to save measurement";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save measurement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendAbnormalAlert() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId == null) return;

      // Get user profile
      Map<String, dynamic>? userProfile = await _firebaseService.getUserProfile(userId);
      if (userProfile == null) return;

      String emergencyPhone = userProfile['emergencyPhone'] ?? '';
      String userName = userProfile['name'] ?? 'User';

      if (emergencyPhone.isNotEmpty) {
        bool smsSent = await _smsService.sendBloodPressureAlert(
          emergencyPhone: emergencyPhone,
          userName: userName,
          systolic: _systolic,
          diastolic: _diastolic,
          heartRate: _heartRate,
          timestamp: DateTime.now(),
        );

        if (smsSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SMS alert sent to emergency contact!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send SMS alert')),
          );
        }
      }
    } catch (e) {
      print('Failed to send abnormal alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Blood Pressure Measurement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Scanner Status Card
            _buildStatusCard(),
            SizedBox(height: 24),
            
            // Measurement Display
            if (_hasData) _buildMeasurementDisplay(),
            
            // Scanner Controls
            _buildScannerControls(),
            SizedBox(height: 16),
            
            // Connection Status Button
            if (!_wifiService.isConnected) _buildConnectionButton(),
            SizedBox(height: 24),
            
            // Instructions
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAX30102 Sensor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _wifiService.isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _wifiService.isConnected ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _wifiService.isConnected ? 'ESP8266 Connected' : 'ESP8266 Not Connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: _wifiService.isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFF3F4F6)),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isScanning ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _isScanning ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                        color: _isScanning ? Color(0xFFDC2626) : Color(0xFF9CA3AF),
                        size: 40,
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isScanning ? Color(0xFFDC2626) : Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isScanning) ...[
                  SizedBox(height: 12),
                  if (_scanProgress > 0) ...[
                    LinearProgressIndicator(
                      value: _scanProgress / 30.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Progress: $_scanProgress/30 seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Waiting for finger detection...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementDisplay() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded, // FIXED: Replaced with available icon
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Measurement Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementItem('Systolic', '$_systolic', 'mmHg', Color(0xFFEF4444)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementItem('Diastolic', '$_diastolic', 'mmHg', Color(0xFFF59E0B)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementItem('Heart Rate', '$_heartRate', 'bpm', Color(0xFFDC2626)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementItem('SpO2', '${_spo2.toStringAsFixed(1)}', '%', Color(0xFF10B981)),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildBloodPressureStatus(),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureStatus() {
    bool isNormal = _systolic <= 120 && _diastolic <= 80;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNormal ? Color(0xFFF0FDF4) : Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNormal ? Color(0xFFBBF7D0) : Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isNormal ? Color(0xFF10B981) : Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNormal ? Icons.check_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              isNormal ? 'Blood pressure is normal' : 'Elevated blood pressure detected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isNormal ? Color(0xFF059669) : Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerControls() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!_hasData && !_isSaving) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _wifiService.isConnected
                      ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                      : [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _wifiService.isConnected
                    ? [
                        BoxShadow(
                          color: Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _wifiService.isConnected
                      ? (_isScanning ? _stopScanning : _startScanning)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please connect to ESP8266 device first')),
                          );
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _wifiService.isConnected
                              ? (_isScanning ? 'Stop Scanning' : 'Start Scanning')
                              : 'Connect ESP8266 First',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else if (_isSaving) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Saving measurement...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'New Scan',
                    Icons.refresh_rounded,
                    Color(0xFF3B82F6),
                    _resetScan,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Results',
                    Icons.visibility_rounded,
                    Color(0xFF10B981),
                    () {
                      // Navigate to history or show detailed results
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Measurement saved to database!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to device screen
            Navigator.pushNamed(context, '/device');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_find_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Go to Device Tab to Connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Measurement Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInstructionStep(1, 'Sit comfortably and relax for 5 minutes'),
          SizedBox(height: 12),
          _buildInstructionStep(2, 'Place your index finger on the MAX30102 sensor'),
          SizedBox(height: 12),
          _buildInstructionStep(3, 'Keep your hand steady during measurement'),
          SizedBox(height: 12),
          _buildInstructionStep(4, 'Wait for the scan to complete automatically'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFFDC2626),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            instruction,
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}