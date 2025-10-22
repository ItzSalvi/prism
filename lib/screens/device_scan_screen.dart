import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/firebase_service.dart';
import '../services/sms_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeleton_loader.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  _DeviceScanScreenState createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final BluetoothManager _bluetoothService = BluetoothManager();
  final FirebaseService _firebaseService = FirebaseService();
  final SMSService _smsService = SMSService();
  
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isDeviceScanning = false;
  int _scanProgress = 0;
  String _status = "Ready to connect";
  
  // Sensor data
  int _systolic = 0;
  int _diastolic = 0;
  int _heartRate = 0;
  double _spo2 = 0.0;
  
  // Available devices
  List<dynamic> _availableDevices = [];
  
  @override
  void initState() {
    super.initState();
    _setupBluetoothListeners();
  }

  void _setupBluetoothListeners() {
    _bluetoothService.statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });

    _bluetoothService.dataStream.listen((data) {
      setState(() {
        _systolic = data['systolic'] ?? 0;
        _diastolic = data['diastolic'] ?? 0;
        _heartRate = data['heartRate'] ?? 0;
        _spo2 = data['spo2'] ?? 0.0;
      });
    });

    _bluetoothService.scanProgressStream.listen((progress) {
      setState(() {
        _scanProgress = progress;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP8266 Device Scanner'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            SizedBox(height: 20),
            _buildDeviceList(),
            SizedBox(height: 20),
            _buildScanningSection(),
            SizedBox(height: 20),
            _buildMeasurementDisplay(),
            SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'Device Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(_status, style: TextStyle(fontSize: 14)),
            if (_isConnected) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.device_hub, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('ESP8266 + MAX30102 Connected'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanForDevices,
                  icon: Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_availableDevices.isEmpty)
              Text('No devices found. Tap "Scan" to search for ESP8266 devices.')
            else
              ..._availableDevices.map((device) => _buildDeviceItem(device)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(dynamic device) {
    return ListTile(
      leading: Icon(Icons.device_hub, color: Colors.blue),
      title: Text(device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'),
      subtitle: Text(device.remoteId.toString()),
      trailing: ElevatedButton(
        onPressed: _isConnected ? null : () => _connectToDevice(device),
        child: Text(_isConnected ? 'Connected' : 'Connect'),
      ),
    );
  }

  Widget _buildScanningSection() {
    if (!_isConnected) return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Scanning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (_isDeviceScanning) ...[
              _buildScanProgress(),
              SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDeviceScanning ? null : _startScan,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isDeviceScanning ? _stopScan : null,
                  icon: Icon(Icons.stop),
                  label: Text('Stop Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanProgress() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _scanProgress / 60.0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          'Scanning: $_scanProgress/60 seconds',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'Place your finger on the MAX30102 sensor',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMeasurementDisplay() {
    if (!_isDeviceScanning && _systolic == 0) return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Measurements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMeasurementItem('Systolic', '$_systolic', 'mmHg', Colors.red),
                _buildMeasurementItem('Diastolic', '$_diastolic', 'mmHg', Colors.orange),
                _buildMeasurementItem('Heart Rate', '$_heartRate', 'bpm', Colors.blue),
                _buildMeasurementItem('SpO2', _spo2.toStringAsFixed(1), '%', Colors.green),
              ],
            ),
            if (_systolic > 0 && _diastolic > 0) ...[
              SizedBox(height: 16),
              _buildBloodPressureStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBloodPressureStatus() {
    bool isAbnormal = _bluetoothService.isAbnormalBloodPressure(_systolic, _diastolic);
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAbnormal ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAbnormal ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAbnormal ? Icons.warning : Icons.check_circle,
            color: isAbnormal ? Colors.red : Colors.green,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isAbnormal 
                ? '⚠️ Abnormal blood pressure detected!'
                : '✅ Blood pressure is normal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAbnormal ? Colors.red[800] : Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isConnected ? _disconnect : null,
            icon: Icon(Icons.bluetooth_disabled),
            label: Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _systolic > 0 ? _saveMeasurement : null,
            icon: Icon(Icons.save),
            label: Text('Save Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Methods
  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _status = "Scanning for devices...";
    });

    try {
      List<dynamic> devices = await _bluetoothService.scanForDevices();
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = "Scan failed: $e";
      });
    }
  }

  Future<void> _connectToDevice(dynamic device) async {
    bool connected = await _bluetoothService.connectToDevice(device);
    setState(() {
      _isConnected = connected;
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isDeviceScanning = true;
      _scanProgress = 0;
    });

    try {
      await _bluetoothService.startSensorScan();
    } catch (e) {
      setState(() {
        _isDeviceScanning = false;
        _status = "Failed to start scan: $e";
      });
    }
  }

  Future<void> _stopScan() async {
    await _bluetoothService.stopSensorScan();
    setState(() {
      _isDeviceScanning = false;
    });
  }

  Future<void> _disconnect() async {
    await _bluetoothService.disconnect();
    setState(() {
      _isConnected = false;
      _isDeviceScanning = false;
      _systolic = 0;
      _diastolic = 0;
      _heartRate = 0;
      _spo2 = 0.0;
    });
  }

  Future<void> _saveMeasurement() async {
    if (_systolic == 0 || _diastolic == 0) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Save to Firebase
      String measurementId = await _firebaseService.storeBloodPressureMeasurement(
        userId: userId,
        systolic: _systolic,
        diastolic: _diastolic,
        heartRate: _heartRate,
        spo2: _spo2,
        timestamp: DateTime.now(),
        isAbnormal: _bluetoothService.isAbnormalBloodPressure(_systolic, _diastolic),
      );

      // Check if abnormal and send SMS
      if (_bluetoothService.isAbnormalBloodPressure(_systolic, _diastolic)) {
        await _sendAbnormalAlert();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Measurement saved successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save measurement: $e')),
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
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}
