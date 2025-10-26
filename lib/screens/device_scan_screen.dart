import 'package:flutter/material.dart';
import '../services/wifi_service.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  _DeviceScanScreenState createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final WiFiDeviceManager _wifiService = WiFiDeviceManager();
  
  bool _isScanning = false;
  bool _isConnected = false;
  String _status = "Ready to connect";
  
  // Available devices
  List<Map<String, dynamic>> _availableDevices = [];
  
  @override
  void initState() {
    super.initState();
    _setupWiFiListeners();
  }

  void _setupWiFiListeners() {
    _wifiService.statusStream.listen((status) {
      setState(() {
        _status = status;
        _isConnected = _wifiService.isConnected;
      });
    });

    _wifiService.devicesStream.listen((devices) {
      setState(() {
        _availableDevices = devices;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Connection'),
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
            _buildActionButtons(),
            SizedBox(height: 20),
            _buildInstructionsCard(),
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
                  _isConnected ? Icons.wifi : Icons.wifi_off,
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
                  Text('ESP8266 + MAX30102 Connected via WiFi'),
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
              Text('No devices found. Tap "Scan" to search for ESP8266 devices on your WiFi network.')
            else
              ..._availableDevices.map((device) => _buildDeviceItem(device)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    return ListTile(
      leading: Icon(Icons.device_hub, color: Colors.blue),
      title: Text(device['name'] ?? 'ESP8266 Device'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IP: ${device['ip']}:${device['port']}'),
          Text('Status: ${device['status']}'),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: _isConnected ? null : () => _connectToDevice(device),
        child: Text(_isConnected ? 'Connected' : 'Connect'),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Connection Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInstructionStep(1, 'Make sure your ESP8266 device is powered on and connected to WiFi'),
            SizedBox(height: 8),
            _buildInstructionStep(2, 'Tap "Scan" to search for available ESP8266 devices'),
            SizedBox(height: 8),
            _buildInstructionStep(3, 'Select your device from the list and tap "Connect"'),
            SizedBox(height: 8),
            _buildInstructionStep(4, 'Once connected, go to "Measurement" tab to start scanning'),
          ],
        ),
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
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            instruction,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isConnected ? _disconnect : null,
            icon: Icon(Icons.wifi_off),
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
            onPressed: _isConnected ? _goToMeasurement : null,
            icon: Icon(Icons.monitor_heart),
            label: Text('Start Measurement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
      List<Map<String, dynamic>> devices = await _wifiService.scanForDevices();
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

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    String ip = device['ip'];
    int port = device['port'] ?? 8080;
    bool connected = await _wifiService.connectToDevice(ip, port: port);
    setState(() {
      _isConnected = connected;
    });
  }


  Future<void> _disconnect() async {
    await _wifiService.disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  void _goToMeasurement() {
    // Navigate to measurement screen
    Navigator.pushNamed(context, '/measurement');
  }


  @override
  void dispose() {
    // Don't dispose WiFi service here - it's a singleton that should persist
    super.dispose();
  }
}
